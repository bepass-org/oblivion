use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Deserialize, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct TunnelSettings {
    #[serde(default = "default_core")]
    pub core: String,
    #[serde(default)]
    pub psiphon_country: String,
    #[serde(default = "default_psiphon_mode")]
    pub psiphon_mode: String,
    #[serde(default)]
    pub psiphon_cdn_ips: String,
    #[serde(default)]
    pub psiphon_cdn_sni: String,
    #[serde(default = "default_conduit_peers")]
    pub psiphon_conduit_peers: String,
    #[serde(default = "default_true")]
    pub psiphon_reject_censored_peers: bool,
    #[serde(default = "default_protocol")]
    pub protocol: String,
    #[serde(default = "default_transport")]
    pub transport: String,
    #[serde(default = "default_scan_mode")]
    pub scan_mode: String,
    #[serde(default = "default_obfuscation")]
    pub obfuscation: String,
    #[serde(default = "default_ip_version")]
    pub ip_version: String,
    #[serde(default = "default_log_level")]
    pub log_level: String,
    #[serde(default)]
    pub perf_profile: String,
    #[serde(default)]
    pub endpoint: String,
    #[serde(default)]
    pub wiw_outer: String,
    #[serde(default)]
    pub wiw_inner: String,
    #[serde(default = "default_socks_port")]
    pub socks_port: u16,
    #[serde(default)]
    pub allow_lan: bool,
    #[serde(default)]
    pub proxy_only: bool,
    #[serde(default)]
    pub system_proxy: bool,
    #[serde(default)]
    pub data_dir: String,
    #[serde(default)]
    pub noize_profile: String,
    #[serde(default)]
    pub fragment: bool,
    #[serde(default = "default_true")]
    pub quick_reconnect: bool,
    #[serde(default = "default_true")]
    pub fast_first_connect: bool,
    #[serde(default = "default_tunnel_interface")]
    pub tunnel_interface: String,
    #[serde(default = "default_mtu")]
    pub tunnel_mtu: u16,
    #[serde(default)]
    pub bypass_uid: Option<u32>,
    #[serde(default)]
    pub edge_endpoint: String,
    #[serde(default = "default_true")]
    pub override_dns: bool,
    #[serde(default)]
    pub dns_primary: String,
    #[serde(default)]
    pub dns_secondary: String,
    #[serde(default)]
    pub route_block: String,
    #[serde(default)]
    pub route_direct: String,
    #[serde(default)]
    pub team: String,
    #[serde(default)]
    pub access_token: String,
    #[serde(default)]
    pub access_id: String,
    #[serde(default)]
    pub access_secret: String,
    #[serde(default)]
    pub gateway_proxy: bool,
}

fn default_tunnel_interface() -> String {
    "oblivion0".to_string()
}

fn default_mtu() -> u16 {
    8500
}

fn default_core() -> String {
    crate::psiphon::CORE_AETHER.to_string()
}

fn default_psiphon_mode() -> String {
    crate::psiphon::MODE_AUTO.to_string()
}

fn default_conduit_peers() -> String {
    crate::psiphon::CONDUIT_PEERS_AUTO.to_string()
}

fn default_protocol() -> String {
    "masque".to_string()
}

fn default_transport() -> String {
    "h3".to_string()
}

fn default_scan_mode() -> String {
    "balanced".to_string()
}

fn default_obfuscation() -> String {
    "balanced".to_string()
}

fn default_ip_version() -> String {
    "v4".to_string()
}

fn default_log_level() -> String {
    "info".to_string()
}

fn default_socks_port() -> u16 {
    1819
}

fn default_true() -> bool {
    true
}

#[derive(Debug, Clone, Deserialize)]
pub struct ConnectRequest {
    pub settings: TunnelSettings,
    #[serde(default)]
    pub arguments: Vec<String>,
}

