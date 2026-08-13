use std::fs::{File, OpenOptions};
use std::io::{BufRead, BufReader, Read, Seek, SeekFrom, Write};
use std::path::PathBuf;
use std::process::{Child, Command, Stdio};
use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::mpsc::{channel, Receiver, Sender};
use std::sync::{Arc, Mutex};
use std::thread;
use std::time::{Duration, Instant, SystemTime, UNIX_EPOCH};

use crate::dns::DnsOverride;
use crate::net;
use crate::probe;
use crate::settings::TunnelSettings;
use crate::sysproxy::SystemProxy;
use crate::tunnel::TunnelDevice;

const POST_SCAN_HEADROOM: Duration = Duration::from_secs(60);

fn validation_budget(scan_mode: &str) -> Duration {
    let scan_budget = match scan_mode.trim().to_lowercase().as_str() {
        "turbo" | "fast" => Duration::from_secs(45),
        "thorough" | "deep" | "pro" => Duration::from_secs(300),
        "stealth" | "quiet" => Duration::from_secs(180),
        "ironclad" | "real" | "verify" | "guaranteed" => Duration::from_secs(180),
        _ => Duration::from_secs(120),
    };
    scan_budget + POST_SCAN_HEADROOM
}
const VALIDATION_INTERVAL: Duration = Duration::from_secs(1);
const RETAINED_LOG_LINES: usize = 2500;
const MAX_TAILED_LOG_BYTES: u64 = 2 * 1024 * 1024;

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Stage {
    Disconnected,
    Connecting,
    Validating,
    Connected,
    Disconnecting,
    Failed,
}

impl Stage {
    pub fn wire(self) -> &'static str {
        match self {
            Stage::Disconnected => "disconnected",
            Stage::Connecting => "connecting",
            Stage::Validating => "validating",
            Stage::Connected => "connected",
            Stage::Disconnecting => "disconnecting",
            Stage::Failed => "failed",
        }
    }
}

#[derive(Debug, Clone)]
pub struct Snapshot {
    pub stage: Stage,
    pub gateway: Option<String>,
    pub connected_at_millis: u64,
    pub message: Option<String>,
    pub tunnel_mode: bool,
}

impl Snapshot {
    pub fn disconnected() -> Self {
        Self {
            stage: Stage::Disconnected,
            gateway: None,
            connected_at_millis: 0,
            message: None,
            tunnel_mode: false,
        }
    }
}

fn hev_log_path(settings: &TunnelSettings) -> PathBuf {
    let directory = settings.log_directory();
    let _ = std::fs::create_dir_all(&directory);
    directory.join("oblivion-hevtun.log")
}

fn gateway_from_log(line: &str) -> Option<String> {
    const MARKERS: [&str; 5] = [
        "using forced peer ",
        "selected gateway ",
        "using cloudflare edge ",
        "cached gateway ",
        "known-good gateway ",
    ];

    for marker in MARKERS {
        if let Some(index) = line.find(marker) {
            let rest = &line[index + marker.len()..];
            let candidate = rest
                .split_whitespace()
                .next()?
                .trim_end_matches([',', ';', '.']);
            if candidate.contains(':') && candidate.chars().any(|c| c.is_ascii_digit()) {
                return Some(candidate.to_string());
            }
        }
    }
    None
}

fn escape(value: &str) -> String {
    value.replace('\\', "\\\\").replace('"', "\\\"")
}

pub struct Supervisor {
    core: Mutex<Option<Child>>,
    core_input: Mutex<Option<std::process::ChildStdin>>,
    snapshot: Mutex<Snapshot>,
    logs: Mutex<Vec<String>>,
    log_tx: Sender<String>,
    log_rx: Mutex<Receiver<String>>,
    shutting_down: Arc<AtomicBool>,
    core_binary: Mutex<Option<PathBuf>>,
    device: TunnelDevice,
    active: Mutex<Option<TunnelSettings>>,
    resolver: Mutex<DnsOverride>,
    proxy: Mutex<SystemProxy>,
    observed_gateway: Mutex<Option<String>>,
}

