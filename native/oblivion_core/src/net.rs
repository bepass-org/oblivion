use std::path::Path;
#[cfg(unix)]
use std::net::IpAddr;
#[cfg(unix)]
use std::process::Command;
#[cfg(unix)]
use std::thread;
#[cfg(unix)]
use std::time::{Duration, Instant};

pub const ROUTE_TABLE: &str = "8319";
pub const BYPASS_PRIORITY: &str = "8310";
pub const LOCAL_PRIORITY: &str = "8318";
pub const TUNNEL_PRIORITY: &str = "8320";

#[cfg(unix)]
const INTERFACE_TIMEOUT: Duration = Duration::from_secs(10);

#[derive(Debug)]
pub struct RouteOutcome {
    pub applied: Vec<String>,
    pub failures: Vec<String>,
    pub bypass_ready: bool,
}

impl RouteOutcome {
    fn new() -> Self {
        Self {
            applied: Vec::new(),
            failures: Vec::new(),
            bypass_ready: false,
        }
    }
}

#[cfg(unix)]
pub fn is_privileged() -> bool {
    unsafe { libc::geteuid() == 0 }
}

#[cfg(windows)]
pub fn is_privileged() -> bool {
    use std::mem::size_of;
    use windows_sys::Win32::Foundation::{CloseHandle, HANDLE};
    use windows_sys::Win32::Security::{
        GetTokenInformation, TokenElevation, TOKEN_ELEVATION, TOKEN_QUERY,
    };
    use windows_sys::Win32::System::Threading::{GetCurrentProcess, OpenProcessToken};

    unsafe {
        let mut token: HANDLE = std::ptr::null_mut();
        if OpenProcessToken(GetCurrentProcess(), TOKEN_QUERY, &mut token) == 0 {
            return false;
        }

        let mut elevation = TOKEN_ELEVATION { TokenIsElevated: 0 };
        let mut returned = 0u32;
        let queried = GetTokenInformation(
            token,
            TokenElevation,
            &mut elevation as *mut _ as *mut _,
            size_of::<TOKEN_ELEVATION>() as u32,
            &mut returned,
        );
        CloseHandle(token);

        queried != 0 && elevation.TokenIsElevated != 0
    }
}

#[cfg(unix)]
pub fn elevator() -> Option<String> {
    for candidate in ["pkexec"] {
        if let Ok(output) = Command::new("sh")
            .args(["-c", &format!("command -v {candidate}")])
            .output()
        {
            if output.status.success() {
                let path = String::from_utf8_lossy(&output.stdout).trim().to_string();
                if !path.is_empty() {
                    return Some(path);
                }
            }
        }
    }
    None
}

#[cfg(windows)]
pub fn elevator() -> Option<String> {
    Some("runas".to_string())
}

pub fn effective_uid() -> u32 {
    #[cfg(unix)]
    unsafe {
        libc::geteuid()
    }
    #[cfg(not(unix))]
    0
}

#[cfg(unix)]
fn interface_is_up(name: &str) -> bool {
    let flags = match std::fs::read_to_string(format!("/sys/class/net/{name}/flags")) {
        Ok(value) => value,
        Err(_) => return false,
    };
    let trimmed = flags.trim().trim_start_matches("0x");
    u32::from_str_radix(trimmed, 16)
        .map(|value| value & 0x1 != 0)
        .unwrap_or(false)
}

#[cfg(windows)]
#[path = "net_windows.rs"]
mod imp;

#[cfg(windows)]
pub use imp::{
    apply_tunnel_routes, default_route, parse_default_route, revert_tunnel_routes,
    revert_tunnel_routes_with_edge, tunnel_default_installed, wait_for_interface,
};

#[cfg(unix)]
pub fn wait_for_interface(name: &str) -> bool {
    let path = format!("/sys/class/net/{name}");
    let deadline = Instant::now() + INTERFACE_TIMEOUT;
    while Instant::now() < deadline {
        if Path::new(&path).exists() && interface_is_up(name) {
            return true;
        }
        thread::sleep(Duration::from_millis(100));
    }
    false
}