impl TunnelSettings {
    pub fn uses_chain(&self) -> bool {
        self.core.trim().eq_ignore_ascii_case(crate::psiphon::CORE_CHAIN)
    }

    pub fn psiphon_only(&self) -> bool {
        self.core.trim().eq_ignore_ascii_case(crate::psiphon::CORE_PSIPHON)
    }

    pub fn runs_aether(&self) -> bool {
        !self.psiphon_only()
    }

    pub fn runs_psiphon(&self) -> bool {
        self.psiphon_only() || self.uses_chain()
    }

    pub fn core_name(&self) -> &'static str {
        if self.psiphon_only() {
            crate::psiphon::CORE_PSIPHON
        } else {
            crate::psiphon::CORE_AETHER
        }
    }

    pub fn aether_socks_port(&self) -> u16 {
        if !self.uses_chain() {
            return self.socks_port;
        }
        match self.socks_port.checked_add(11) {
            Some(_) => self.socks_port + 10,
            None => self.socks_port.saturating_sub(10),
        }
    }

    pub fn aether_http_port(&self) -> u16 {
        self.aether_socks_port().saturating_add(1)
    }

    fn aether_bind_host(&self) -> &'static str {
        if self.allow_lan && !self.uses_chain() {
            "0.0.0.0"
        } else {
            "127.0.0.1"
        }
    }

    pub fn aether_bind_address(&self) -> String {
        format!("{}:{}", self.aether_bind_host(), self.aether_socks_port())
    }

    pub fn aether_http_address(&self) -> String {
        format!("{}:{}", self.aether_bind_host(), self.aether_http_port())
    }

    pub fn chain_upstream_url(&self) -> String {
        format!("socks5://127.0.0.1:{}", self.aether_socks_port())
    }

    pub fn uses_gool(&self) -> bool {
        self.protocol.trim().eq_ignore_ascii_case("gool")
    }

    pub fn wiw_outer_peer(&self) -> &str {
        if self.uses_gool() { self.wiw_outer.trim() } else { "" }
    }

    pub fn wiw_inner_peer(&self) -> &str {
        if self.uses_gool() { self.wiw_inner.trim() } else { "" }
    }

    pub fn wiw_pinned(&self) -> bool {
        !self.wiw_outer_peer().is_empty() || !self.wiw_inner_peer().is_empty()
    }

    pub fn bind_host(&self) -> &'static str {
        if self.allow_lan {
            "0.0.0.0"
        } else {
            "127.0.0.1"
        }
    }

    pub fn bind_address(&self) -> String {
        format!("{}:{}", self.bind_host(), self.socks_port)
    }

    pub fn http_proxy_port(&self) -> u16 {
        self.socks_port.saturating_add(1)
    }

    pub fn http_proxy_address(&self) -> String {
        format!("{}:{}", self.bind_host(), self.http_proxy_port())
    }

    pub fn noize(&self) -> String {
        let mapped = self.noize_profile.trim();
        if !mapped.is_empty() {
            return mapped.to_string();
        }
        self.obfuscation.clone()
    }

    pub fn identity_path(&self) -> Option<String> {
        let base = self.data_dir.trim();
        if base.is_empty() {
            return None;
        }
        let separator = if base.ends_with(std::path::MAIN_SEPARATOR) {
            ""
        } else {
            std::path::MAIN_SEPARATOR_STR
        };
        Some(format!("{base}{separator}aether.toml"))
    }

    pub fn core_environment(&self) -> Vec<(String, String)> {
        let mut env = vec![
            ("AETHER_SOCKS".to_string(), self.aether_bind_address()),
            ("AETHER_HTTP_PROXY".to_string(), self.aether_http_address()),
            ("AETHER_PROTOCOL".to_string(), self.protocol.clone()),
            ("AETHER_SCAN".to_string(), self.scan_mode.clone()),
            ("AETHER_NOIZE".to_string(), self.noize()),
            ("AETHER_IP".to_string(), self.ip_version.clone()),
            ("AETHER_LOG_LEVEL".to_string(), self.log_level.clone()),
            (
                "AETHER_QUICK_RECONNECT".to_string(),
                if self.quick_reconnect { "1" } else { "0" }.to_string(),
            ),
        ];

        if let Some(path) = self.identity_path() {
            env.push(("AETHER_CONFIG".to_string(), path));
        }

        if self.override_dns {
            env.push(("AETHER_DNS".to_string(), self.dns_servers().join(",")));
        }

        if self.protocol == "masque" && self.transport == "h2" {
            env.push(("AETHER_MASQUE_HTTP2".to_string(), "1".to_string()));
            if self.fragment {
                env.push(("AETHER_MASQUE_H2_FRAGMENT".to_string(), "1".to_string()));
            }
        }

        if self.uses_gool() {
            let outer = self.wiw_outer_peer();
            if !outer.is_empty() {
                env.push(("AETHER_WIW_OUTER_PEER".to_string(), outer.to_string()));
            }
            let inner = self.wiw_inner_peer();
            if !inner.is_empty() {
                env.push(("AETHER_WIW_INNER_PEER".to_string(), inner.to_string()));
            }
            if !self.wiw_pinned() {
                env.push(("AETHER_WIW_PEERS".to_string(), "auto".to_string()));
            }
        } else if !self.endpoint.trim().is_empty() {
            env.push(("AETHER_PEER".to_string(), self.endpoint.trim().to_string()));
        }
        if !self.perf_profile.trim().is_empty() {
            env.push((
                "AETHER_PERF_PROFILE".to_string(),
                self.perf_profile.clone(),
            ));
        }

        let blocked = route_rules(&self.route_block);
        if !blocked.is_empty() {
            env.push(("AETHER_ROUTE_BLOCK".to_string(), blocked.join(",")));
        }
        let direct = route_rules(&self.route_direct);
        if !direct.is_empty() {
            env.push(("AETHER_ROUTE_DIRECT".to_string(), direct.join(",")));
        }

        let team = self.team.trim();
        if !team.is_empty() {
            env.push(("AETHER_TEAM".to_string(), team.to_string()));

            let token = self.access_token.trim();
            let id = self.access_id.trim();
            let secret = self.access_secret.trim();

            if !token.is_empty() {
                env.push(("AETHER_ACCESS_TOKEN".to_string(), token.to_string()));
            } else if !id.is_empty() && !secret.is_empty() {
                env.push(("AETHER_ACCESS_CLIENT_ID".to_string(), id.to_string()));
                env.push((
                    "AETHER_ACCESS_CLIENT_SECRET".to_string(),
                    secret.to_string(),
                ));
            }

            if self.gateway_proxy {
                env.push(("AETHER_GATEWAY".to_string(), "1".to_string()));
            }
        }

        env
    }

    pub fn dns_servers(&self) -> Vec<String> {
        let mut servers = Vec::new();
        for candidate in [&self.dns_primary, &self.dns_secondary] {
            let value = candidate.trim();
            if !value.is_empty() && !servers.iter().any(|entry| entry == value) {
                servers.push(value.to_string());
            }
        }
        if servers.is_empty() {
            servers.push("1.1.1.1".to_string());
            servers.push("1.0.0.1".to_string());
        }
        servers
    }

    pub fn tunnel_mode(&self) -> bool {
        !self.proxy_only
    }

    pub fn system_proxy_mode(&self) -> bool {
        self.proxy_only && self.system_proxy
    }

    pub fn manual_gateway(&self) -> Option<String> {
        let value = self.endpoint.trim();
        if value.is_empty() {
            None
        } else {
            Some(value.to_string())
        }
    }

    pub fn log_directory(&self) -> std::path::PathBuf {
        let base = self.data_dir.trim();
        if base.is_empty() {
            std::env::temp_dir()
        } else {
            std::path::PathBuf::from(base)
        }
    }

    pub fn dual_stack(&self) -> bool {
        self.ip_version == "dual" || self.ip_version == "v6"
    }

    pub fn hev_log_level(&self) -> &'static str {
        match self.log_level.as_str() {
            "trace" | "debug" => "debug",
            "info" => "info",
            _ => "error",
        }
    }

    pub fn hev_config(&self, log_path: Option<&str>) -> String {
        let mut config = String::new();
        config.push_str("tunnel:\n");
        config.push_str(&format!("  name: '{}'\n", self.tunnel_interface));
        config.push_str(&format!("  mtu: {}\n", self.tunnel_mtu));
        config.push_str("  ipv4: '198.18.0.1'\n");
        if self.dual_stack() {
            config.push_str("  ipv6: 'fc00::1'\n");
        }
        config.push_str("socks5:\n");
        config.push_str(&format!("  port: {}\n", self.socks_port));
        config.push_str("  address: '127.0.0.1'\n");
        config.push_str("  udp: 'udp'\n");
        config.push_str("misc:\n");
        config.push_str(&format!("  log-level: '{}'\n", self.hev_log_level()));
        if let Some(path) = log_path {
            config.push_str(&format!("  log-file: '{path}'\n"));
        }
        config.push_str("  limit-nofile: 65535\n");
        config
    }
}

