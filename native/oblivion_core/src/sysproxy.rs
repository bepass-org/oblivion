#[cfg(any(target_os = "linux", target_os = "windows", target_os = "macos"))]
use std::process::Command;

#[cfg(target_os = "linux")]
#[derive(Debug, Clone, Default)]
struct GnomeSnapshot {
    mode: String,
    host: String,
    port: String,
    use_same: String,
    http_host: String,
    http_port: String,
    https_host: String,
    https_port: String,
}

#[cfg(target_os = "linux")]
#[derive(Debug, Clone, Default)]
struct KdeSnapshot {
    tool: String,
    proxy_type: String,
    socks_proxy: String,
    http_proxy: String,
    https_proxy: String,
}

#[cfg(target_os = "windows")]
#[derive(Debug, Clone, Default)]
struct WindowsSnapshot {
    enable: String,
    server: String,
}

#[derive(Debug, Default)]
pub struct SystemProxy {
    #[cfg(target_os = "linux")]
    gnome: Option<GnomeSnapshot>,
    #[cfg(target_os = "linux")]
    kde: Option<KdeSnapshot>,
    #[cfg(target_os = "windows")]
    windows: Option<WindowsSnapshot>,
    #[cfg(target_os = "macos")]
    macos: Vec<String>,
    active: bool,
}

impl SystemProxy {
    pub fn new() -> Self {
        Self::default()
    }

    pub fn is_active(&self) -> bool {
        self.active
    }

    pub fn apply(&mut self, host: &str, port: u16, http_port: u16) -> Result<String, String> {
        if self.active {
            self.restore();
        }

        let mut applied: Vec<String> = Vec::new();
        let mut failures: Vec<String> = Vec::new();

        #[cfg(target_os = "linux")]
        {
            match self.apply_gnome(host, port, http_port) {
                Ok(true) => applied.push("gnome".to_string()),
                Ok(false) => {}
                Err(error) => failures.push(format!("gnome: {error}")),
            }
            match self.apply_kde(host, port, http_port) {
                Ok(true) => applied.push("kde".to_string()),
                Ok(false) => {}
                Err(error) => failures.push(format!("kde: {error}")),
            }
        }

        #[cfg(target_os = "windows")]
        match self.apply_windows(host, port, http_port) {
            Ok(()) => applied.push("windows".to_string()),
            Err(error) => failures.push(format!("windows: {error}")),
        }

        #[cfg(target_os = "macos")]
        match self.apply_macos(host, port, http_port) {
            Ok(services) if !services.is_empty() => {
                applied.push(format!("macos ({})", services.join(", ")))
            }
            Ok(_) => {}
            Err(error) => failures.push(format!("macos: {error}")),
        }

        if applied.is_empty() {
            let detail = if failures.is_empty() {
                "no supported desktop proxy backend was found".to_string()
            } else {
                failures.join("; ")
            };
            return Err(detail);
        }

        self.active = true;
        Ok(applied.join(", "))
    }

    pub fn restore(&mut self) {
        #[cfg(target_os = "linux")]
        {
            self.restore_gnome();
            self.restore_kde();
        }

        #[cfg(target_os = "windows")]
        self.restore_windows();

        #[cfg(target_os = "macos")]
        self.restore_macos();

        self.active = false;
    }
}

#[cfg(any(target_os = "linux", target_os = "windows", target_os = "macos"))]
fn capture(program: &str, arguments: &[&str]) -> Option<String> {
    let output = Command::new(program).args(arguments).output().ok()?;
    if !output.status.success() {
        return None;
    }
    Some(String::from_utf8_lossy(&output.stdout).trim().to_string())
}

#[cfg(any(target_os = "linux", target_os = "windows", target_os = "macos"))]
fn perform(program: &str, arguments: &[&str]) -> Result<(), String> {
    let output = Command::new(program)
        .args(arguments)
        .output()
        .map_err(|error| format!("{program}: {error}"))?;
    if output.status.success() {
        return Ok(());
    }
    let detail = String::from_utf8_lossy(&output.stderr).trim().to_string();
    Err(if detail.is_empty() {
        format!("{program} {} failed", arguments.join(" "))
    } else {
        detail
    })
}

