use std::fs;
use std::path::{Path, PathBuf};
use std::thread;
use std::time::Duration;

use crate::dns::DnsOverride;
use crate::net;
use crate::settings::TunnelSettings;
use crate::tunnel::TunnelDevice;

pub const REQUEST_FILE: &str = "tunnel.json";
pub const STOP_FILE: &str = "stop";
pub const READY_FILE: &str = "ready";
pub const STATS_FILE: &str = "stats";
pub const ERROR_FILE: &str = "error";
pub const LOG_FILE: &str = "hevtun.log";

const POLL_INTERVAL: Duration = Duration::from_millis(500);

pub struct Paths {
    pub root: PathBuf,
}

impl Paths {
    pub fn new(root: impl Into<PathBuf>) -> Self {
        Self { root: root.into() }
    }

    pub fn request(&self) -> PathBuf {
        self.root.join(REQUEST_FILE)
    }

    pub fn stop(&self) -> PathBuf {
        self.root.join(STOP_FILE)
    }

    pub fn ready(&self) -> PathBuf {
        self.root.join(READY_FILE)
    }

    pub fn stats(&self) -> PathBuf {
        self.root.join(STATS_FILE)
    }

    pub fn error(&self) -> PathBuf {
        self.root.join(ERROR_FILE)
    }

    pub fn log(&self) -> PathBuf {
        self.root.join(LOG_FILE)
    }

    pub fn clear(&self) {
        let _ = fs::remove_file(self.stop());
        let _ = fs::remove_file(self.ready());
        let _ = fs::remove_file(self.stats());
        let _ = fs::remove_file(self.error());
    }
}

pub fn read_stats(path: &Path) -> Option<(u64, u64, u64, u64)> {
    let raw = fs::read_to_string(path).ok()?;
    let mut parts = raw.split_whitespace();
    let tx_packets = parts.next()?.parse().ok()?;
    let tx_bytes = parts.next()?.parse().ok()?;
    let rx_packets = parts.next()?.parse().ok()?;
    let rx_bytes = parts.next()?.parse().ok()?;
    Some((tx_packets, tx_bytes, rx_packets, rx_bytes))
}

fn fail(paths: &Paths, reason: &str) -> i32 {
    let _ = fs::write(paths.error(), reason);
    eprintln!("[helper] {reason}");
    1
}

pub fn invoking_uid(requested: Option<u32>) -> Option<u32> {
    if let Some(uid) = requested.filter(|uid| *uid != 0) {
        return Some(uid);
    }

    for key in ["PKEXEC_UID", "SUDO_UID"] {
        if let Some(uid) = std::env::var(key)
            .ok()
            .and_then(|raw| raw.trim().parse::<u32>().ok())
            .filter(|uid| *uid != 0)
        {
            return Some(uid);
        }
    }

    None
}