impl Supervisor {
    pub fn new() -> Self {
        let (log_tx, log_rx) = channel();
        Self {
            core: Mutex::new(None),
            core_input: Mutex::new(None),
            snapshot: Mutex::new(Snapshot::disconnected()),
            logs: Mutex::new(Vec::new()),
            log_tx,
            log_rx: Mutex::new(log_rx),
            shutting_down: Arc::new(AtomicBool::new(false)),
            core_binary: Mutex::new(None),
            device: TunnelDevice::new(),
            active: Mutex::new(None),
            resolver: Mutex::new(DnsOverride::new()),
            proxy: Mutex::new(SystemProxy::new()),
            observed_gateway: Mutex::new(None),
        }
    }

    pub fn submit_line(&self, line: &str) -> bool {
        use std::io::Write;

        let trimmed = line.trim();
        if trimmed.is_empty() {
            return false;
        }

        let mut guard = self.core_input.lock().unwrap();
        let Some(input) = guard.as_mut() else {
            return false;
        };

        match writeln!(input, "{trimmed}").and_then(|()| input.flush()) {
            Ok(()) => true,
            Err(error) => {
                self.log_from("aether", format!("[-] could not reach the core: {error}"));
                false
            }
        }
    }

    pub fn recover_previous_session(&self) {
        if !net::is_privileged() {
            return;
        }
        if crate::dns::recover_stale_override() {
            self.log_from("aether", "[!] restored a resolver left behind by an earlier run");
        }
        if net::tunnel_default_installed() {
            net::revert_tunnel_routes(true);
            self.log_from("aether", "[!] cleared routes left behind by an earlier run");
        }
    }

    pub fn set_core_binary(&self, path: PathBuf) {
        *self.core_binary.lock().unwrap() = Some(path);
    }

    pub fn snapshot_json(&self) -> String {
        let snapshot = self.snapshot.lock().unwrap().clone();
        let counters = self.device.counters();

        let gateway = snapshot
            .gateway
            .as_ref()
            .map(|value| format!("\"{}\"", escape(value)))
            .unwrap_or_else(|| "null".to_string());
        let message = snapshot
            .message
            .as_ref()
            .map(|value| format!("\"{}\"", escape(value)))
            .unwrap_or_else(|| "null".to_string());

        format!(
            "{{\"stage\":\"{stage}\",\"stats\":{{\"txPackets\":{tx_packets},\
             \"txBytes\":{tx_bytes},\"rxPackets\":{rx_packets},\
             \"rxBytes\":{rx_bytes}}},\"gateway\":{gateway},\
             \"connectedAt\":{connected_at},\"message\":{message},\
             \"tunnelMode\":{tunnel_mode},\"tunnelDeviceUp\":{device_up}}}",
            stage = snapshot.stage.wire(),
            tx_packets = counters.tx_packets,
            tx_bytes = counters.tx_bytes,
            rx_packets = counters.rx_packets,
            rx_bytes = counters.rx_bytes,
            gateway = gateway,
            connected_at = snapshot.connected_at_millis,
            message = message,
            tunnel_mode = snapshot.tunnel_mode,
            device_up = self.device.is_running(),
        )
    }

    pub fn tunnel_device_available(&self) -> bool {
        TunnelDevice::available()
    }

    pub fn drain_logs(&self) -> String {
        let receiver = self.log_rx.lock().unwrap();
        let mut chunk = String::new();
        while let Ok(line) = receiver.try_recv() {
            chunk.push_str(&line);
            chunk.push('\n');
        }
        chunk
    }

    pub fn read_logs(&self) -> String {
        self.logs.lock().unwrap().join("\n")
    }

    pub fn clear_logs(&self) {
        self.logs.lock().unwrap().clear();
    }

    fn log_from(&self, source: &str, line: impl Into<String>) {
        let line = line.into();
        let trimmed = line.trim_end();
        if trimmed.is_empty() {
            return;
        }
        if let Some(peer) = gateway_from_log(trimmed) {
            let mut observed = self.observed_gateway.lock().unwrap();
            if observed.as_deref() != Some(peer.as_str()) {
                *observed = Some(peer.clone());
                drop(observed);
                let mut snapshot = self.snapshot.lock().unwrap();
                snapshot.gateway = Some(peer);
            }
        }
        self.log(format!("[{source}] {trimmed}"));
    }

    fn log(&self, line: impl Into<String>) {
        let line = line.into();
        let mut buffer = self.logs.lock().unwrap();
        buffer.push(line.clone());
        if buffer.len() > RETAINED_LOG_LINES {
            let overflow = buffer.len() - RETAINED_LOG_LINES;
            buffer.drain(0..overflow);
        }
        drop(buffer);
        let _ = self.log_tx.send(line);
    }