#[cfg(unix)]
fn run(arguments: &[&str], outcome: &mut RouteOutcome) {
    let rendered = format!("ip {}", arguments.join(" "));
    match Command::new("ip").args(arguments).output() {
        Ok(output) if output.status.success() => outcome.applied.push(rendered),
        Ok(output) => {
            let error = String::from_utf8_lossy(&output.stderr).trim().to_string();
            outcome.failures.push(format!("{rendered}: {error}"));
        }
        Err(error) => outcome.failures.push(format!("{rendered}: {error}")),
    }
}

#[cfg(unix)]
fn run_quiet(arguments: &[&str]) {
    let _ = Command::new("ip").args(arguments).output();
}

#[cfg(unix)]
fn pin_edge_route(edge: IpAddr, outcome: &mut RouteOutcome) -> bool {
    let ipv6 = edge.is_ipv6();
    let route = match default_route(ipv6) {
        Some(route) => route,
        None => {
            outcome.failures.push(format!(
                "no default route to pin {edge} to; the engine would be routed into the tunnel"
            ));
            return false;
        }
    };

    let host = if ipv6 {
        format!("{edge}/128")
    } else {
        format!("{edge}/32")
    };

    let mut arguments: Vec<&str> = Vec::new();
    if ipv6 {
        arguments.push("-6");
    }
    arguments.extend_from_slice(&["route", "add", &host]);
    if let Some(gateway) = &route.gateway {
        arguments.extend_from_slice(&["via", gateway]);
    }
    arguments.extend_from_slice(&["dev", &route.device]);

    run(&arguments, outcome);
    true
}

#[cfg(unix)]
fn drop_edge_route(edge: IpAddr) {
    let ipv6 = edge.is_ipv6();
    let host = if ipv6 {
        format!("{edge}/128")
    } else {
        format!("{edge}/32")
    };

    let mut arguments: Vec<&str> = Vec::new();
    if ipv6 {
        arguments.push("-6");
    }
    arguments.extend_from_slice(&["route", "del", &host]);
    run_quiet(&arguments);
}