#[cfg(target_os = "linux")]
impl SystemProxy {
    fn apply_gnome(&mut self, host: &str, port: u16, http_port: u16) -> Result<bool, String> {
        let mode = match capture("gsettings", &["get", "org.gnome.system.proxy", "mode"]) {
            Some(value) => value,
            None => return Ok(false),
        };

        let snapshot = GnomeSnapshot {
            mode,
            host: capture("gsettings", &["get", "org.gnome.system.proxy.socks", "host"])
                .unwrap_or_else(|| "''".to_string()),
            port: capture("gsettings", &["get", "org.gnome.system.proxy.socks", "port"])
                .unwrap_or_else(|| "0".to_string()),
            use_same: capture(
                "gsettings",
                &["get", "org.gnome.system.proxy", "use-same-proxy"],
            )
            .unwrap_or_else(|| "true".to_string()),
            http_host: capture("gsettings", &["get", "org.gnome.system.proxy.http", "host"])
                .unwrap_or_else(|| "''".to_string()),
            http_port: capture("gsettings", &["get", "org.gnome.system.proxy.http", "port"])
                .unwrap_or_else(|| "0".to_string()),
            https_host: capture("gsettings", &["get", "org.gnome.system.proxy.https", "host"])
                .unwrap_or_else(|| "''".to_string()),
            https_port: capture("gsettings", &["get", "org.gnome.system.proxy.https", "port"])
                .unwrap_or_else(|| "0".to_string()),
        };

        let port_text = port.to_string();
        let http_text = http_port.to_string();

        for schema in ["org.gnome.system.proxy.http", "org.gnome.system.proxy.https"] {
            perform("gsettings", &["set", schema, "host", host])?;
            perform("gsettings", &["set", schema, "port", &http_text])?;
        }

        perform(
            "gsettings",
            &["set", "org.gnome.system.proxy.socks", "host", host],
        )?;
        perform(
            "gsettings",
            &["set", "org.gnome.system.proxy.socks", "port", &port_text],
        )?;
        perform(
            "gsettings",
            &["set", "org.gnome.system.proxy", "use-same-proxy", "false"],
        )?;
        perform("gsettings", &["set", "org.gnome.system.proxy", "mode", "manual"])?;

        self.gnome = Some(snapshot);
        Ok(true)
    }

    fn restore_gnome(&mut self) {
        let snapshot = match self.gnome.take() {
            Some(value) => value,
            None => return,
        };

        let mode = snapshot.mode.trim().trim_matches('\'').to_string();
        let host = snapshot.host.trim().trim_matches('\'').to_string();
        let port = snapshot.port.trim().to_string();
        let use_same = snapshot.use_same.trim().to_string();
        let http_host = snapshot.http_host.trim().trim_matches('\'').to_string();
        let http_port = snapshot.http_port.trim().to_string();
        let https_host = snapshot.https_host.trim().trim_matches('\'').to_string();
        let https_port = snapshot.https_port.trim().to_string();

        let _ = perform(
            "gsettings",
            &["set", "org.gnome.system.proxy.http", "host", &http_host],
        );
        let _ = perform(
            "gsettings",
            &["set", "org.gnome.system.proxy.http", "port", &http_port],
        );
        let _ = perform(
            "gsettings",
            &["set", "org.gnome.system.proxy.https", "host", &https_host],
        );
        let _ = perform(
            "gsettings",
            &["set", "org.gnome.system.proxy.https", "port", &https_port],
        );
        let _ = perform(
            "gsettings",
            &["set", "org.gnome.system.proxy.socks", "host", &host],
        );
        let _ = perform(
            "gsettings",
            &["set", "org.gnome.system.proxy.socks", "port", &port],
        );
        let _ = perform(
            "gsettings",
            &["set", "org.gnome.system.proxy", "use-same-proxy", &use_same],
        );
        let _ = perform(
            "gsettings",
            &["set", "org.gnome.system.proxy", "mode", &mode],
        );
    }

    fn kde_tools() -> Option<(String, String)> {
        for (writer, reader) in [
            ("kwriteconfig6", "kreadconfig6"),
            ("kwriteconfig5", "kreadconfig5"),
        ] {
            if capture(reader, &["--file", "kioslaverc", "--group", "Proxy Settings", "--key", "ProxyType"]).is_some()
                || Command::new(writer).arg("--help").output().is_ok()
            {
                return Some((writer.to_string(), reader.to_string()));
            }
        }
        None
    }

    fn kde_read(reader: &str, key: &str) -> String {
        capture(
            reader,
            &[
                "--file",
                "kioslaverc",
                "--group",
                "Proxy Settings",
                "--key",
                key,
            ],
        )
        .unwrap_or_default()
    }

    fn kde_write(writer: &str, key: &str, value: &str) -> Result<(), String> {
        perform(
            writer,
            &[
                "--file",
                "kioslaverc",
                "--group",
                "Proxy Settings",
                "--key",
                key,
                value,
            ],
        )
    }

    fn apply_kde(&mut self, host: &str, port: u16, http_port: u16) -> Result<bool, String> {
        let (writer, reader) = match Self::kde_tools() {
            Some(pair) => pair,
            None => return Ok(false),
        };

        let snapshot = KdeSnapshot {
            tool: writer.clone(),
            http_proxy: Self::kde_read(&reader, "httpProxy"),
            https_proxy: Self::kde_read(&reader, "httpsProxy"),
            proxy_type: capture(
                &reader,
                &[
                    "--file",
                    "kioslaverc",
                    "--group",
                    "Proxy Settings",
                    "--key",
                    "ProxyType",
                ],
            )
            .unwrap_or_else(|| "0".to_string()),
            socks_proxy: capture(
                &reader,
                &[
                    "--file",
                    "kioslaverc",
                    "--group",
                    "Proxy Settings",
                    "--key",
                    "socksProxy",
                ],
            )
            .unwrap_or_default(),
        };

        let web = format!("http://{host} {http_port}");
        Self::kde_write(&writer, "httpProxy", &web)?;
        Self::kde_write(&writer, "httpsProxy", &web)?;
        Self::kde_write(&writer, "socksProxy", &format!("socks://{host} {port}"))?;
        Self::kde_write(&writer, "ProxyType", "1")?;

        notify_kde();
        self.kde = Some(snapshot);
        Ok(true)
    }