pub fn run(root: &str) -> i32 {
    let paths = Paths::new(root);

    if !net::is_privileged() {
        return fail(&paths, "the helper was not started with elevated rights");
    }

    let raw = match fs::read_to_string(paths.request()) {
        Ok(value) => value,
        Err(error) => return fail(&paths, &format!("no tunnel request to act on: {error}")),
    };

    let settings: TunnelSettings = match serde_json::from_str(&raw) {
        Ok(value) => value,
        Err(error) => return fail(&paths, &format!("the tunnel request is malformed: {error}")),
    };

    let _ = fs::remove_file(paths.stop());
    let _ = fs::remove_file(paths.error());
    let _ = fs::remove_file(paths.ready());

    let log_path = paths.log();
    let _ = fs::write(&log_path, b"");

    let device = TunnelDevice::new();
    if let Err(error) = device.start(settings.hev_config(log_path.to_str())) {
        return fail(&paths, &format!("the tunnel device did not start: {error}"));
    }

    if !net::wait_for_interface(&settings.tunnel_interface) {
        device.stop();
        return fail(
            &paths,
            &format!("the {} interface never appeared", settings.tunnel_interface),
        );
    }

    let bypass_uid = match invoking_uid(settings.bypass_uid) {
        Some(uid) => uid,
        None => {
            device.stop();
            return fail(
                &paths,
                "the account that asked for tunnel mode could not be identified, \
                 refusing to route the engine into a loop",
            );
        }
    };
    println!("[+] traffic from uid {bypass_uid} stays outside the tunnel");

    let dual = settings.dual_stack();
    let edge = crate::settings::edge_ip(&settings.edge_endpoint);
    match edge {
        Some(address) => println!("[+] {address} stays outside the tunnel so the engine can reach it"),
        None => println!("[!] no edge address was supplied; falling back to a uid bypass"),
    }

    let outcome = net::apply_tunnel_routes(&settings.tunnel_interface, bypass_uid, dual, edge);

    for entry in &outcome.applied {
        println!("[+] {entry}");
    }
    for entry in &outcome.failures {
        println!("[-] {entry}");
    }

    if !outcome.bypass_ready {
        net::revert_tunnel_routes_with_edge(dual, edge);
        device.stop();
        return fail(
            &paths,
            "the engine bypass rule could not be installed, refusing to route traffic into a loop",
        );
    }

    if !net::tunnel_default_installed() {
        net::revert_tunnel_routes_with_edge(dual, edge);
        device.stop();
        return fail(
            &paths,
            &format!(
                "the default route never moved onto {}",
                settings.tunnel_interface
            ),
        );
    }

    let mut resolver = DnsOverride::new();
    if settings.override_dns {
        match resolver.apply(&settings.dns_servers()) {
            Ok(list) => println!("[+] resolver redirected through the tunnel: {list}"),
            Err(error) => println!("[!] could not redirect the resolver: {error}"),
        }
    }

    let _ = fs::write(paths.ready(), b"1");
    println!("[+] tunnel mode is live, waiting for a stop request");

    let stop = paths.stop();
    let stats = paths.stats();
    while !stop.exists() {
        let counters = device.counters();
        let _ = fs::write(
            &stats,
            format!(
                "{} {} {} {}",
                counters.tx_packets, counters.tx_bytes, counters.rx_packets, counters.rx_bytes
            ),
        );

        if !device.is_running() {
            break;
        }

        thread::sleep(POLL_INTERVAL);
    }

    if resolver.is_active() {
        resolver.restore();
        println!("[-] resolver restored");
    }

    net::revert_tunnel_routes_with_edge(dual, edge);
    device.stop();

    let _ = fs::remove_file(paths.ready());
    let _ = fs::remove_file(&stats);
    let _ = fs::remove_file(&stop);
    println!("[-] tunnel mode stopped and routes restored");

    0
}

#[cfg(test)]
mod tests {
    use super::*;

    fn clear_env() {
        std::env::remove_var("PKEXEC_UID");
        std::env::remove_var("SUDO_UID");
    }

    #[test]
    fn a_uid_named_in_the_request_is_used_as_is() {
        let _guard = crate::testenv::lock();
        clear_env();
        assert_eq!(invoking_uid(Some(1000)), Some(1000));
    }

    #[test]
    fn pkexec_tells_the_helper_who_asked() {
        let _guard = crate::testenv::lock();
        clear_env();
        std::env::set_var("PKEXEC_UID", "1000");
        assert_eq!(invoking_uid(None), Some(1000));
        clear_env();
    }

    #[test]
    fn sudo_is_accepted_when_pkexec_is_absent() {
        let _guard = crate::testenv::lock();
        clear_env();
        std::env::set_var("SUDO_UID", "1001");
        assert_eq!(invoking_uid(None), Some(1001));
        clear_env();
    }

    #[test]
    fn root_is_never_taken_as_the_account_to_bypass() {
        let _guard = crate::testenv::lock();
        clear_env();
        std::env::set_var("PKEXEC_UID", "0");
        assert_eq!(
            invoking_uid(Some(0)),
            None,
            "bypassing root would leave the engine inside the tunnel"
        );
        clear_env();
    }

    #[test]
    fn an_unknown_account_is_reported_rather_than_guessed() {
        let _guard = crate::testenv::lock();
        clear_env();
        assert_eq!(invoking_uid(None), None);
    }

    #[test]
    fn nonsense_in_the_environment_is_ignored() {
        let _guard = crate::testenv::lock();
        clear_env();
        std::env::set_var("PKEXEC_UID", "not-a-uid");
        assert_eq!(invoking_uid(None), None);
        clear_env();
    }

    #[test]
    fn the_state_files_all_live_under_the_directory_given() {
        let paths = Paths::new("/tmp/oblivion-state");
        for path in [
            paths.request(),
            paths.stop(),
            paths.ready(),
            paths.stats(),
            paths.error(),
            paths.log(),
        ] {
            assert!(path.starts_with("/tmp/oblivion-state"), "{path:?}");
        }
    }

    #[test]
    fn stats_are_read_back_in_the_order_the_helper_writes_them() {
        let dir = std::env::temp_dir().join("oblivion-stats-test");
        std::fs::create_dir_all(&dir).unwrap();
        let file = dir.join("stats");
        std::fs::write(&file, "1 2 3 4").unwrap();

        assert_eq!(read_stats(&file), Some((1, 2, 3, 4)));

        std::fs::write(&file, "garbage").unwrap();
        assert_eq!(read_stats(&file), None);

        let _ = std::fs::remove_dir_all(&dir);
    }
}