fn route_rules(raw: &str) -> Vec<String> {
    raw.split(['\n', ',', ';'])
        .map(|entry| entry.trim())
        .filter(|entry| !entry.is_empty() && !entry.starts_with('#'))
        .map(|entry| entry.to_string())
        .collect()
}

#[cfg(test)]
mod tests {
    use super::*;

    fn settings_from(json: &str) -> TunnelSettings {
        serde_json::from_str(json).expect("settings should parse")
    }

    #[test]
    fn routing_rules_are_absent_from_the_environment_when_unset() {
        let settings = settings_from("{}");
        let env = settings.core_environment();
        assert!(!env.iter().any(|(key, _)| key == "AETHER_ROUTE_BLOCK"));
        assert!(!env.iter().any(|(key, _)| key == "AETHER_ROUTE_DIRECT"));
    }

    #[test]
    fn routing_rules_reach_the_core_environment() {
        let settings = settings_from(
            r#"{"routeBlock":"ads.example.com,keyword:tracker","routeDirect":"private"}"#,
        );
        let env = settings.core_environment();

        let blocked = env
            .iter()
            .find(|(key, _)| key == "AETHER_ROUTE_BLOCK")
            .map(|(_, value)| value.as_str());
        assert_eq!(blocked, Some("ads.example.com,keyword:tracker"));

        let direct = env
            .iter()
            .find(|(key, _)| key == "AETHER_ROUTE_DIRECT")
            .map(|(_, value)| value.as_str());
        assert_eq!(direct, Some("private"));
    }

