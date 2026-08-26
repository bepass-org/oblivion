use std::net::IpAddr;
use std::process::Command;
use std::thread;
use std::time::{Duration, Instant};

use super::{DefaultRoute, RouteOutcome};

const INTERFACE_TIMEOUT: Duration = Duration::from_secs(15);
const TUNNEL_METRIC: &str = "1";

fn powershell(script: &str) -> Option<String> {
    let output = Command::new("powershell")
        .args([
            "-NoProfile",
            "-NonInteractive",
            "-ExecutionPolicy",
            "Bypass",
            "-Command",
            script,
        ])
        .output()
        .ok()?;

    if !output.status.success() {
        return None;
    }
    Some(String::from_utf8_lossy(&output.stdout).trim().to_string())
}

fn run(script: &str, label: &str, outcome: &mut RouteOutcome) {
    let output = Command::new("powershell")
        .args([
            "-NoProfile",
            "-NonInteractive",
            "-ExecutionPolicy",
            "Bypass",
            "-Command",
            script,
        ])
        .output();

    match output {
        Ok(done) if done.status.success() => outcome.applied.push(label.to_string()),
        Ok(done) => {
            let detail = String::from_utf8_lossy(&done.stderr);
            let detail = detail.trim();
            let detail = detail.lines().next().unwrap_or("no detail");
            outcome.failures.push(format!("{label}: {detail}"));
        }
        Err(error) => outcome.failures.push(format!("{label}: {error}")),
    }
}

fn run_quiet(script: &str) {
    let _ = Command::new("powershell")
        .args([
            "-NoProfile",
            "-NonInteractive",
            "-ExecutionPolicy",
            "Bypass",
            "-Command",
            script,
        ])
        .output();
}

fn family(ipv6: bool) -> &'static str {
    if ipv6 {
        "IPv6"
    } else {
        "IPv4"
    }
}

fn halves(ipv6: bool) -> [&'static str; 2] {
    if ipv6 {
        ["::/1", "8000::/1"]
    } else {
        ["0.0.0.0/1", "128.0.0.0/1"]
    }
}

pub fn parse_default_route(raw: &str) -> Option<DefaultRoute> {
    let line = raw.lines().map(str::trim).find(|line| !line.is_empty())?;
    let mut fields = line.split_whitespace();
    let gateway = fields.next()?.to_string();
    let device = fields.next()?.to_string();

    let unspecified = gateway == "0.0.0.0" || gateway == "::" || gateway.is_empty();

    Some(DefaultRoute {
        gateway: if unspecified { None } else { Some(gateway) },
        device,
    })
}

pub fn default_route(ipv6: bool) -> Option<DefaultRoute> {
    let prefix = if ipv6 { "::/0" } else { "0.0.0.0/0" };
    let script = format!(
        "Get-NetRoute -AddressFamily {} -DestinationPrefix '{}' -ErrorAction SilentlyContinue | \
         Sort-Object RouteMetric | Select-Object -First 1 | \
         ForEach-Object {{ \"$($_.NextHop) $($_.InterfaceIndex)\" }}",
        family(ipv6),
        prefix
    );

    parse_default_route(&powershell(&script)?)
}

pub fn interface_index(name: &str) -> Option<String> {
    let script = format!(
        "(Get-NetAdapter -Name '{name}' -ErrorAction SilentlyContinue).ifIndex"
    );
    let value = powershell(&script)?;
    if value.is_empty() {
        return None;
    }
    Some(value)
}

pub fn wait_for_interface(name: &str) -> bool {
    let deadline = Instant::now() + INTERFACE_TIMEOUT;
    while Instant::now() < deadline {
        if interface_index(name).is_some() {
            return true;
        }
        thread::sleep(Duration::from_millis(250));
    }
    false
}

fn host_prefix(edge: IpAddr) -> String {
    match edge {
        IpAddr::V4(address) => format!("{address}/32"),
        IpAddr::V6(address) => format!("{address}/128"),
    }
}

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

    let prefix = host_prefix(edge);
    let next_hop = route.gateway.clone().unwrap_or_else(|| {
        if ipv6 {
            "::".to_string()
        } else {
            "0.0.0.0".to_string()
        }
    });

    let script = format!(
        "New-NetRoute -DestinationPrefix '{}' -InterfaceIndex {} -NextHop '{}' \
         -RouteMetric {} -PolicyStore ActiveStore -ErrorAction Stop | Out-Null",
        prefix, route.device, next_hop, TUNNEL_METRIC
    );

    run(&script, &format!("host route for {edge}"), outcome);
    true
}