    fn publish(&self, stage: Stage, message: Option<String>, gateway: Option<String>) {
        let connected_at = if stage == Stage::Connected {
            SystemTime::now()
                .duration_since(UNIX_EPOCH)
                .map(|value| value.as_millis() as u64)
                .unwrap_or(0)
        } else {
            0
        };

        let tunnel_mode = self
            .active
            .lock()
            .unwrap()
            .as_ref()
            .map(TunnelSettings::tunnel_mode)
            .unwrap_or(false);

        let resolved = gateway.or_else(|| self.observed_gateway.lock().unwrap().clone());

        *self.snapshot.lock().unwrap() = Snapshot {
            stage,
            gateway: resolved,
            connected_at_millis: connected_at,
            message,
            tunnel_mode,
        };
    }

    pub fn core_version(&self) -> String {
        let binary = match self.core_binary.lock().unwrap().clone() {
            Some(path) => path,
            None => return "unavailable".to_string(),
        };

        Command::new(&binary)
            .arg("--version")
            .output()
            .ok()
            .and_then(|output| String::from_utf8(output.stdout).ok())
            .map(|value| value.trim().to_string())
            .filter(|value| !value.is_empty())
            .unwrap_or_else(|| "unavailable".to_string())
    }

    pub fn connect(self: &Arc<Self>, settings: TunnelSettings, arguments: Vec<String>) {
        self.disconnect();
        self.shutting_down.store(false, Ordering::SeqCst);
        *self.observed_gateway.lock().unwrap() = settings.manual_gateway();
        *self.active.lock().unwrap() = Some(settings.clone());

        let binary = match self.core_binary.lock().unwrap().clone() {
            Some(path) => path,
            None => {
                self.log_from("aether", "[-] aether core binary path was never registered");
                self.publish(Stage::Failed, Some("core binary missing".into()), None);
                return;
            }
        };

        if !binary.exists() {
            self.log(format!(
                "[-] aether core binary not found at {}",
                binary.display()
            ));
            self.publish(Stage::Failed, Some("core binary missing".into()), None);
            return;
        }

        self.publish(Stage::Connecting, None, None);

        let mut command = Command::new(&binary);
        command
            .args(&arguments)
            .stdin(Stdio::piped())
            .stdout(Stdio::piped())
            .stderr(Stdio::piped());

        for (key, value) in settings.core_environment() {
            command.env(key, value);
        }

        #[cfg(unix)]
        if settings.tunnel_mode() && net::is_privileged() {
            let dedicated = settings
                .bypass_uid
                .filter(|uid| *uid != net::effective_uid());
            if let Some(uid) = dedicated {
                use std::os::unix::process::CommandExt;
                unsafe {
                    command.pre_exec(move || {
                        if libc::setgid(uid) != 0 || libc::setuid(uid) != 0 {
                            return Err(std::io::Error::last_os_error());
                        }
                        Ok(())
                    });
                }
                self.log_from("aether", format!("[+] aether core will run as uid {uid}"));
            }
        }

        let mut child = match command.spawn() {
            Ok(child) => child,
            Err(error) => {
                self.log_from("aether", format!("[-] failed to launch the aether core: {error}"));
                self.publish(Stage::Failed, Some(error.to_string()), None);
                return;
            }
        };

        self.log_from("aether", format!("[+] aether core started: {}", arguments.join(" ")));

        if let Some(stdout) = child.stdout.take() {
            self.spawn_log_reader(stdout, "aether");
        }
        if let Some(stderr) = child.stderr.take() {
            self.spawn_log_reader(stderr, "aether");
        }

        *self.core_input.lock().unwrap() = child.stdin.take();
        *self.core.lock().unwrap() = Some(child);

        let supervisor = Arc::clone(self);
        thread::spawn(move || supervisor.await_validation(settings));
    }

