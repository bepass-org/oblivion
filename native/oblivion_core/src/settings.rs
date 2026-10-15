use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Deserialize, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct TunnelSettings {
    #[serde(default = "default_core")]
    pub core: String,
    #[serde(default)]
    pub psiphon: String,
    #[serde(default)]
    pub tor: String,
    #[serde(default)]
    pub psiphon_country: String,
    #[serde(default = "default_psiphon_mode")]
    pub psiphon_mode: String,
    #[serde(default)]
    pub psiphon_cdn_ips: String,
    #[serde(default)]
    pub psiphon_cdn_sni: String,
    #[serde(default)]
    pub psiphon_cdn_sets: String,
    #[serde(default)]
    pub psiphon_server_entries: String,
    #[serde(default = "default_conduit_peers")]
    pub psiphon_conduit_peers: String,
    #[serde(default = "default_true")]
    pub psiphon_reject_censored_peers: bool,
    #[serde(default = "default_tor_relays")]
    pub tor_relays: String,
    #[serde(default)]
    pub tor_bridges: String,
    #[serde(default)]
    pub exit_loc: String,
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
    pub core_mtu: u16,
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
    1500
}

pub const NOIZE_AUTO: &str = "auto";

const TUN_MTU_MIN: u16 = 1280;
const TUN_MTU_MAX: u16 = 9000;
const CORE_MTU_MIN: u16 = 576;
const CORE_MTU_MAX: u16 = 1500;

fn default_core() -> String {
    crate::psiphon::CORE_AETHER.to_string()
}

