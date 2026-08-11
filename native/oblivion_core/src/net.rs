use std::path::Path;
use std::process::Command;
use std::thread;
use std::time::{Duration, Instant};

pub const ROUTE_TABLE: &str = "8319";
pub const BYPASS_PRIORITY: &str = "8310";
pub const LOCAL_PRIORITY: &str = "8318";
pub const TUNNEL_PRIORITY: &str = "8320";

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

pub fn is_privileged() -> bool {
    #[cfg(unix)]
    unsafe {
        libc::geteuid() == 0
    }
    #[cfg(not(unix))]
    false
}

pub fn effective_uid() -> u32 {
    #[cfg(unix)]
    unsafe {
        libc::geteuid()
    }
    #[cfg(not(unix))]
    0
}

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

fn run_quiet(arguments: &[&str]) {
    let _ = Command::new("ip").args(arguments).output();
}

pub fn apply_tunnel_routes(
    interface: &str,
    bypass_uid: u32,
    ipv6: bool,
) -> RouteOutcome {
    let mut outcome = RouteOutcome::new();

    revert_tunnel_routes(ipv6);

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
        run(
            &[
                "-6", "rule", "add", "uidrange", &range, "lookup", "main",
                "pref", BYPASS_PRIORITY,
            ],
            &mut outcome,
        );
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

pub fn tunnel_default_installed() -> bool {
    Command::new("ip")
        .args(["route", "show", "table", ROUTE_TABLE])
        .output()
        .map(|output| {
            String::from_utf8_lossy(&output.stdout).contains("default")
        })
        .unwrap_or(false)
}

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