    fn spawn_log_reader<R: std::io::Read + Send + 'static>(
        self: &Arc<Self>,
        stream: R,
        source: &'static str,
    ) {
        let supervisor = Arc::clone(self);
        thread::spawn(move || {
            let reader = BufReader::new(stream);
            for line in reader.lines().map_while(Result::ok) {
                supervisor.log_from(source, line);
            }
        });
    }

    fn spawn_log_tail(self: &Arc<Self>, path: PathBuf, source: &'static str) {
        let supervisor = Arc::clone(self);
        thread::spawn(move || {
            let mut offset: u64 = 0;
            let mut pending = String::new();
            let mut draining = true;

            while draining {
                draining = supervisor.device.is_running();

                match File::open(&path) {
                    Ok(mut file) => {
                        let length = file
                            .metadata()
                            .map(|value| value.len())
                            .unwrap_or(offset);
                        if length < offset {
                            offset = 0;
                        }
                        if length > MAX_TAILED_LOG_BYTES {
                            if OpenOptions::new()
                                .write(true)
                                .truncate(true)
                                .open(&path)
                                .is_ok()
                            {
                                offset = 0;
                                pending.clear();
                                supervisor.log_from(
                                    source,
                                    "log file grew past its budget and was truncated",
                                );
                                continue;
                            }
                        }
                        if length > offset
                            && file.seek(SeekFrom::Start(offset)).is_ok()
                        {
                            let mut chunk = String::new();
                            if BufReader::new(&mut file)
                                .read_to_string(&mut chunk)
                                .is_ok()
                            {
                                offset += chunk.len() as u64;
                                pending.push_str(&chunk);
                                while let Some(index) = pending.find('\n') {
                                    let line: String =
                                        pending.drain(..=index).collect();
                                    let line = line.trim_end().to_string();
                                    if !line.is_empty() {
                                        supervisor.log_from(source, line);
                                    }
                                }
                            }
                        }
                    }
                    Err(_) => {}
                }

                if draining {
                    thread::sleep(Duration::from_millis(400));
                }
            }

            let remainder = pending.trim_end();
            if !remainder.is_empty() {
                supervisor.log_from(source, remainder.to_string());
            }
        });
    }

    fn await_validation(self: Arc<Self>, settings: TunnelSettings) {
        self.publish(Stage::Validating, None, None);

        let budget = validation_budget(&settings.scan_mode);
        self.log_from(
            "aether",
            format!(
                "[*] waiting up to {}s for the tunnel on scan mode {}",
                budget.as_secs(),
                settings.scan_mode
            ),
        );

        let deadline = Instant::now() + budget;
        while Instant::now() < deadline {
            if self.shutting_down.load(Ordering::SeqCst) {
                return;
            }

            if !self.core_alive() {
                self.log_from("aether", "[-] the core stopped before the tunnel came up");
                self.disconnect();
                self.publish(Stage::Failed, Some("core stopped".into()), None);
                return;
            }

            if probe::socks_reachable(settings.socks_port) {
                self.log_from("aether", "[+] socks5 proxy answered a real request");
                let gateway = if settings.endpoint.trim().is_empty() {
                    None
                } else {
                    Some(settings.endpoint.trim().to_string())
                };

                if settings.tunnel_mode() {
                    if let Err(error) = self.raise_device(&settings) {
                        self.log_from("aether", format!("[-] tunnel mode unavailable: {error}"));
                        self.publish(Stage::Connected, Some(error), gateway);
                        return;
                    }
                } else if settings.system_proxy_mode() {
                    if let Err(error) = self.raise_system_proxy(&settings) {
                        self.log_from(
                            "aether",
                            format!("[-] system proxy unavailable: {error}"),
                        );
                        self.publish(Stage::Connected, Some(error), gateway);
                        return;
                    }
                }

                self.publish(Stage::Connected, None, gateway);
                return;
            }

            thread::sleep(VALIDATION_INTERVAL);
        }

        self.log_from(
            "aether",
            format!(
                "[-] no working tunnel after {}s on scan mode {}",
                budget.as_secs(),
                settings.scan_mode
            ),
        );
        self.disconnect();
        self.publish(Stage::Failed, Some("validation timeout".into()), None);
    }

    fn core_alive(self: &Arc<Self>) -> bool {
        let mut guard = match self.core.lock() {
            Ok(guard) => guard,
            Err(_) => return true,
        };
        match guard.as_mut() {
            Some(child) => !matches!(child.try_wait(), Ok(Some(_))),
            None => false,
        }
    }

    fn raise_device(
        self: &Arc<Self>,
        settings: &TunnelSettings,
    ) -> Result<(), String> {
        if !TunnelDevice::available() {
            return Err("this build does not embed the tunnel device".to_string());
        }

        if !net::is_privileged() {
            return Err(
                "tunnel mode needs elevated privileges, staying in proxy mode"
                    .to_string(),
            );
        }

        let log_path = hev_log_path(settings);
        match OpenOptions::new()
            .write(true)
            .create(true)
            .truncate(true)
            .open(&log_path)
        {
            Ok(mut file) => {
                let _ = file.write_all(b"");
            }
            Err(error) => {
                self.log(format!(
                    "[core] [-] could not prepare the hevtun log file: {error}"
                ));
            }
        }

        self.device
            .start(settings.hev_config(log_path.to_str()))?;
        self.spawn_log_tail(log_path.clone(), "hevtun");
        self.log(format!(
            "[core] [+] tunnel device requested on {}",
            settings.tunnel_interface
        ));

        if !net::wait_for_interface(&settings.tunnel_interface) {
            self.device.stop();
            return Err(format!(
                "the {} interface never appeared",
                settings.tunnel_interface
            ));
        }

        let bypass_uid = settings.bypass_uid.unwrap_or_else(net::effective_uid);
        self.log_from(
            "aether",
            format!("[+] traffic from uid {bypass_uid} stays outside the tunnel"),
        );

        let outcome = net::apply_tunnel_routes(
            &settings.tunnel_interface,
            bypass_uid,
            settings.dual_stack(),
        );

        for entry in &outcome.applied {
            self.log_from("aether", format!("[+] {entry}"));
        }
        for entry in &outcome.failures {
            self.log_from("aether", format!("[-] {entry}"));
        }

        if !outcome.bypass_ready {
            self.device.stop();
            net::revert_tunnel_routes(settings.dual_stack());
            return Err(
                "the engine bypass rule could not be installed, refusing to \
                 route traffic into a loop"
                    .to_string(),
            );
        }

        if !net::tunnel_default_installed() {
            self.device.stop();
            net::revert_tunnel_routes(settings.dual_stack());
            return Err(format!(
                "the default route could not be installed on {}",
                settings.tunnel_interface
            ));
        }

        if settings.override_dns {
            let servers = settings.dns_servers();
            match self.resolver.lock().unwrap().apply(&servers) {
                Ok(list) => self.log_from(
                    "aether",
                    format!("[+] resolver redirected through the tunnel: {list}"),
                ),
                Err(error) => self.log_from(
                    "aether",
                    format!("[!] could not redirect the resolver: {error}"),
                ),
            }
        }

        self.log_from("aether", "[+] system traffic is now routed through the tunnel");
        Ok(())
    }

    fn raise_system_proxy(self: &Arc<Self>, settings: &TunnelSettings) -> Result<(), String> {
        let host = if settings.allow_lan {
            "127.0.0.1"
        } else {
            settings.bind_host()
        };

        let http_port = settings.http_proxy_port();
        let outcome = self
            .proxy
            .lock()
            .unwrap()
            .apply(host, settings.socks_port, http_port)?;

        self.log_from(
            "aether",
            format!(
                "[+] system proxy points http at {host}:{http_port} and socks at {host}:{} ({outcome})",
                settings.socks_port
            ),
        );
        Ok(())
    }

    fn lower_system_proxy(&self) {
        let mut proxy = self.proxy.lock().unwrap();
        if !proxy.is_active() {
            return;
        }
        proxy.restore();
        drop(proxy);
        self.log_from("aether", "[-] system proxy settings restored");
    }

    fn lower_device(&self) {
        if !self.device.is_running() {
            return;
        }

        let dual = self
            .active
            .lock()
            .unwrap()
            .as_ref()
            .map(TunnelSettings::dual_stack)
            .unwrap_or(false);

        let mut resolver = self.resolver.lock().unwrap();
        if resolver.is_active() {
            resolver.restore();
            self.log_from("aether", "[-] resolver restored");
        }
        drop(resolver);

        net::revert_tunnel_routes(dual);
        self.device.stop();
        self.log_from("aether", "[-] tunnel device stopped and routes restored");
    }

    pub fn disconnect(&self) {
        self.shutting_down.store(true, Ordering::SeqCst);
        self.lower_system_proxy();
        self.lower_device();

        drop(self.core_input.lock().unwrap().take());

        let mut guard = self.core.lock().unwrap();
        if let Some(mut child) = guard.take() {
            self.publish(Stage::Disconnecting, None, None);
            let _ = child.kill();
            let _ = child.wait();
            self.log_from("aether", "[-] aether core stopped");
        }
        drop(guard);

        *self.observed_gateway.lock().unwrap() = None;
        self.publish(Stage::Disconnected, None, None);
    }
}

impl Default for Supervisor {
    fn default() -> Self {
        Self::new()
    }
}