fn legacy_places(core: &str) -> (&'static str, &'static str) {
    match core.trim().to_ascii_lowercase().as_str() {
        "psiphon" => ("only", "off"),
        "chain" => ("chain", "off"),
        "psiphon-reverse" => ("reverse", "off"),
        "tor" => ("off", "only"),
        "tor-chain" => ("off", "chain"),
        "tor-reverse" => ("off", "reverse"),
        _ => ("off", "off"),
    }
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

fn default_tor_relays() -> String {
    "auto".to_string()
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
    "both".to_string()
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
    fn psiphon_place(&self) -> &str {
        match self.psiphon.trim() {
            "" => legacy_places(&self.core).0,
            chosen => chosen,
        }
    }

    fn tor_place(&self) -> &str {
        match self.tor.trim() {
            "" => legacy_places(&self.core).1,
            chosen => chosen,
        }
    }

    pub fn uses_chain(&self) -> bool {
        self.psiphon_place().eq_ignore_ascii_case("chain")
    }

    pub fn psiphon_only(&self) -> bool {
        self.psiphon_place().eq_ignore_ascii_case("only")
    }

    pub fn psiphon_reverse(&self) -> bool {
        self.psiphon_place().eq_ignore_ascii_case("reverse")
    }

    pub fn tor_only(&self) -> bool {
        self.tor_place().eq_ignore_ascii_case("only")
    }

    pub fn tor_chain(&self) -> bool {
        self.tor_place().eq_ignore_ascii_case("chain")
    }

    pub fn tor_reverse(&self) -> bool {
        self.tor_place().eq_ignore_ascii_case("reverse")
    }

    pub fn uses_tor(&self) -> bool {
        self.tor_only() || self.tor_chain() || self.tor_reverse()
    }

    pub fn runs_alone(&self) -> bool {
        self.psiphon_only() || self.tor_only()
    }

    pub fn carries_inside(&self) -> bool {
        self.uses_chain() || self.tor_chain()
    }

    pub fn dials_through(&self) -> bool {
        self.psiphon_reverse() || self.tor_reverse()
    }

    pub fn psiphon_wire(&self) -> &'static str {
        if self.psiphon_only() {
            "only"
        } else if self.uses_chain() {
            "chain"
        } else if self.psiphon_reverse() {
            "reverse"
        } else {
            ""
        }
    }

    pub fn effective_protocol(&self) -> String {
        let chosen = self.protocol.trim();
        let needs_udp = chosen.eq_ignore_ascii_case("wg")
            || chosen.eq_ignore_ascii_case("wireguard")
            || chosen.eq_ignore_ascii_case("gool-classic");
        if self.dials_through() && needs_udp {
            "masque".to_string()
        } else {
            self.protocol.clone()
        }
    }

    pub fn core_protocol(&self) -> String {
        if self.uses_gool_classic() {
            "gool".to_string()
        } else {
            self.effective_protocol()
        }
    }

    pub fn runs_aether(&self) -> bool {
        true
    }

    pub fn runs_psiphon(&self) -> bool {
        self.psiphon_only() || self.uses_chain() || self.psiphon_reverse()
    }

    pub fn core_name(&self) -> &'static str {
        crate::psiphon::CORE_AETHER
    }

    pub fn aether_socks_port(&self) -> u16 {
        if !self.carries_inside() {
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
        if self.allow_lan && !self.carries_inside() {
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

    pub fn tor_mode(&self) -> String {
        let mode = if self.tor_only() {
            "only"
        } else if self.tor_chain() {
            "chain"
        } else if self.tor_reverse() {
            "reverse"
        } else {
            ""
        };
        mode.to_string()
    }

    pub fn carrier_side_port(&self) -> u16 {
        self.aether_http_port().saturating_add(1)
    }

    pub fn tor_bind_address(&self) -> String {
        if self.tor_chain() {
            format!("{}:{}", self.psiphon_listen_host(), self.socks_port)
        } else {
            format!("127.0.0.1:{}", self.carrier_side_port())
        }
    }

    pub fn psiphon_listen_host(&self) -> &'static str {
        if self.allow_lan {
            "0.0.0.0"
        } else {
            "127.0.0.1"
        }
    }

    pub fn psiphon_bind_address(&self) -> String {
        if self.psiphon_reverse() {
            format!("127.0.0.1:{}", self.carrier_side_port())
        } else {
            format!("{}:{}", self.psiphon_listen_host(), self.socks_port)
        }
    }

    pub fn psiphon_core_mode(&self) -> &'static str {
        match self.psiphon_mode.trim().to_ascii_lowercase().as_str() {
            "cdn" => "cdn",
            "direct" => "direct",
            _ => "auto",
        }
    }

    pub fn uses_mim(&self) -> bool {
        self.effective_protocol().trim().eq_ignore_ascii_case("mim")
    }

    pub fn uses_masque(&self) -> bool {
        let p = self.effective_protocol();
        let p = p.trim();
        p.eq_ignore_ascii_case("masque") || p.eq_ignore_ascii_case("mim")
    }

    pub fn uses_gool(&self) -> bool {
        self.effective_protocol()
            .trim()
            .eq_ignore_ascii_case("gool")
    }

    pub fn uses_gool_classic(&self) -> bool {
        self.effective_protocol()
            .trim()
            .eq_ignore_ascii_case("gool-classic")
    }

    pub fn masque_carrier(&self) -> bool {
        self.uses_masque() || self.uses_gool()
    }

    pub fn wiw_outer_peer(&self) -> &str {
        if self.uses_gool_classic() {
            self.wiw_outer.trim()
        } else {
            ""
        }
    }

    pub fn wiw_inner_peer(&self) -> &str {
        if self.uses_gool_classic() {
            self.wiw_inner.trim()
        } else {
            ""
        }
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

    pub fn noize_chosen(&self) -> bool {
        let noize = self.noize();
        let noize = noize.trim();
        !noize.is_empty() && !noize.eq_ignore_ascii_case(NOIZE_AUTO)
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
            ("AETHER_PROTOCOL".to_string(), self.core_protocol()),
            ("AETHER_SCAN".to_string(), self.scan_mode.clone()),
            ("AETHER_IP".to_string(), self.ip_version.clone()),
            ("AETHER_LOG_LEVEL".to_string(), self.log_level.clone()),
            (
                "AETHER_QUICK_RECONNECT".to_string(),
                if self.quick_reconnect { "1" } else { "0" }.to_string(),
            ),
        ];

        if self.noize_chosen() {
            env.push(("AETHER_NOIZE".to_string(), self.noize()));
        }

        if let Some(path) = self.identity_path() {
            env.push(("AETHER_CONFIG".to_string(), path));
        }

        if self.override_dns {
            env.push(("AETHER_DNS".to_string(), self.dns_servers().join(",")));
        }

        if self.uses_masque() {
            if let Some(mtu) = self.inner_mtu() {
                env.push(("AETHER_MASQUE_MTU".to_string(), mtu.to_string()));
            }
        }

        if self.masque_carrier() && (self.transport == "h2" || self.dials_through()) {
            env.push(("AETHER_MASQUE_HTTP2".to_string(), "1".to_string()));
        }

        if self.fragment && !self.runs_alone() {
            env.push(("AETHER_MASQUE_H2_FRAGMENT".to_string(), "1".to_string()));
        }

        if self.uses_gool_classic() {
            env.push(("AETHER_GOOL_MODE".to_string(), "classic".to_string()));
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
            env.push(("AETHER_PERF_PROFILE".to_string(), self.perf_profile.clone()));
        }

        if self.runs_psiphon() {
            env.push((
                "AETHER_PSIPHON".to_string(),
                self.psiphon_wire().to_string(),
            ));
            env.push((
                "AETHER_PSIPHON_BIND".to_string(),
                self.psiphon_bind_address(),
            ));
            env.push((
                "AETHER_PSIPHON_MODE".to_string(),
                self.psiphon_core_mode().to_string(),
            ));

            let region = self.psiphon_country.trim();
            if !region.is_empty() {
                env.push(("AETHER_PSIPHON_REGION".to_string(), region.to_string()));
            }

            let ips = self.psiphon_cdn_ips.trim();
            if !ips.is_empty() {
                env.push(("AETHER_PSIPHON_CDN_IPS".to_string(), ips.to_string()));
            }

            let names = self.psiphon_cdn_sni.trim();
            if !names.is_empty() {
                env.push(("AETHER_PSIPHON_CDN_SNI".to_string(), names.to_string()));
            }

            let sets = self.psiphon_cdn_sets.trim();
            if !sets.is_empty() {
                env.push(("AETHER_PSIPHON_CDN_SETS".to_string(), sets.to_string()));
            }

            let entries = self.psiphon_server_entries.trim();
            if !entries.is_empty() && std::path::Path::new(entries).is_file() {
                env.push((
                    "AETHER_PSIPHON_SERVER_ENTRIES".to_string(),
                    entries.to_string(),
                ));
            }

            let data = self.data_dir.trim();
            if !data.is_empty() {
                env.push(("AETHER_PSIPHON_DIR".to_string(), format!("{data}/psiphon")));
            }
        }

        let tor = self.tor_mode();
        if !tor.is_empty() {
            env.push(("AETHER_TOR".to_string(), tor.clone()));
            if tor != "only" {
                env.push(("AETHER_TOR_BIND".to_string(), self.tor_bind_address()));
            }
            let relays = self.tor_relays.trim();
            if !relays.is_empty() {
                env.push(("AETHER_TOR_RELAYS".to_string(), relays.to_string()));
            }
            let bridges = self.tor_bridges.trim();
            if !bridges.is_empty() {
                env.push(("AETHER_TOR_BRIDGES".to_string(), bridges.to_string()));
            }
        }

        let wanted = self.exit_loc.trim();
        if !wanted.is_empty() {
            env.push(("AETHER_EXIT_LOC".to_string(), wanted.to_string()));
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

    pub fn tun_mtu(&self) -> u16 {
        self.tunnel_mtu.clamp(TUN_MTU_MIN, TUN_MTU_MAX)
    }

    pub fn inner_mtu(&self) -> Option<u16> {
        (CORE_MTU_MIN..=CORE_MTU_MAX)
            .contains(&self.core_mtu)
            .then_some(self.core_mtu)
    }

    pub fn tunnel_mode(&self) -> bool {
        !self.proxy_only
    }

    pub fn system_proxy_mode(&self) -> bool {
        self.proxy_only && self.system_proxy
    }

    pub fn manual_gateway(&self) -> Option<String> {
        let value = self.endpoint.trim();
        if value.is_empty() || self.uses_gool_classic() {
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
        matches!(self.ip_version.trim(), "both" | "dual" | "v6")
    }

    pub fn hev_log_level(&self) -> &'static str {
        match self.log_level.as_str() {
            "trace" => "debug",
            "debug" => "info",
            _ => "warn",
        }
    }

    pub fn hev_config(&self, log_path: Option<&str>) -> String {
        let mut config = String::new();
        config.push_str("tunnel:\n");
        config.push_str(&format!("  name: '{}'\n", self.tunnel_interface));
        config.push_str(&format!("  mtu: {}\n", self.tun_mtu()));
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
        let settings = settings_from(r#"{"routeBlock":"one.example\ntwo.example\nthree.example"}"#);
        let env = settings.core_environment();
        let blocked = env
            .iter()
            .find(|(key, _)| key == "AETHER_ROUTE_BLOCK")
            .map(|(_, value)| value.as_str());
        assert_eq!(blocked, Some("one.example,two.example,three.example"));
    }
}

#[cfg(test)]
mod mtu_tests {
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
    fn the_default_tun_mtu_survives_the_clamp() {
        assert_eq!(settings_from("{}").tun_mtu(), 1500);
    }

    #[test]
    fn a_tun_mtu_outside_the_range_is_pulled_back_in() {
        assert_eq!(settings_from(r#"{"tunnelMtu":42}"#).tun_mtu(), 1280);
        assert_eq!(settings_from(r#"{"tunnelMtu":65000}"#).tun_mtu(), 9000);
    }

    #[test]
    fn the_default_leaves_the_core_mtu_to_the_core() {
        let env = settings_from("{}").core_environment();
        assert!(value_of(&env, "AETHER_MASQUE_MTU").is_none());
    }

    #[test]
    fn a_measured_core_mtu_reaches_the_core() {
        let env = settings_from(r#"{"tunnelMtu":1280,"coreMtu":1180}"#).core_environment();
        assert_eq!(value_of(&env, "AETHER_MASQUE_MTU"), Some("1180"));
    }

    #[test]
    fn the_tunnel_mtu_alone_leaves_the_core_mtu_to_the_core() {
        let env = settings_from(r#"{"tunnelMtu":1400}"#).core_environment();
        assert!(value_of(&env, "AETHER_MASQUE_MTU").is_none());
    }

    #[test]
    fn both_ip_versions_route_ipv6_as_well() {
        assert!(settings_from("{}").dual_stack());
        assert!(settings_from(r#"{"ipVersion":"both"}"#).dual_stack());
        assert!(settings_from(r#"{"ipVersion":"v6"}"#).dual_stack());
        assert!(!settings_from(r#"{"ipVersion":"v4"}"#).dual_stack());
        let env = settings_from("{}").core_environment();
        assert_eq!(value_of(&env, "AETHER_IP"), Some("both"));
    }

    #[test]
    fn wireguard_keeps_its_own_packet_size() {
        let env = settings_from(r#"{"protocol":"wg","tunnelMtu":1400}"#).core_environment();
        assert!(value_of(&env, "AETHER_MASQUE_MTU").is_none());
    }

    #[test]
    fn the_tunnel_device_is_told_the_clamped_mtu() {
        let config = settings_from(r#"{"tunnelMtu":40000}"#).hev_config(None);
        assert!(config.contains("  mtu: 9000\n"));
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
        let env = settings_from(r#"{"team":"example","accessToken":"a.b.c"}"#).core_environment();
        assert_eq!(value_of(&env, "AETHER_TEAM"), Some("example"));
        assert_eq!(value_of(&env, "AETHER_ACCESS_TOKEN"), Some("a.b.c"));
    }

    #[test]
    fn a_service_token_is_forwarded_when_there_is_no_jwt() {
        let env = settings_from(r#"{"team":"example","accessId":"id","accessSecret":"secret"}"#)
            .core_environment();
        assert_eq!(value_of(&env, "AETHER_ACCESS_CLIENT_ID"), Some("id"));
        assert_eq!(
            value_of(&env, "AETHER_ACCESS_CLIENT_SECRET"),
            Some("secret")
        );
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
    fn a_chain_leaves_the_masque_transport_exactly_as_it_was_picked() {
        let h3 = settings_from(r#"{"core":"chain","protocol":"masque","transport":"h3"}"#)
            .core_environment();
        assert!(value_of(&h3, "AETHER_MASQUE_HTTP2").is_none());

        let h2 = settings_from(r#"{"core":"chain","protocol":"masque","transport":"h2"}"#)
            .core_environment();
        assert_eq!(value_of(&h2, "AETHER_MASQUE_HTTP2"), Some("1"));
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
    fn psiphon_on_its_own_is_still_hosted_by_the_core() {
        let settings = settings_from(r#"{"core":"psiphon"}"#);
        assert!(settings.runs_aether());
        assert!(settings.runs_psiphon());
        assert!(settings.psiphon_only());
        assert_eq!(settings.core_name(), crate::psiphon::CORE_AETHER);
    }

    #[test]
    fn aether_on_its_own_runs_no_psiphon() {
        let settings = settings_from(r#"{"core":"aether"}"#);
        assert!(settings.runs_aether());
        assert!(!settings.runs_psiphon());
    }

    #[test]
    fn psiphon_around_warp_and_tor_inside_it_each_get_their_own_port() {
        let settings = settings_from(r#"{"psiphon":"reverse","tor":"chain","socksPort":1819}"#);
        assert!(settings.psiphon_reverse());
        assert!(settings.tor_chain());
        assert!(settings.carries_inside());
        assert!(settings.dials_through());

        let env = settings.core_environment();
        assert_eq!(value_of(&env, "AETHER_SOCKS"), Some("127.0.0.1:1829"));
        assert_eq!(value_of(&env, "AETHER_PSIPHON"), Some("reverse"));
        assert_eq!(
            value_of(&env, "AETHER_PSIPHON_BIND"),
            Some("127.0.0.1:1831")
        );
        assert_eq!(value_of(&env, "AETHER_TOR"), Some("chain"));
        assert_eq!(value_of(&env, "AETHER_TOR_BIND"), Some("127.0.0.1:1819"));
    }

    #[test]
    fn tor_around_warp_and_psiphon_inside_it_each_get_their_own_port() {
        let env = settings_from(r#"{"psiphon":"chain","tor":"reverse","socksPort":1819}"#)
            .core_environment();
        assert_eq!(value_of(&env, "AETHER_PSIPHON"), Some("chain"));
        assert_eq!(
            value_of(&env, "AETHER_PSIPHON_BIND"),
            Some("127.0.0.1:1819")
        );
        assert_eq!(value_of(&env, "AETHER_TOR"), Some("reverse"));
        assert_eq!(value_of(&env, "AETHER_TOR_BIND"), Some("127.0.0.1:1831"));
    }

    #[test]
    fn the_new_fields_win_over_a_core_left_from_before() {
        let settings = settings_from(r#"{"core":"tor-chain","psiphon":"chain","tor":"off"}"#);
        assert!(settings.uses_chain());
        assert!(!settings.uses_tor());
    }

    #[test]
    fn a_core_from_before_reads_as_the_same_places() {
        for (core, psiphon, tor) in [
            ("aether", "", ""),
            ("psiphon", "only", ""),
            ("chain", "chain", ""),
            ("psiphon-reverse", "reverse", ""),
            ("tor", "", "only"),
            ("tor-chain", "", "chain"),
            ("tor-reverse", "", "reverse"),
        ] {
            let settings = settings_from(&format!(r#"{{"core":"{core}"}}"#));
            assert_eq!(settings.psiphon_wire(), psiphon, "{core}");
            assert_eq!(settings.tor_mode(), tor, "{core}");
        }
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
    fn classic_gool_is_named_to_the_core_as_gool_in_its_classic_mode() {
        let env = settings_from(r#"{"protocol":"gool-classic"}"#).core_environment();
        assert_eq!(value_of(&env, "AETHER_PROTOCOL"), Some("gool"));
        assert_eq!(value_of(&env, "AETHER_GOOL_MODE"), Some("classic"));
    }

    #[test]
    fn both_hops_reach_the_core_when_they_are_named_by_hand() {
        let env = settings_from(
            r#"{"protocol":"gool-classic","wiwOuter":"162.159.192.1:2408","wiwInner":"188.114.96.1:894"}"#,
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
        let env = settings_from(r#"{"protocol":"gool-classic","wiwOuter":"162.159.192.1:2408"}"#)
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
        let env = settings_from(r#"{"protocol":"gool-classic"}"#).core_environment();
        assert_eq!(value_of(&env, "AETHER_WIW_PEERS"), Some("auto"));
    }

    #[test]
    fn the_masque_endpoint_never_becomes_a_classic_gool_hop() {
        let settings =
            settings_from(r#"{"protocol":"gool-classic","endpoint":"162.159.198.1:443"}"#);
        let env = settings.core_environment();

        assert!(
            value_of(&env, "AETHER_PEER").is_none(),
            "AETHER_PEER doubles as the outer hop, so it must not survive into classic gool"
        );
        assert_eq!(value_of(&env, "AETHER_WIW_PEERS"), Some("auto"));
        assert_eq!(settings.manual_gateway(), None);
    }

    #[test]
    fn hops_set_on_another_protocol_are_ignored() {
        let env = settings_from(
            r#"{"protocol":"masque","endpoint":"162.159.198.1:443","wiwOuter":"162.159.192.1:2408"}"#,
        )
        .core_environment();

        assert!(value_of(&env, "AETHER_WIW_OUTER_PEER").is_none());
        assert!(value_of(&env, "AETHER_GOOL_MODE").is_none());
        assert_eq!(value_of(&env, "AETHER_PEER"), Some("162.159.198.1:443"));
    }

    #[test]
    fn surrounding_whitespace_is_trimmed_off_a_hop() {
        let settings =
            settings_from(r#"{"protocol":"gool-classic","wiwInner":"  188.114.96.1:894  "}"#);
        assert_eq!(settings.wiw_inner_peer(), "188.114.96.1:894");
        assert!(settings.wiw_pinned());
    }

    #[test]
    fn gool_over_masque_leaves_every_classic_switch_off() {
        let env = settings_from(
            r#"{"protocol":"gool","wiwOuter":"162.159.192.1:2408","wiwInner":"188.114.96.1:894"}"#,
        )
        .core_environment();

        assert_eq!(value_of(&env, "AETHER_PROTOCOL"), Some("gool"));
        for key in [
            "AETHER_GOOL_MODE",
            "AETHER_WIW_OUTER_PEER",
            "AETHER_WIW_INNER_PEER",
            "AETHER_WIW_PEERS",
        ] {
            assert!(
                value_of(&env, key).is_none(),
                "{key} would turn gool classic"
            );
        }
    }

    #[test]
    fn gool_over_masque_takes_the_masque_gateway_and_carrier() {
        let settings = settings_from(
            r#"{"protocol":"gool","transport":"h2","endpoint":" 162.159.198.1:443 "}"#,
        );
        let env = settings.core_environment();

        assert_eq!(value_of(&env, "AETHER_PEER"), Some("162.159.198.1:443"));
        assert_eq!(value_of(&env, "AETHER_MASQUE_HTTP2"), Some("1"));
        assert_eq!(
            settings.manual_gateway().as_deref(),
            Some("162.159.198.1:443")
        );
    }

    #[test]
    fn gool_over_masque_keeps_the_masque_packet_size_of_the_core() {
        let env = settings_from(r#"{"protocol":"gool","tunnelMtu":1280,"coreMtu":1180}"#)
            .core_environment();
        assert!(value_of(&env, "AETHER_MASQUE_MTU").is_none());
    }

    #[test]
    fn through_a_carrier_gool_stays_and_classic_gool_falls_back_to_masque() {
        for core in ["tor-reverse", "psiphon-reverse"] {
            let gool = settings_from(&format!(r#"{{"core":"{core}","protocol":"gool"}}"#))
                .core_environment();
            assert_eq!(value_of(&gool, "AETHER_PROTOCOL"), Some("gool"), "{core}");
            assert_eq!(value_of(&gool, "AETHER_MASQUE_HTTP2"), Some("1"), "{core}");

            let classic =
                settings_from(&format!(r#"{{"core":"{core}","protocol":"gool-classic"}}"#))
                    .core_environment();
            assert_eq!(
                value_of(&classic, "AETHER_PROTOCOL"),
                Some("masque"),
                "{core}"
            );
            assert!(value_of(&classic, "AETHER_GOOL_MODE").is_none(), "{core}");
            assert!(value_of(&classic, "AETHER_WIW_PEERS").is_none(), "{core}");
        }
    }

    #[test]
    fn the_fragment_switch_reaches_the_core_on_every_carrier() {
        for json in [
            r#"{"fragment":true}"#,
            r#"{"fragment":true,"transport":"h2"}"#,
            r#"{"fragment":true,"protocol":"wg"}"#,
            r#"{"fragment":true,"protocol":"gool"}"#,
        ] {
            let env = settings_from(json).core_environment();
            assert_eq!(
                value_of(&env, "AETHER_MASQUE_H2_FRAGMENT"),
                Some("1"),
                "{json}"
            );
        }

        let off = settings_from("{}").core_environment();
        assert!(value_of(&off, "AETHER_MASQUE_H2_FRAGMENT").is_none());

        let alone = settings_from(r#"{"core":"psiphon","fragment":true}"#).core_environment();
        assert!(value_of(&alone, "AETHER_MASQUE_H2_FRAGMENT").is_none());
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

#[cfg(test)]
mod sync_tests {
    use super::*;

    fn settings(json: &str) -> TunnelSettings {
        serde_json::from_str(json).expect("settings parse")
    }

    fn value<'a>(env: &'a [(String, String)], key: &str) -> Option<&'a str> {
        env.iter().find(|(k, _)| k == key).map(|(_, v)| v.as_str())
    }

    #[test]
    fn tor_is_off_until_it_is_chosen() {
        let env = settings("{}").core_environment();
        assert!(value(&env, "AETHER_TOR").is_none());
        assert!(value(&env, "AETHER_TOR_BIND").is_none());
    }

    #[test]
    fn every_tor_core_reaches_the_core() {
        for (core, expected) in [
            ("tor", "only"),
            ("tor-chain", "chain"),
            ("tor-reverse", "reverse"),
        ] {
            let env = settings(&format!(r#"{{"core":"{core}"}}"#)).core_environment();
            assert_eq!(value(&env, "AETHER_TOR"), Some(expected), "{core}");
            assert!(value(&env, "AETHER_PSIPHON").is_none(), "{core}");
        }
    }

    #[test]
    fn a_tor_switch_left_in_old_settings_is_not_read() {
        let env = settings(r#"{"core":"aether","torMode":"chain"}"#).core_environment();
        assert!(value(&env, "AETHER_TOR").is_none());
    }

    #[test]
    fn tor_inside_warp_is_the_exit_on_the_public_port() {
        let chained = settings(r#"{"core":"tor-chain","socksPort":1819}"#);
        let env = chained.core_environment();
        assert_eq!(value(&env, "AETHER_TOR_BIND"), Some("127.0.0.1:1819"));
        assert_eq!(value(&env, "AETHER_SOCKS"), Some("127.0.0.1:1829"));
        assert_eq!(chained.aether_socks_port(), 1829);
    }

    #[test]
    fn tor_inside_warp_faces_the_lan_only_when_asked_and_warp_never_does() {
        let lan = settings(r#"{"core":"tor-chain","socksPort":1819,"allowLan":true}"#);
        let env = lan.core_environment();
        assert_eq!(value(&env, "AETHER_TOR_BIND"), Some("0.0.0.0:1819"));
        assert_eq!(value(&env, "AETHER_SOCKS"), Some("127.0.0.1:1829"));
    }

    #[test]
    fn warp_through_tor_keeps_the_public_port_and_tor_takes_a_loopback_side_port() {
        let reverse = settings(r#"{"core":"tor-reverse","socksPort":1819}"#);
        let env = reverse.core_environment();
        assert_eq!(value(&env, "AETHER_SOCKS"), Some("127.0.0.1:1819"));
        assert_eq!(value(&env, "AETHER_HTTP_PROXY"), Some("127.0.0.1:1820"));
        assert_eq!(value(&env, "AETHER_TOR_BIND"), Some("127.0.0.1:1821"));
    }

    #[test]
    fn tor_alone_is_served_on_the_public_port_itself() {
        let alone = settings(r#"{"core":"tor","socksPort":1819}"#).core_environment();
        assert_eq!(value(&alone, "AETHER_TOR"), Some("only"));
        assert_eq!(value(&alone, "AETHER_SOCKS"), Some("127.0.0.1:1819"));
        assert!(value(&alone, "AETHER_TOR_BIND").is_none());
    }

    #[test]
    fn through_a_carrier_only_masque_over_http2_runs() {
        for core in ["tor-reverse", "psiphon-reverse"] {
            let s = settings(&format!(
                r#"{{"core":"{core}","protocol":"wg","transport":"h3"}}"#
            ));
            assert_eq!(s.protocol, "wg", "{core}: the saved choice is kept");
            let env = s.core_environment();
            assert_eq!(value(&env, "AETHER_PROTOCOL"), Some("masque"), "{core}");
            assert_eq!(value(&env, "AETHER_MASQUE_HTTP2"), Some("1"), "{core}");
        }

        let direct = settings(r#"{"core":"aether","protocol":"wg"}"#).core_environment();
        assert_eq!(value(&direct, "AETHER_PROTOCOL"), Some("wg"));
    }

    #[test]
    fn an_unwanted_exit_country_is_passed_on_only_when_asked_for() {
        let off = settings("{}").core_environment();
        assert!(value(&off, "AETHER_EXIT_LOC").is_none());

        let on = settings(r#"{"exitLoc":"!IR,AZ,RU"}"#).core_environment();
        assert_eq!(value(&on, "AETHER_EXIT_LOC"), Some("!IR,AZ,RU"));
    }

    #[test]
    fn masque_in_masque_is_treated_as_a_masque_carrier() {
        let mim = settings(r#"{"protocol":"mim","transport":"h2"}"#);
        assert!(mim.uses_mim());
        assert!(mim.uses_masque());
        let env = mim.core_environment();
        assert_eq!(value(&env, "AETHER_PROTOCOL"), Some("mim"));
        assert_eq!(value(&env, "AETHER_MASQUE_HTTP2"), Some("1"));
    }

    #[test]
    fn automatic_obfuscation_leaves_the_profile_to_the_core() {
        let auto = settings(r#"{"obfuscation":"auto","noizeProfile":"auto"}"#).core_environment();
        assert!(value(&auto, "AETHER_NOIZE").is_none());

        let named = settings(r#"{"obfuscation":"gfw","noizeProfile":"gfw"}"#).core_environment();
        assert_eq!(value(&named, "AETHER_NOIZE"), Some("gfw"));

        let older = settings(r#"{"obfuscation":"light"}"#).core_environment();
        assert_eq!(value(&older, "AETHER_NOIZE"), Some("light"));
    }

    #[test]
    fn the_bridge_choice_travels_with_tor_alone() {
        let own =
            settings(r#"{"core":"tor","torBridges":"obfs4 1.2.3.4:443 AAAA cert=x iat-mode=0"}"#)
                .core_environment();
        assert_eq!(
            value(&own, "AETHER_TOR_BRIDGES"),
            Some("obfs4 1.2.3.4:443 AAAA cert=x iat-mode=0")
        );

        let never = settings(r#"{"core":"tor-chain","torBridges":"off"}"#).core_environment();
        assert_eq!(value(&never, "AETHER_TOR_BRIDGES"), Some("off"));

        let left = settings(r#"{"core":"tor","torBridges":""}"#).core_environment();
        assert!(value(&left, "AETHER_TOR_BRIDGES").is_none());

        let plain = settings(r#"{"torBridges":"off"}"#).core_environment();
        assert!(value(&plain, "AETHER_TOR_BRIDGES").is_none());
    }

    #[test]
    fn the_relay_source_defaults_to_auto_and_travels_with_tor() {
        let env = settings(r#"{"core":"tor-chain"}"#).core_environment();
        assert_eq!(value(&env, "AETHER_TOR_RELAYS"), Some("auto"));

        let env = settings(r#"{"core":"tor-chain","torRelays":"only"}"#).core_environment();
        assert_eq!(value(&env, "AETHER_TOR_RELAYS"), Some("only"));
    }
}

#[cfg(test)]
mod psiphon_through_core_tests {
    use super::*;

    fn settings(json: &str) -> TunnelSettings {
        serde_json::from_str(json).expect("settings parse")
    }

    fn value<'a>(env: &'a [(String, String)], key: &str) -> Option<&'a str> {
        env.iter().find(|(k, _)| k == key).map(|(_, v)| v.as_str())
    }

    #[test]
    fn plain_aether_never_mentions_psiphon() {
        let env = settings("{}").core_environment();
        assert!(value(&env, "AETHER_PSIPHON").is_none());
        assert!(value(&env, "AETHER_PSIPHON_BIND").is_none());
    }

    #[test]
    fn psiphon_on_its_own_is_the_only_thing_the_core_serves() {
        let s = settings(r#"{"core":"psiphon","socksPort":1829}"#);
        let env = s.core_environment();
        assert_eq!(value(&env, "AETHER_PSIPHON"), Some("only"));
        assert_eq!(value(&env, "AETHER_PSIPHON_BIND"), Some("127.0.0.1:1829"));
        assert_eq!(value(&env, "AETHER_SOCKS"), Some("127.0.0.1:1829"));
    }

    #[test]
    fn a_chain_puts_psiphon_on_the_port_people_connect_to() {
        let s = settings(r#"{"core":"chain","socksPort":1829}"#);
        let env = s.core_environment();
        assert_eq!(value(&env, "AETHER_PSIPHON"), Some("chain"));
        assert_eq!(value(&env, "AETHER_PSIPHON_BIND"), Some("127.0.0.1:1829"));
        assert_eq!(value(&env, "AETHER_SOCKS"), Some("127.0.0.1:1839"));
    }

    #[test]
    fn warp_through_psiphon_keeps_the_public_port_and_psiphon_takes_a_side_port() {
        let s = settings(r#"{"core":"psiphon-reverse","socksPort":1819,"allowLan":true}"#);
        let env = s.core_environment();
        assert_eq!(value(&env, "AETHER_PSIPHON"), Some("reverse"));
        assert_eq!(value(&env, "AETHER_SOCKS"), Some("0.0.0.0:1819"));
        assert_eq!(value(&env, "AETHER_PSIPHON_BIND"), Some("127.0.0.1:1821"));
        assert!(value(&env, "AETHER_TOR").is_none());
    }

    #[test]
    fn lan_sharing_reaches_the_psiphon_listener_too() {
        let env = settings(r#"{"core":"psiphon","allowLan":true}"#).core_environment();
        assert!(value(&env, "AETHER_PSIPHON_BIND").is_some_and(|a| a.starts_with("0.0.0.0:")));
    }

    #[test]
    fn the_region_and_cdn_settings_travel_with_it() {
        let env = settings(
            r#"{"core":"psiphon","psiphonCountry":"DE","psiphonCdnIps":"1.2.3.4","psiphonCdnSni":"a.example"}"#,
        )
        .core_environment();
        assert_eq!(value(&env, "AETHER_PSIPHON_REGION"), Some("DE"));
        assert_eq!(value(&env, "AETHER_PSIPHON_CDN_IPS"), Some("1.2.3.4"));
        assert_eq!(value(&env, "AETHER_PSIPHON_CDN_SNI"), Some("a.example"));
    }

    #[test]
    fn the_cdn_lists_travel_only_when_some_were_picked() {
        let none = settings(r#"{"core":"psiphon"}"#).core_environment();
        assert!(value(&none, "AETHER_PSIPHON_CDN_SETS").is_none());

        let picked =
            settings(r#"{"core":"chain","psiphonCdnSets":"cloudflare,fastly"}"#).core_environment();
        assert_eq!(
            value(&picked, "AETHER_PSIPHON_CDN_SETS"),
            Some("cloudflare,fastly")
        );

        let plain = settings(r#"{"psiphonCdnSets":"cloudflare"}"#).core_environment();
        assert!(value(&plain, "AETHER_PSIPHON_CDN_SETS").is_none());
    }

    #[test]
    fn the_bundled_server_list_travels_only_with_psiphon_and_a_real_file() {
        let directory =
            std::env::temp_dir().join(format!("oblivion-entries-{}", std::process::id()));
        std::fs::create_dir_all(&directory).unwrap();
        let entries = directory.join("psiphon-servers.txt");
        std::fs::write(&entries, "00\n").unwrap();
        let path = entries.to_string_lossy().replace('\\', "\\\\");

        let with = settings(&format!(
            r#"{{"core":"psiphon","psiphonServerEntries":"{path}"}}"#
        ))
        .core_environment();
        assert_eq!(
            value(&with, "AETHER_PSIPHON_SERVER_ENTRIES"),
            Some(entries.to_string_lossy().as_ref())
        );

        let missing =
            settings(r#"{"core":"psiphon","psiphonServerEntries":"/nowhere/psiphon-servers.txt"}"#)
                .core_environment();
        assert!(value(&missing, "AETHER_PSIPHON_SERVER_ENTRIES").is_none());

        let warp = settings(&format!(r#"{{"psiphonServerEntries":"{path}"}}"#)).core_environment();
        assert!(value(&warp, "AETHER_PSIPHON_SERVER_ENTRIES").is_none());

        let _ = std::fs::remove_dir_all(&directory);
    }

    #[test]
    fn conduit_falls_back_to_auto_because_the_core_has_no_inproxy() {
        for (given, expected) in [
            ("auto", "auto"),
            ("cdn", "cdn"),
            ("direct", "direct"),
            ("conduit", "auto"),
        ] {
            let env = settings(&format!(r#"{{"core":"psiphon","psiphonMode":"{given}"}}"#))
                .core_environment();
            assert_eq!(
                value(&env, "AETHER_PSIPHON_MODE"),
                Some(expected),
                "{given}"
            );
        }
    }
}