    fn restore_kde(&mut self) {
        let snapshot = match self.kde.take() {
            Some(value) => value,
            None => return,
        };

        let _ = Self::kde_write(&snapshot.tool, "httpProxy", &snapshot.http_proxy);
        let _ = Self::kde_write(&snapshot.tool, "httpsProxy", &snapshot.https_proxy);
        let _ = Self::kde_write(&snapshot.tool, "socksProxy", &snapshot.socks_proxy);
        let _ = Self::kde_write(&snapshot.tool, "ProxyType", &snapshot.proxy_type);

        notify_kde();
    }
}

#[cfg(target_os = "linux")]
fn notify_kde() {
    let _ = Command::new("dbus-send")
        .args([
            "--type=signal",
            "/KIO/Scheduler",
            "org.kde.KIO.Scheduler.reparseSlaveConfiguration",
            "string:",
        ])
        .output();
}

#[cfg(target_os = "windows")]
impl SystemProxy {
    const KEY: &'static str =
        "HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Internet Settings";

    fn read_registry(name: &str) -> Option<String> {
        let output = capture("reg", &["query", Self::KEY, "/v", name])?;
        let line = output.lines().find(|line| line.contains(name))?;
        let mut parts = line.split_whitespace();
        parts.next()?;
        parts.next()?;
        Some(parts.collect::<Vec<&str>>().join(" "))
    }

    fn apply_windows(&mut self, host: &str, port: u16, http_port: u16) -> Result<(), String> {
        let snapshot = WindowsSnapshot {
            enable: Self::read_registry("ProxyEnable").unwrap_or_else(|| "0".to_string()),
            server: Self::read_registry("ProxyServer").unwrap_or_default(),
        };

        let server =
            format!("http={host}:{http_port};https={host}:{http_port};socks={host}:{port}");
        perform(
            "reg",
            &[
                "add", Self::KEY, "/v", "ProxyServer", "/t", "REG_SZ", "/d", &server, "/f",
            ],
        )?;
        perform(
            "reg",
            &[
                "add", Self::KEY, "/v", "ProxyEnable", "/t", "REG_DWORD", "/d", "1", "/f",
            ],
        )?;

        self.windows = Some(snapshot);
        Ok(())
    }

    fn restore_windows(&mut self) {
        let snapshot = match self.windows.take() {
            Some(value) => value,
            None => return,
        };

        let enable = if snapshot.enable.trim().ends_with('1') {
            "1"
        } else {
            "0"
        };

        if snapshot.server.trim().is_empty() {
            let _ = perform("reg", &["delete", Self::KEY, "/v", "ProxyServer", "/f"]);
        } else {
            let _ = perform(
                "reg",
                &[
                    "add",
                    Self::KEY,
                    "/v",
                    "ProxyServer",
                    "/t",
                    "REG_SZ",
                    "/d",
                    snapshot.server.trim(),
                    "/f",
                ],
            );
        }

        let _ = perform(
            "reg",
            &[
                "add", Self::KEY, "/v", "ProxyEnable", "/t", "REG_DWORD", "/d", enable, "/f",
            ],
        );
    }
}

#[cfg(target_os = "macos")]
impl SystemProxy {
    fn services() -> Vec<String> {
        let listing = match capture("networksetup", &["-listallnetworkservices"]) {
            Some(value) => value,
            None => return Vec::new(),
        };

        listing
            .lines()
            .skip(1)
            .map(|line| line.trim().to_string())
            .filter(|line| !line.is_empty() && !line.starts_with('*'))
            .collect()
    }

    fn apply_macos(
        &mut self,
        host: &str,
        port: u16,
        http_port: u16,
    ) -> Result<Vec<String>, String> {
        let port_text = port.to_string();
        let http_text = http_port.to_string();
        let mut touched = Vec::new();

        for service in Self::services() {
            if perform(
                "networksetup",
                &["-setsocksfirewallproxy", &service, host, &port_text],
            )
            .is_ok()
            {
                let _ =
                    perform("networksetup", &["-setsocksfirewallproxystate", &service, "on"]);

                for (setter, state) in [
                    ("-setwebproxy", "-setwebproxystate"),
                    ("-setsecurewebproxy", "-setsecurewebproxystate"),
                ] {
                    if perform("networksetup", &[setter, &service, host, &http_text]).is_ok() {
                        let _ = perform("networksetup", &[state, &service, "on"]);
                    }
                }

                touched.push(service);
            }
        }

        if touched.is_empty() {
            return Err("no configurable network service was found".to_string());
        }

        self.macos = touched.clone();
        Ok(touched)
    }

    fn restore_macos(&mut self) {
        for service in std::mem::take(&mut self.macos) {
            for state in [
                "-setsocksfirewallproxystate",
                "-setwebproxystate",
                "-setsecurewebproxystate",
            ] {
                let _ = perform("networksetup", &[state, &service, "off"]);
            }
        }
    }
}