#[cfg(unix)]
pub fn apply_tunnel_routes(
    interface: &str,
    bypass_uid: u32,
    ipv6: bool,
    edge: Option<IpAddr>,
) -> RouteOutcome {
    let mut outcome = RouteOutcome::new();

    revert_tunnel_routes_with_edge(ipv6, edge);

    outcome.bypass_ready = false;

    if let Some(edge) = edge {
        let before = outcome.failures.len();
        match pin_edge_route(edge, &mut outcome) {
            true => outcome.bypass_ready = outcome.failures.len() == before,
            false => return outcome,
        }
    }

    let mut uid_bypassed = false;
    if !outcome.bypass_ready && bypass_uid != 0 {
        let range = format!("{bypass_uid}-{bypass_uid}");
        let before = outcome.failures.len();
        run(
            &[
                "rule", "add", "uidrange", &range, "lookup", "main", "pref",
                BYPASS_PRIORITY,
            ],
            &mut outcome,
        );
        outcome.bypass_ready = outcome.failures.len() == before;
        uid_bypassed = outcome.bypass_ready;
    }

    if !outcome.bypass_ready {
        return outcome;
    }

    run(
        &[
            "rule", "add", "lookup", "main", "suppress_prefixlength", "0",
            "pref", LOCAL_PRIORITY,
        ],
        &mut outcome,
    );
    run(
        &[
            "route", "add", "default", "dev", interface, "table", ROUTE_TABLE,
        ],
        &mut outcome,
    );
    run(
        &["rule", "add", "lookup", ROUTE_TABLE, "pref", TUNNEL_PRIORITY],
        &mut outcome,
    );

    if ipv6 {
        if uid_bypassed {
            let range = format!("{bypass_uid}-{bypass_uid}");
            run(
                &[
                    "-6", "rule", "add", "uidrange", &range, "lookup", "main",
                    "pref", BYPASS_PRIORITY,
                ],
                &mut outcome,
            );
        }
        run(
            &[
                "-6", "rule", "add", "lookup", "main",
                "suppress_prefixlength", "0", "pref", LOCAL_PRIORITY,
            ],
            &mut outcome,
        );
        run(
            &[
                "-6", "route", "add", "default", "dev", interface, "table",
                ROUTE_TABLE,
            ],
            &mut outcome,
        );
        run(
            &[
                "-6", "rule", "add", "lookup", ROUTE_TABLE, "pref",
                TUNNEL_PRIORITY,
            ],
            &mut outcome,
        );
    }

    outcome
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct DefaultRoute {
    pub gateway: Option<String>,
    pub device: String,
}

#[cfg(unix)]
pub fn parse_default_route(raw: &str) -> Option<DefaultRoute> {
    for line in raw.lines() {
        let fields: Vec<&str> = line.split_whitespace().collect();
        if fields.first() != Some(&"default") {
            continue;
        }

        let gateway = fields
            .iter()
            .position(|field| *field == "via")
            .and_then(|at| fields.get(at + 1))
            .map(|value| value.to_string());

        let device = fields
            .iter()
            .position(|field| *field == "dev")
            .and_then(|at| fields.get(at + 1))
            .map(|value| value.to_string())?;

        return Some(DefaultRoute { gateway, device });
    }
    None
}

#[cfg(unix)]
pub fn default_route(ipv6: bool) -> Option<DefaultRoute> {
    let mut arguments = Vec::new();
    if ipv6 {
        arguments.push("-6");
    }
    arguments.extend_from_slice(&["route", "show", "default", "table", "main"]);

    let output = Command::new("ip").args(&arguments).output().ok()?;
    parse_default_route(&String::from_utf8_lossy(&output.stdout))
}

#[cfg(unix)]
pub fn tunnel_default_installed() -> bool {
    Command::new("ip")
        .args(["route", "show", "table", ROUTE_TABLE])
        .output()
        .map(|output| {
            String::from_utf8_lossy(&output.stdout).contains("default")
        })
        .unwrap_or(false)
}

#[cfg(unix)]
pub fn revert_tunnel_routes_with_edge(ipv6: bool, edge: Option<IpAddr>) {
    if let Some(edge) = edge {
        drop_edge_route(edge);
    }
    revert_tunnel_routes(ipv6);
}

#[cfg(unix)]
pub fn revert_tunnel_routes(ipv6: bool) {
    for _ in 0..4 {
        run_quiet(&["rule", "del", "pref", BYPASS_PRIORITY]);
        run_quiet(&["rule", "del", "pref", LOCAL_PRIORITY]);
        run_quiet(&["rule", "del", "pref", TUNNEL_PRIORITY]);
    }
    run_quiet(&["route", "flush", "table", ROUTE_TABLE]);

    if ipv6 {
        for _ in 0..4 {
            run_quiet(&["-6", "rule", "del", "pref", BYPASS_PRIORITY]);
            run_quiet(&["-6", "rule", "del", "pref", LOCAL_PRIORITY]);
            run_quiet(&["-6", "rule", "del", "pref", TUNNEL_PRIORITY]);
        }
        run_quiet(&["-6", "route", "flush", "table", ROUTE_TABLE]);
    }
}

#[cfg(unix)]
pub struct ElevatedProcess {
    child: std::process::Child,
}

#[cfg(unix)]
impl ElevatedProcess {
    pub fn is_running(&mut self) -> bool {
        !matches!(self.child.try_wait(), Ok(Some(_)))
    }

    pub fn take_stdout(&mut self) -> Option<std::process::ChildStdout> {
        self.child.stdout.take()
    }

    pub fn take_stderr(&mut self) -> Option<std::process::ChildStderr> {
        self.child.stderr.take()
    }
}

#[cfg(windows)]
pub struct ElevatedProcess {
    handle: windows_sys::Win32::Foundation::HANDLE,
}

#[cfg(windows)]
unsafe impl Send for ElevatedProcess {}

#[cfg(windows)]
impl ElevatedProcess {
    pub fn is_running(&mut self) -> bool {
        use windows_sys::Win32::Foundation::WAIT_TIMEOUT;
        use windows_sys::Win32::System::Threading::WaitForSingleObject;

        unsafe { WaitForSingleObject(self.handle, 0) == WAIT_TIMEOUT }
    }

    pub fn take_stdout(&mut self) -> Option<std::process::ChildStdout> {
        None
    }

    pub fn take_stderr(&mut self) -> Option<std::process::ChildStderr> {
        None
    }
}

#[cfg(windows)]
impl Drop for ElevatedProcess {
    fn drop(&mut self) {
        use windows_sys::Win32::Foundation::CloseHandle;

        if !self.handle.is_null() {
            unsafe { CloseHandle(self.handle) };
        }
    }
}

#[cfg(unix)]
pub fn spawn_elevated(
    elevator: &str,
    program: &Path,
    argument: &Path,
) -> std::io::Result<ElevatedProcess> {
    let child = Command::new(elevator)
        .arg(program)
        .arg(argument)
        .stdout(std::process::Stdio::piped())
        .stderr(std::process::Stdio::piped())
        .spawn()?;
    Ok(ElevatedProcess { child })
}

#[cfg(windows)]
pub fn spawn_elevated(
    _elevator: &str,
    program: &Path,
    argument: &Path,
) -> std::io::Result<ElevatedProcess> {
    use std::ffi::OsStr;
    use std::os::windows::ffi::OsStrExt;
    use windows_sys::Win32::UI::Shell::{
        ShellExecuteExW, SEE_MASK_NOCLOSEPROCESS, SHELLEXECUTEINFOW,
    };
    use windows_sys::Win32::UI::WindowsAndMessaging::SW_HIDE;

    fn wide(value: &OsStr) -> Vec<u16> {
        value.encode_wide().chain(std::iter::once(0)).collect()
    }

    let verb = wide(OsStr::new("runas"));
    let file = wide(program.as_os_str());
    let parameters = wide(OsStr::new(&format!("\"{}\"", argument.display())));

    let mut info: SHELLEXECUTEINFOW = unsafe { std::mem::zeroed() };
    info.cbSize = std::mem::size_of::<SHELLEXECUTEINFOW>() as u32;
    info.fMask = SEE_MASK_NOCLOSEPROCESS;
    info.lpVerb = verb.as_ptr();
    info.lpFile = file.as_ptr();
    info.lpParameters = parameters.as_ptr();
    info.nShow = SW_HIDE as i32;

    if unsafe { ShellExecuteExW(&mut info) } == 0 || info.hProcess.is_null() {
        return Err(std::io::Error::last_os_error());
    }

    Ok(ElevatedProcess {
        handle: info.hProcess,
    })
}

#[cfg(test)]
mod default_route_tests {
    use super::parse_default_route;

    #[test]
    fn a_normal_default_route_gives_the_gateway_and_device() {
        let route =
            parse_default_route("default via 192.168.1.1 dev wlan0 proto dhcp metric 600")
                .expect("a default route");
        assert_eq!(route.gateway.as_deref(), Some("192.168.1.1"));
        assert_eq!(route.device, "wlan0");
    }

    #[test]
    fn a_point_to_point_link_has_a_device_but_no_gateway() {
        let route = parse_default_route("default dev ppp0 scope link").expect("a default route");
        assert_eq!(route.gateway, None);
        assert_eq!(route.device, "ppp0");
    }

    #[test]
    fn an_ipv6_default_route_is_read_the_same_way() {
        let route = parse_default_route("default via fe80::1 dev eth0 metric 1024 pref medium")
            .expect("a default route");
        assert_eq!(route.gateway.as_deref(), Some("fe80::1"));
        assert_eq!(route.device, "eth0");
    }

    #[test]
    fn the_first_default_wins_when_several_are_listed() {
        let raw = "default via 10.0.0.1 dev eth0 metric 100\ndefault via 10.0.1.1 dev eth1 metric 200";
        let route = parse_default_route(raw).expect("a default route");
        assert_eq!(route.gateway.as_deref(), Some("10.0.0.1"));
        assert_eq!(route.device, "eth0");
    }

    #[test]
    fn a_table_without_a_default_gives_nothing() {
        assert!(parse_default_route("").is_none());
        assert!(parse_default_route("10.0.0.0/8 dev eth0 scope link").is_none());
    }

    #[test]
    fn a_default_without_a_device_is_refused() {
        assert!(parse_default_route("default via 192.168.1.1").is_none());
    }
}