fn drop_edge_route(edge: IpAddr) {
    let script = format!(
        "Remove-NetRoute -DestinationPrefix '{}' -PolicyStore ActiveStore -Confirm:$false \
         -ErrorAction SilentlyContinue",
        host_prefix(edge)
    );
    run_quiet(&script);
}

pub fn apply_tunnel_routes(
    interface: &str,
    _bypass_uid: u32,
    ipv6: bool,
    edge: Option<IpAddr>,
) -> RouteOutcome {
    let mut outcome = RouteOutcome::new();

    revert_tunnel_routes_with_edge(ipv6, edge);

    let index = match interface_index(interface) {
        Some(index) => index,
        None => {
            outcome
                .failures
                .push(format!("the {interface} adapter is not present"));
            return outcome;
        }
    };

    match edge {
        Some(address) => {
            let before = outcome.failures.len();
            if !pin_edge_route(address, &mut outcome) {
                return outcome;
            }
            outcome.bypass_ready = outcome.failures.len() == before;
        }
        None => {
            outcome.failures.push(
                "no edge address was supplied, so the engine cannot be kept out of the tunnel"
                    .to_string(),
            );
            return outcome;
        }
    }

    if !outcome.bypass_ready {
        return outcome;
    }

    let next_hop = if ipv6 { "::" } else { "0.0.0.0" };
    for half in halves(ipv6) {
        let script = format!(
            "New-NetRoute -DestinationPrefix '{}' -InterfaceIndex {} -NextHop '{}' \
             -RouteMetric {} -PolicyStore ActiveStore -ErrorAction Stop | Out-Null",
            half, index, next_hop, TUNNEL_METRIC
        );
        run(&script, &format!("route {half} onto {interface}"), &mut outcome);
    }

    outcome
}

pub fn tunnel_default_installed() -> bool {
    let script = format!(
        "@(Get-NetRoute -AddressFamily IPv4 -DestinationPrefix '{}' \
         -PolicyStore ActiveStore -ErrorAction SilentlyContinue).Count",
        halves(false)[0]
    );

    powershell(&script)
        .and_then(|value| value.trim().parse::<u32>().ok())
        .map(|count| count > 0)
        .unwrap_or(false)
}

pub fn revert_tunnel_routes_with_edge(ipv6: bool, edge: Option<IpAddr>) {
    if let Some(edge) = edge {
        drop_edge_route(edge);
    }
    revert_tunnel_routes(ipv6);
}

pub fn revert_tunnel_routes(ipv6: bool) {
    let mut families = vec![false];
    if ipv6 {
        families.push(true);
    }

    for family_ipv6 in families {
        for half in halves(family_ipv6) {
            let script = format!(
                "Remove-NetRoute -DestinationPrefix '{half}' -PolicyStore ActiveStore \
                 -Confirm:$false -ErrorAction SilentlyContinue"
            );
            run_quiet(&script);
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn a_gateway_and_index_pair_is_read() {
        let route = parse_default_route("192.168.1.1 12").expect("a default route");
        assert_eq!(route.gateway.as_deref(), Some("192.168.1.1"));
        assert_eq!(route.device, "12");
    }

    #[test]
    fn an_unspecified_next_hop_means_a_point_to_point_link() {
        let route = parse_default_route("0.0.0.0 7").expect("a default route");
        assert_eq!(route.gateway, None);
        assert_eq!(route.device, "7");

        let route = parse_default_route(":: 9").expect("a default route");
        assert_eq!(route.gateway, None);
        assert_eq!(route.device, "9");
    }

    #[test]
    fn blank_lines_before_the_answer_are_skipped() {
        let route = parse_default_route("\n\n  10.0.0.1 5  \n").expect("a default route");
        assert_eq!(route.gateway.as_deref(), Some("10.0.0.1"));
        assert_eq!(route.device, "5");
    }

    #[test]
    fn nothing_usable_gives_nothing() {
        assert!(parse_default_route("").is_none());
        assert!(parse_default_route("192.168.1.1").is_none());
    }

    #[test]
    fn the_default_route_is_split_in_half_rather_than_replaced() {
        assert_eq!(halves(false), ["0.0.0.0/1", "128.0.0.0/1"]);
        assert_eq!(halves(true), ["::/1", "8000::/1"]);
    }

    #[test]
    fn a_host_prefix_covers_a_single_address() {
        assert_eq!(host_prefix("1.2.3.4".parse().unwrap()), "1.2.3.4/32");
        assert_eq!(host_prefix("2606:4700::1".parse().unwrap()), "2606:4700::1/128");
    }
}