    #[test]
    fn rule_lists_drop_blanks_and_comments() {
        assert_eq!(
            route_rules("a.com\n\n  # a note\n b.com ;c.com"),
            vec!["a.com", "b.com", "c.com"]
        );
    }

    #[test]
    fn newlines_from_the_editor_become_a_comma_list() {
        let settings =
            settings_from(r#"{"routeBlock":"one.example\ntwo.example\nthree.example"}"#);
        let env = settings.core_environment();
        let blocked = env
            .iter()
            .find(|(key, _)| key == "AETHER_ROUTE_BLOCK")
            .map(|(_, value)| value.as_str());
        assert_eq!(blocked, Some("one.example,two.example,three.example"));
    }
}

#[cfg(test)]
mod zero_trust_tests {
    use super::*;

    fn settings_from(json: &str) -> TunnelSettings {
        serde_json::from_str(json).expect("settings should parse")
    }

    fn value_of<'a>(env: &'a [(String, String)], key: &str) -> Option<&'a str> {
        env.iter()
            .find(|(name, _)| name == key)
            .map(|(_, value)| value.as_str())
    }

    #[test]
    fn no_team_means_no_zero_trust_variables() {
        let env = settings_from("{}").core_environment();
        for key in [
            "AETHER_TEAM",
            "AETHER_ACCESS_TOKEN",
            "AETHER_ACCESS_CLIENT_ID",
            "AETHER_ACCESS_CLIENT_SECRET",
            "AETHER_GATEWAY",
        ] {
            assert!(value_of(&env, key).is_none(), "{key} should be absent");
        }
    }

    #[test]
    fn an_access_token_is_forwarded_with_the_team() {
        let env = settings_from(r#"{"team":"example","accessToken":"a.b.c"}"#)
            .core_environment();
        assert_eq!(value_of(&env, "AETHER_TEAM"), Some("example"));
        assert_eq!(value_of(&env, "AETHER_ACCESS_TOKEN"), Some("a.b.c"));
    }

    #[test]
    fn a_service_token_is_forwarded_when_there_is_no_jwt() {
        let env =
            settings_from(r#"{"team":"example","accessId":"id","accessSecret":"secret"}"#)
                .core_environment();
        assert_eq!(value_of(&env, "AETHER_ACCESS_CLIENT_ID"), Some("id"));
        assert_eq!(value_of(&env, "AETHER_ACCESS_CLIENT_SECRET"), Some("secret"));
    }

    #[test]
    fn a_jwt_wins_over_a_service_token() {
        let env = settings_from(
            r#"{"team":"example","accessToken":"a.b.c","accessId":"id","accessSecret":"s"}"#,
        )
        .core_environment();
        assert_eq!(value_of(&env, "AETHER_ACCESS_TOKEN"), Some("a.b.c"));
        assert!(value_of(&env, "AETHER_ACCESS_CLIENT_ID").is_none());
    }

    #[test]
    fn a_half_filled_service_token_is_ignored() {
        let env = settings_from(r#"{"team":"example","accessId":"id"}"#).core_environment();
        assert!(value_of(&env, "AETHER_ACCESS_CLIENT_ID").is_none());
        assert!(value_of(&env, "AETHER_ACCESS_CLIENT_SECRET").is_none());
    }

    #[test]
    fn the_gateway_proxy_stays_off_unless_asked_for() {
        let off = settings_from(r#"{"team":"example"}"#).core_environment();
        assert!(value_of(&off, "AETHER_GATEWAY").is_none());

        let on = settings_from(r#"{"team":"example","gatewayProxy":true}"#).core_environment();
        assert_eq!(value_of(&on, "AETHER_GATEWAY"), Some("1"));
    }

    #[test]
    fn the_gateway_proxy_needs_a_team_to_apply() {
        let env = settings_from(r#"{"gatewayProxy":true}"#).core_environment();
        assert!(value_of(&env, "AETHER_GATEWAY").is_none());
    }
}

#[cfg(test)]
mod chain_tests {
    use super::*;

    fn settings_from(json: &str) -> TunnelSettings {
        serde_json::from_str(json).expect("settings should parse")
    }

    fn value_of<'a>(env: &'a [(String, String)], key: &str) -> Option<&'a str> {
        env.iter()
            .find(|(name, _)| name == key)
            .map(|(_, value)| value.as_str())
    }

    #[test]
    fn a_plain_aether_run_keeps_the_public_ports() {
        let settings = settings_from("{}");
        assert!(!settings.uses_chain());
        assert_eq!(settings.aether_socks_port(), settings.socks_port);
        assert_eq!(settings.aether_bind_address(), settings.bind_address());
    }

    #[test]
    fn chaining_moves_aether_aside_so_psiphon_holds_the_public_port() {
        let settings = settings_from(r#"{"core":"chain","socksPort":1819}"#);
        assert_eq!(settings.socks_port, 1819);
        assert_eq!(settings.aether_socks_port(), 1829);
        assert_eq!(settings.aether_http_port(), 1830);
        assert_eq!(settings.http_proxy_port(), 1820);
    }

    #[test]
    fn the_core_is_told_to_listen_on_the_inner_port() {
        let env = settings_from(r#"{"core":"chain","socksPort":1819}"#).core_environment();
        assert_eq!(value_of(&env, "AETHER_SOCKS"), Some("127.0.0.1:1829"));
        assert_eq!(value_of(&env, "AETHER_HTTP_PROXY"), Some("127.0.0.1:1830"));
    }

    #[test]
    fn a_chained_inner_port_stays_on_loopback_even_when_lan_is_allowed() {
        let settings = settings_from(r#"{"core":"chain","allowLan":true}"#);
        assert!(settings.aether_bind_address().starts_with("127.0.0.1:"));
        assert!(settings.bind_address().starts_with("0.0.0.0:"));
    }

    #[test]
    fn a_socks_port_near_the_ceiling_shifts_downwards_instead_of_overflowing() {
        let settings = settings_from(r#"{"core":"chain","socksPort":65530}"#);
        assert_eq!(settings.aether_socks_port(), 65520);
        assert_eq!(settings.aether_http_port(), 65521);
    }

    #[test]
    fn psiphon_is_pointed_at_the_port_aether_listens_on() {
        let settings = settings_from(r#"{"core":"chain","socksPort":1819}"#);
        assert_eq!(settings.chain_upstream_url(), "socks5://127.0.0.1:1829");
    }

    #[test]
    fn a_chain_runs_both_cores_and_leads_with_aether() {
        let settings = settings_from(r#"{"core":"chain"}"#);
        assert!(settings.runs_aether());
        assert!(settings.runs_psiphon());
        assert!(!settings.psiphon_only());
        assert_eq!(settings.core_name(), crate::psiphon::CORE_AETHER);
    }

    #[test]
    fn psiphon_on_its_own_runs_no_aether() {
        let settings = settings_from(r#"{"core":"psiphon"}"#);
        assert!(!settings.runs_aether());
        assert!(settings.runs_psiphon());
        assert!(settings.psiphon_only());
    }

    #[test]
    fn aether_on_its_own_runs_no_psiphon() {
        let settings = settings_from(r#"{"core":"aether"}"#);
        assert!(settings.runs_aether());
        assert!(!settings.runs_psiphon());
    }
}

#[cfg(test)]
mod warp_in_warp_tests {
    use super::*;

    fn settings_from(json: &str) -> TunnelSettings {
        serde_json::from_str(json).expect("settings should parse")
    }

    fn value_of<'a>(env: &'a [(String, String)], key: &str) -> Option<&'a str> {
        env.iter()
            .find(|(name, _)| name == key)
            .map(|(_, value)| value.as_str())
    }

    #[test]
    fn both_hops_reach_the_core_when_they_are_named_by_hand() {
        let env = settings_from(
            r#"{"protocol":"gool","wiwOuter":"162.159.192.1:2408","wiwInner":"188.114.96.1:894"}"#,
        )
        .core_environment();

        assert_eq!(
            value_of(&env, "AETHER_WIW_OUTER_PEER"),
            Some("162.159.192.1:2408")
        );
        assert_eq!(
            value_of(&env, "AETHER_WIW_INNER_PEER"),
            Some("188.114.96.1:894")
        );
        assert!(value_of(&env, "AETHER_WIW_PEERS").is_none());
    }

    #[test]
    fn naming_one_hop_leaves_the_other_to_the_scan() {
        let env =
            settings_from(r#"{"protocol":"gool","wiwOuter":"162.159.192.1:2408"}"#)
                .core_environment();

        assert_eq!(
            value_of(&env, "AETHER_WIW_OUTER_PEER"),
            Some("162.159.192.1:2408")
        );
        assert!(value_of(&env, "AETHER_WIW_INNER_PEER").is_none());
        assert!(value_of(&env, "AETHER_WIW_PEERS").is_none());
    }

    #[test]
    fn naming_neither_hop_asks_the_core_to_scan_for_both() {
        let env = settings_from(r#"{"protocol":"gool"}"#).core_environment();
        assert_eq!(value_of(&env, "AETHER_WIW_PEERS"), Some("auto"));
    }

    #[test]
    fn the_masque_endpoint_never_becomes_a_gool_hop() {
        let env = settings_from(r#"{"protocol":"gool","endpoint":"162.159.198.1:443"}"#)
            .core_environment();

        assert!(
            value_of(&env, "AETHER_PEER").is_none(),
            "AETHER_PEER doubles as the outer hop, so it must not survive into gool"
        );
        assert_eq!(value_of(&env, "AETHER_WIW_PEERS"), Some("auto"));
    }

    #[test]
    fn hops_set_on_another_protocol_are_ignored() {
        let env = settings_from(
            r#"{"protocol":"masque","endpoint":"162.159.198.1:443","wiwOuter":"162.159.192.1:2408"}"#,
        )
        .core_environment();

        assert!(value_of(&env, "AETHER_WIW_OUTER_PEER").is_none());
        assert_eq!(value_of(&env, "AETHER_PEER"), Some("162.159.198.1:443"));
    }

    #[test]
    fn surrounding_whitespace_is_trimmed_off_a_hop() {
        let settings =
            settings_from(r#"{"protocol":"gool","wiwInner":"  188.114.96.1:894  "}"#);
        assert_eq!(settings.wiw_inner_peer(), "188.114.96.1:894");
        assert!(settings.wiw_pinned());
    }
}

pub fn edge_ip(raw: &str) -> Option<std::net::IpAddr> {
    let trimmed = raw.trim();
    if trimmed.is_empty() {
        return None;
    }

    if let Ok(address) = trimmed.parse::<std::net::SocketAddr>() {
        return Some(address.ip());
    }
    if let Ok(ip) = trimmed.parse::<std::net::IpAddr>() {
        return Some(ip);
    }

    if let Some(rest) = trimmed.strip_prefix('[') {
        if let Some((host, _)) = rest.split_once(']') {
            return host.parse::<std::net::IpAddr>().ok();
        }
    }

    if let Some((host, _)) = trimmed.rsplit_once(':') {
        if let Ok(ip) = host.parse::<std::net::IpAddr>() {
            return Some(ip);
        }
    }

    None
}

#[cfg(test)]
mod edge_tests {
    use super::edge_ip;

    #[test]
    fn an_endpoint_with_a_port_gives_up_its_address() {
        assert_eq!(
            edge_ip("162.159.195.1:2408").map(|ip| ip.to_string()),
            Some("162.159.195.1".to_string())
        );
    }

    #[test]
    fn a_bare_address_is_accepted() {
        assert_eq!(
            edge_ip("162.159.195.1").map(|ip| ip.to_string()),
            Some("162.159.195.1".to_string())
        );
    }

    #[test]
    fn a_bracketed_ipv6_endpoint_is_read() {
        assert_eq!(
            edge_ip("[2606:4700:d0::a29f:c001]:2408").map(|ip| ip.to_string()),
            Some("2606:4700:d0::a29f:c001".to_string())
        );
    }

    #[test]
    fn a_bare_ipv6_address_is_accepted() {
        assert_eq!(
            edge_ip("2606:4700:d0::a29f:c001").map(|ip| ip.to_string()),
            Some("2606:4700:d0::a29f:c001".to_string())
        );
    }

    #[test]
    fn nothing_usable_gives_nothing() {
        for raw in ["", "   ", "not-an-address", "example.com:443"] {
            assert_eq!(edge_ip(raw), None, "{raw}");
        }
    }
}
