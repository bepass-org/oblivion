use std::path::PathBuf;

use serde_json::{json, Map, Value};

use crate::settings::TunnelSettings;

pub const CORE_AETHER: &str = "aether";
pub const CORE_PSIPHON: &str = "psiphon";

pub const MODE_AUTO: &str = "auto";
pub const MODE_CDN: &str = "cdn";
pub const MODE_CONDUIT: &str = "conduit";
pub const MODE_DIRECT: &str = "direct";

pub const CONDUIT_PEERS_AUTO: &str = "auto";
pub const CONDUIT_PEERS_PRIVATE: &str = "private";
pub const CONDUIT_PEERS_PUBLIC: &str = "public";

const CDN_PROTOCOLS: [&str; 3] = [
    "FRONTED-MEEK-CDN-OSSH",
    "FRONTED-MEEK-CDN-HTTP-OSSH",
    "FRONTED-MEEK-CDN-QUIC-OSSH",
];

const CONDUIT_PROTOCOLS: [&str; 9] = [
    "INPROXY-WEBRTC-OSSH",
    "INPROXY-WEBRTC-TLS-OSSH",
    "INPROXY-WEBRTC-UNFRONTED-MEEK-OSSH",
    "INPROXY-WEBRTC-UNFRONTED-MEEK-HTTPS-OSSH",
    "INPROXY-WEBRTC-UNFRONTED-MEEK-SESSION-TICKET-OSSH",
    "INPROXY-WEBRTC-FRONTED-MEEK-OSSH",
    "INPROXY-WEBRTC-FRONTED-MEEK-HTTP-OSSH",
    "INPROXY-WEBRTC-QUIC-OSSH",
    "INPROXY-WEBRTC-SHADOWSOCKS-OSSH",
];

const DIRECT_PROTOCOLS: [&str; 14] = [
    "SSH",
    "OSSH",
    "TLS-OSSH",
    "UNFRONTED-MEEK-OSSH",
    "UNFRONTED-MEEK-HTTPS-OSSH",
    "UNFRONTED-MEEK-SESSION-TICKET-OSSH",
    "QUIC-OSSH",
    "SHADOWSOCKS-OSSH",
    "FRONTED-MEEK-OSSH",
    "FRONTED-MEEK-CDN-OSSH",
    "FRONTED-MEEK-HTTP-OSSH",
    "FRONTED-MEEK-CDN-HTTP-OSSH",
    "FRONTED-MEEK-QUIC-OSSH",
    "FRONTED-MEEK-CDN-QUIC-OSSH",
];

const CENSORED_COUNTRY_CODES: [&str; 6] = ["IR", "CN", "RU", "TM", "BY", "MM"];

const EDGE_ADDRESSES: [(&str, &str); 9] = [
    ("edge-a-1", "23.215.0.206"),
    ("edge-a-2", "23.215.0.203"),
    ("edge-b-1", "23.212.250.91"),
    ("edge-b-2", "23.212.250.78"),
    ("edge-c-1", "23.12.147.13"),
    ("edge-c-2", "23.12.147.29"),
    ("edge-d-1", "23.73.207.8"),
    ("edge-d-2", "23.73.207.15"),
    ("edge-original", "92.123.102.43"),
];

const EDGE_VERIFY_NAMES: [&str; 6] = [
    "a248.e.akamai.net",
    "a.akamaized.net",
    "a.akamaized-staging.net",
    "a.akamaihd.net",
    "a.akamaihd-staging.net",
    "www.akamai.com",
];

const FASTLY_VERIFY_NAMES: [&str; 9] = [
    "www.python.org",
    "pypi.org",
    "fastly.com",
    "www.fastly.com",
    "developer.fastly.com",
    "githubassets.com",
    "github.com",
    "github.io",
    "githubusercontent.com",
];

const DEFAULT_PROPAGATION_CHANNEL_ID: &str = "FFFFFFFFFFFFFFFF";

const DEFAULT_SPONSOR_ID: &str = "FFFFFFFFFFFFFFFF";

const DEFAULT_SERVER_LIST_URL: &str =
    "https://s3.amazonaws.com//psiphon/web/mjr4-p23r-puwl/server_list_compressed";

const DEFAULT_SERVER_LIST_SIGNATURE_KEY: &str = concat!(
    "MIICIDANBgkqhkiG9w0BAQEFAAOCAg0AMIICCAKCAgEAt7Ls+/39r+T6zNW7GiVpJfzq/xvL9SBH",
    "5rIFnk0RXYEYavax3WS6HOD35eTAqn8AniOwiH+DOkvgSKF2caqk/y1dfq47Pdymtwzp9ikpB1C5",
    "OfAysXzBiwVJlCdajBKvBZDerV1cMvRzCKvKwRmvDmHgphQQ7WfXIGbRbmmk6opMBh3roE42Kcot",
    "LFtqp0RRwLtcBRNtCdsrVsjiI1Lqz/lH+T61sGjSjQ3CHMuZYSQJZo/KrvzgQXpkaCTdbObxHqb6",
    "/+i1qaVOfEsvjoiyzTxJADvSytVtcTjijhPEV6XskJVHE1Zgl+7rATr/pDQkw6DPCNBS1+Y6fy7G",
    "stZALQXwEDN/qhQI9kWkHijT8ns+i1vGg00Mk/6J75arLhqcodWsdeG/M/moWgqQAnlZAGVtJI1O",
    "geF5fsPpXu4kctOfuZlGjVZXQNW34aOzm8r8S0eVZitPlbhcPiR4gT/aSMz/wd8lZlzZYsje/Jr8",
    "u/YtlwjjreZrGRmG8KMOzukV3lLmMppXFMvl4bxv6YFEmIuTsOhbLTwFgh7KYNjodLj/LsqRVfwz",
    "31PgWQFTEPICV7GCvgVlPRxnofqKSjgTWI4mxDhBpVcATvaoBl1L/6WLbFvBsoAUBItWwctO2xal",
    "KxF5szhGm8lccoc5MZr8kfE0uxMgsxz4er68iCID+rsCAQM=",
);

fn embedded(runtime_key: &str, compiled: Option<&'static str>, fallback: &str) -> String {
    if let Ok(value) = std::env::var(runtime_key) {
        let trimmed = value.trim();
        if !trimmed.is_empty() {
            return trimmed.to_string();
        }
    }
    let compiled = compiled.unwrap_or_default().trim();
    if !compiled.is_empty() {
        return compiled.to_string();
    }
    fallback.to_string()
}

pub fn propagation_channel_id() -> String {
    embedded(
        "OBLIVION_PSIPHON_PROPAGATION_CHANNEL_ID",
        option_env!("OBLIVION_PSIPHON_PROPAGATION_CHANNEL_ID"),
        DEFAULT_PROPAGATION_CHANNEL_ID,
    )
}

pub fn sponsor_id() -> String {
    embedded(
        "OBLIVION_PSIPHON_SPONSOR_ID",
        option_env!("OBLIVION_PSIPHON_SPONSOR_ID"),
        DEFAULT_SPONSOR_ID,
    )
}

pub fn server_list_url() -> String {
    embedded(
        "OBLIVION_PSIPHON_SERVER_LIST_URL",
        option_env!("OBLIVION_PSIPHON_SERVER_LIST_URL"),
        DEFAULT_SERVER_LIST_URL,
    )
}

pub fn server_list_signature_key() -> String {
    embedded(
        "OBLIVION_PSIPHON_SERVER_LIST_SIGNATURE_KEY",
        option_env!("OBLIVION_PSIPHON_SERVER_LIST_SIGNATURE_KEY"),
        DEFAULT_SERVER_LIST_SIGNATURE_KEY,
    )
}

fn base64_encode(input: &str) -> String {
    const ALPHABET: &[u8; 64] =
        b"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    let bytes = input.as_bytes();
    let mut encoded = String::with_capacity((bytes.len() + 2) / 3 * 4);

    for chunk in bytes.chunks(3) {
        let b0 = chunk[0] as u32;
        let b1 = *chunk.get(1).unwrap_or(&0) as u32;
        let b2 = *chunk.get(2).unwrap_or(&0) as u32;
        let triple = (b0 << 16) | (b1 << 8) | b2;

        encoded.push(ALPHABET[(triple >> 18) as usize & 0x3f] as char);
        encoded.push(ALPHABET[(triple >> 12) as usize & 0x3f] as char);
        if chunk.len() > 1 {
            encoded.push(ALPHABET[(triple >> 6) as usize & 0x3f] as char);
        } else {
            encoded.push('=');
        }
        if chunk.len() > 2 {
            encoded.push(ALPHABET[triple as usize & 0x3f] as char);
        } else {
            encoded.push('=');
        }
    }

    encoded
}

pub fn conduit_compartment_id() -> String {
    embedded(
        "OBLIVION_PSIPHON_CONDUIT_COMPARTMENT_ID",
        option_env!("OBLIVION_PSIPHON_CONDUIT_COMPARTMENT_ID"),
        "",
    )
}

pub fn is_provisioned() -> bool {
    !propagation_channel_id().is_empty() && !sponsor_id().is_empty()
}

pub fn data_directory(settings: &TunnelSettings) -> PathBuf {
    let base = settings.data_dir.trim();
    let root = if base.is_empty() {
        std::env::temp_dir().join("oblivion")
    } else {
        PathBuf::from(base)
    };
    root.join("psiphon")
}

pub fn config_path(settings: &TunnelSettings) -> PathBuf {
    data_directory(settings).join("psiphon.config")
}

fn is_ipv4(value: &str) -> bool {
    let parts: Vec<&str> = value.split('.').collect();
    if parts.len() != 4 {
        return false;
    }
    parts.iter().all(|part| {
        !part.is_empty()
            && part.len() <= 3
            && part.chars().all(|c| c.is_ascii_digit())
            && part.parse::<u16>().map(|v| v <= 255).unwrap_or(false)
    })
}

fn is_ipv4_cidr(value: &str) -> bool {
    match value.split_once('/') {
        Some((address, prefix)) => {
            is_ipv4(address)
                && !prefix.is_empty()
                && prefix.chars().all(|c| c.is_ascii_digit())
                && prefix.parse::<u8>().map(|v| v <= 32).unwrap_or(false)
        }
        None => false,
    }
}

pub fn cdn_ip_candidates(raw: &str) -> Vec<String> {
    let mut candidates = Vec::new();
    for entry in raw.split([' ', '\t', '\n', '\r', ',', ';']) {
        let value = entry.trim();
        if value.is_empty() || (!is_ipv4(value) && !is_ipv4_cidr(value)) {
            continue;
        }
        if !candidates.iter().any(|existing| existing == value) {
            candidates.push(value.to_string());
        }
    }
    candidates
}

fn normalize_hostname(raw: &str) -> String {
    let mut value = raw.trim().to_lowercase();
    for prefix in ["https://", "http://"] {
        if let Some(rest) = value.strip_prefix(prefix) {
            value = rest.to_string();
        }
    }
    if let Some((host, _)) = value.split_once('/') {
        value = host.to_string();
    }
    let value = value.trim_matches('.').to_string();
    if value.is_empty() || !value.contains('.') {
        return String::new();
    }
    if value
        .chars()
        .any(|c| !(c.is_ascii_alphanumeric() || c == '.' || c == '-'))
    {
        return String::new();
    }
    value
}

pub fn cdn_sni_candidates(raw: &str) -> Vec<String> {
    let mut candidates = Vec::new();
    for entry in raw.split([' ', '\t', '\n', '\r', ',', ';']) {
        let value = normalize_hostname(entry);
        if value.is_empty() {
            continue;
        }
        if !candidates.iter().any(|existing| existing == &value) {
            candidates.push(value);
        }
    }
    candidates
}

fn make_override(
    override_id: &str,
    provider_regexes: Option<Vec<&str>>,
    dial_address_regexes: Option<Vec<&str>>,
    dial_address: &str,
    sni_server_name: &str,
    verify_server_names: Vec<String>,
    alpn_protocols: Vec<&str>,
) -> Value {
    let mut entry = Map::new();
    entry.insert("OverrideID".into(), json!(override_id));
    if let Some(regexes) = provider_regexes {
        entry.insert("MatchFrontingProviderIDRegexes".into(), json!(regexes));
    }
    if let Some(regexes) = dial_address_regexes {
        entry.insert("MatchDialAddressRegexes".into(), json!(regexes));
    }
    entry.insert("DialAddresses".into(), json!([dial_address]));
    entry.insert("SNIServerName".into(), json!(sni_server_name));
    entry.insert("VerifyServerNames".into(), json!(verify_server_names));
    entry.insert("ALPNProtocols".into(), json!(alpn_protocols));
    entry.insert("TLSProfile".into(), json!("Chrome-83"));
    Value::Object(entry)
}

fn unique_names(values: Vec<String>) -> Vec<String> {
    let mut names: Vec<String> = Vec::new();
    for value in values {
        let trimmed = value.trim().to_string();
        if trimmed.is_empty() || names.contains(&trimmed) {
            continue;
        }
        names.push(trimmed);
    }
    names
}

fn dial_overrides(custom_sni: &str) -> Vec<Value> {
    let edge_sni = cdn_sni_candidates(custom_sni)
        .into_iter()
        .next()
        .unwrap_or_default();

    let fastly_verify: Vec<String> =
        FASTLY_VERIFY_NAMES.iter().map(|name| name.to_string()).collect();

    let mut overrides = vec![
        make_override(
            "fastly-provider",
            Some(vec!["(?i)fastly"]),
            None,
            "pypi.org",
            "pypi.org",
            fastly_verify.clone(),
            vec!["h2", "http/1.1"],
        ),
        make_override(
            "fastly-address",
            None,
            Some(vec!["(?i)(fastly|pypi|python|github)"]),
            "pypi.org",
            "pypi.org",
            fastly_verify,
            vec!["h2", "http/1.1"],
        ),
    ];

    let mut seen: Vec<&str> = Vec::new();
    for (override_id, address) in EDGE_ADDRESSES {
        if seen.contains(&address) {
            continue;
        }
        seen.push(address);

        let sni_server_name = if edge_sni.is_empty() {
            address.to_string()
        } else {
            edge_sni.clone()
        };

        let mut verify = vec![sni_server_name.clone(), address.to_string()];
        verify.extend(EDGE_VERIFY_NAMES.iter().map(|name| name.to_string()));

        overrides.push(make_override(
            override_id,
            None,
            Some(vec![".*"]),
            address,
            &sni_server_name,
            unique_names(verify),
            vec!["http/1.1"],
        ));
    }

    overrides
}

fn put_cdn_fronting(config: &mut Map<String, Value>, settings: &TunnelSettings) {
    config.insert(
        "FrontedMeekDialOverrides".into(),
        json!(dial_overrides(&settings.psiphon_cdn_sni)),
    );
    config.insert("FrontedMeekDialOverridesProbability".into(), json!(1.0));
    config.insert("FrontedMeekCDNScanUseBuiltInSpec".into(), json!(true));

    let ip_candidates = cdn_ip_candidates(&settings.psiphon_cdn_ips);
    if ip_candidates.is_empty() {
        return;
    }

    let mut spec = Map::new();
    spec.insert("IPCandidates".into(), json!(ip_candidates));

    let sni_candidates = cdn_sni_candidates(&settings.psiphon_cdn_sni);
    if !sni_candidates.is_empty() {
        spec.insert("SNIServerNames".into(), json!(sni_candidates));
    }

    config.insert("FrontedMeekCDNScanSpec".into(), Value::Object(spec));
}

pub fn mode(settings: &TunnelSettings) -> &str {
    match settings.psiphon_mode.trim() {
        MODE_CDN => MODE_CDN,
        MODE_CONDUIT => MODE_CONDUIT,
        MODE_DIRECT => MODE_DIRECT,
        _ => MODE_AUTO,
    }
}

pub fn build_config(settings: &TunnelSettings) -> Result<String, String> {
    let propagation = propagation_channel_id();
    let sponsor = sponsor_id();

    if propagation.is_empty() || sponsor.is_empty() {
        return Err(
            "the psiphon identifiers were overridden with empty values, unset \
             OBLIVION_PSIPHON_PROPAGATION_CHANNEL_ID and OBLIVION_PSIPHON_SPONSOR_ID"
                .to_string(),
        );
    }

    let directory = data_directory(settings);
    std::fs::create_dir_all(&directory)
        .map_err(|error| format!("could not prepare the psiphon data directory: {error}"))?;

    let mut config = Map::new();

    config.insert("PropagationChannelId".into(), json!(propagation));
    config.insert("SponsorId".into(), json!(sponsor));
    config.insert("ClientPlatform".into(), json!(client_platform()));
    config.insert("ClientVersion".into(), json!("1"));
    config.insert(
        "DataRootDirectory".into(),
        json!(directory.to_string_lossy()),
    );

    config.insert("LocalSocksProxyPort".into(), json!(settings.socks_port));
    config.insert(
        "LocalHttpProxyPort".into(),
        json!(settings.http_proxy_port()),
    );
    if settings.allow_lan {
        config.insert("ListenInterface".into(), json!("any"));
    }

    config.insert("EmitDiagnosticNotices".into(), json!(true));
    config.insert("EmitDiagnosticNetworkParameters".into(), json!(true));
    config.insert("EmitServerAlerts".into(), json!(true));

    let region = settings.psiphon_country.trim().to_uppercase();
    if !region.is_empty() {
        config.insert("EgressRegion".into(), json!(region));
    }

    let list_url = server_list_url();
    let list_key = server_list_signature_key();
    if !list_url.is_empty() && !list_key.is_empty() {
        config.insert(
            "RemoteServerListURLs".into(),
            json!([{ "URL": base64_encode(&list_url) }]),
        );
        config.insert("RemoteServerListSignaturePublicKey".into(), json!(list_key));
    }

    let selected = mode(settings);

    if selected != MODE_CONDUIT {
        put_cdn_fronting(&mut config, settings);
    }

    match selected {
        MODE_CDN => {
            config.insert("LimitTunnelProtocols".into(), json!(CDN_PROTOCOLS.to_vec()));
            config.insert("DisableTactics".into(), json!(true));
        }
        MODE_DIRECT => {
            config.insert(
                "LimitTunnelProtocols".into(),
                json!(DIRECT_PROTOCOLS.to_vec()),
            );
            config.insert("DisableTactics".into(), json!(true));
        }
        MODE_CONDUIT => {
            config.insert(
                "LimitTunnelProtocols".into(),
                json!(CONDUIT_PROTOCOLS.to_vec()),
            );

            let peers = settings.psiphon_conduit_peers.trim();
            let use_compartment = peers != CONDUIT_PEERS_PUBLIC;
            if use_compartment {
                let compartment = conduit_compartment_id();
                if !compartment.is_empty() {
                    config.insert(
                        "InproxyClientPersonalCompartmentID".into(),
                        json!(compartment),
                    );
                }
            }

            if settings.psiphon_reject_censored_peers {
                config.insert(
                    "InproxyRejectProxyCountryCodes".into(),
                    json!(CENSORED_COUNTRY_CODES.to_vec()),
                );
            }
        }
        _ => {}
    }

    serde_json::to_string_pretty(&Value::Object(config))
        .map_err(|error| format!("could not render the psiphon config: {error}"))
}

fn client_platform() -> String {
    let system = if cfg!(target_os = "windows") {
        "Windows"
    } else if cfg!(target_os = "macos") {
        "macOS"
    } else if cfg!(target_os = "android") {
        "Android"
    } else {
        "Linux"
    };
    format!("{system}_oblivion")
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum Notice {
    SocksPort(u16),
    Tunnels(u32),
    Region(String),
    RouteBypass(String),
    Failure(String),
    Info(String),
}

pub fn parse_notice(line: &str) -> Option<Notice> {
    let trimmed = line.trim();
    if !trimmed.starts_with('{') {
        return None;
    }

    let parsed: Value = serde_json::from_str(trimmed).ok()?;
    let kind = parsed.get("noticeType")?.as_str()?;
    let data = parsed.get("data");

    let field = |name: &str| -> Option<&Value> { data.and_then(|value| value.get(name)) };

    match kind {
        "ListeningSocksProxyPort" => field("port")
            .and_then(Value::as_u64)
            .map(|port| Notice::SocksPort(port as u16)),

        "Tunnels" => field("count")
            .and_then(Value::as_u64)
            .map(|count| Notice::Tunnels(count as u32)),

        "ConnectedServerRegion" => field("serverRegion")
            .and_then(Value::as_str)
            .map(|region| Notice::Region(region.to_string())),

        "ConnectedServer" => field("routeBypassIPAddress")
            .and_then(Value::as_str)
            .filter(|address| !address.is_empty())
            .map(|address| Notice::RouteBypass(address.to_string())),

        "EstablishTunnelTimeout" => Some(Notice::Failure(
            "psiphon could not establish a tunnel in time".to_string(),
        )),

        "SocksProxyPortInUse" => Some(Notice::Failure(format!(
            "the socks port {} is already in use",
            field("port").and_then(Value::as_u64).unwrap_or_default()
        ))),

        "HttpProxyPortInUse" => Some(Notice::Failure(format!(
            "the http proxy port {} is already in use",
            field("port").and_then(Value::as_u64).unwrap_or_default()
        ))),

        "Error" | "Alert" | "ServerAlert" => field("message")
            .and_then(Value::as_str)
            .map(|message| Notice::Failure(message.to_string())),

        "Info" | "Warning" => field("message")
            .and_then(Value::as_str)
            .map(|message| Notice::Info(message.to_string())),

        _ => None,
    }
}

pub fn describe(line: &str) -> Option<String> {
    match parse_notice(line)? {
        Notice::SocksPort(port) => Some(format!("[+] socks proxy listening on {port}")),
        Notice::Tunnels(count) if count > 0 => {
            Some(format!("[+] {count} tunnel(s) established"))
        }
        Notice::Tunnels(_) => Some("[!] no tunnels are established".to_string()),
        Notice::Region(region) => Some(format!("[+] connected through {region}")),
        Notice::RouteBypass(address) => {
            Some(format!("[+] server {address} must stay outside the tunnel"))
        }
        Notice::Failure(message) => Some(format!("[-] {message}")),
        Notice::Info(message) => Some(format!("[*] {message}")),
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn settings_from(json: &str) -> TunnelSettings {
        serde_json::from_str(json).expect("settings should parse")
    }

    fn provisioned(json: &str) -> Value {
        let settings = settings_from(json);
        let rendered = build_config(&settings).expect("config should build");
        serde_json::from_str(&rendered).expect("rendered config should be json")
    }

    #[test]
    fn a_plain_build_can_already_reach_the_psiphon_network() {
        assert!(is_provisioned());

        let parsed = provisioned(r#"{"core":"psiphon"}"#);
        assert_eq!(parsed["PropagationChannelId"], json!("FFFFFFFFFFFFFFFF"));
        assert_eq!(parsed["SponsorId"], json!("FFFFFFFFFFFFFFFF"));
        assert!(parsed["RemoteServerListSignaturePublicKey"]
            .as_str()
            .unwrap()
            .starts_with("MIICIDANBgkqhkiG9w0BAQEFAAOCAg0A"));
    }

    #[test]
    fn the_server_list_url_is_base64_encoded_as_a_transfer_url() {
        let parsed = provisioned(r#"{"core":"psiphon"}"#);
        let encoded = parsed["RemoteServerListURLs"][0]["URL"].as_str().unwrap();
        assert_eq!(
            encoded,
            "aHR0cHM6Ly9zMy5hbWF6b25hd3MuY29tLy9wc2lwaG9uL3dlYi9tanI0LXAyM3ItcHV3bC9zZXJ2ZXJfbGlzdF9jb21wcmVzc2Vk"
        );
    }

    #[test]
    fn base64_matches_the_reference_encoding() {
        assert_eq!(base64_encode(""), "");
        assert_eq!(base64_encode("f"), "Zg==");
        assert_eq!(base64_encode("fo"), "Zm8=");
        assert_eq!(base64_encode("foo"), "Zm9v");
        assert_eq!(base64_encode("foob"), "Zm9vYg==");
        assert_eq!(base64_encode("fooba"), "Zm9vYmE=");
        assert_eq!(base64_encode("foobar"), "Zm9vYmFy");
    }

    #[test]
    fn identifiers_can_be_overridden_at_build_or_run_time() {
        std::env::set_var("OBLIVION_PSIPHON_SPONSOR_ID", "OVERRIDDEN");
        let parsed = provisioned(r#"{"core":"psiphon"}"#);
        assert_eq!(parsed["PropagationChannelId"], json!("FFFFFFFFFFFFFFFF"));
        assert_eq!(parsed["SponsorId"], json!("OVERRIDDEN"));
        std::env::remove_var("OBLIVION_PSIPHON_SPONSOR_ID");
    }

    #[test]
    fn auto_mode_does_not_limit_protocols_but_keeps_cdn_fronting() {
        let parsed = provisioned(r#"{"core":"psiphon"}"#);
        assert!(parsed.get("LimitTunnelProtocols").is_none());
        assert!(parsed.get("DisableTactics").is_none());
        assert_eq!(parsed["FrontedMeekCDNScanUseBuiltInSpec"], json!(true));
        assert_eq!(parsed["FrontedMeekDialOverridesProbability"], json!(1.0));
        let overrides = parsed["FrontedMeekDialOverrides"].as_array().unwrap();
        assert_eq!(overrides.len(), 11);
    }

    #[test]
    fn cdn_mode_limits_protocols_and_disables_tactics() {
        let parsed = provisioned(r#"{"core":"psiphon","psiphonMode":"cdn"}"#);
        let protocols = parsed["LimitTunnelProtocols"].as_array().unwrap();
        assert_eq!(protocols.len(), 3);
        assert_eq!(parsed["DisableTactics"], json!(true));
    }

    #[test]
    fn direct_mode_uses_the_direct_protocol_list() {
        let parsed = provisioned(r#"{"core":"psiphon","psiphonMode":"direct"}"#);
        let protocols = parsed["LimitTunnelProtocols"].as_array().unwrap();
        assert_eq!(protocols.len(), 14);
        assert!(protocols.iter().any(|entry| entry == "OSSH"));
    }

    #[test]
    fn conduit_mode_uses_inproxy_only_and_drops_cdn_fronting() {
        let parsed = provisioned(r#"{"core":"psiphon","psiphonMode":"conduit"}"#);
        let protocols = parsed["LimitTunnelProtocols"].as_array().unwrap();
        assert!(protocols
            .iter()
            .all(|entry| entry.as_str().unwrap().starts_with("INPROXY-WEBRTC-")));
        assert!(parsed.get("FrontedMeekDialOverrides").is_none());
        assert!(parsed.get("FrontedMeekCDNScanUseBuiltInSpec").is_none());
    }

    #[test]
    fn public_conduit_peers_drop_the_compartment_id() {
        std::env::set_var("OBLIVION_PSIPHON_CONDUIT_COMPARTMENT_ID", "COMPARTMENT");

        let private = provisioned(r#"{"core":"psiphon","psiphonMode":"conduit"}"#);
        assert_eq!(
            private["InproxyClientPersonalCompartmentID"],
            json!("COMPARTMENT")
        );

        let public = provisioned(
            r#"{"core":"psiphon","psiphonMode":"conduit","psiphonConduitPeers":"public"}"#,
        );
        assert!(public.get("InproxyClientPersonalCompartmentID").is_none());

        std::env::remove_var("OBLIVION_PSIPHON_CONDUIT_COMPARTMENT_ID");
    }

    #[test]
    fn censored_peers_are_rejected_by_default() {
        let on = provisioned(r#"{"core":"psiphon","psiphonMode":"conduit"}"#);
        let codes = on["InproxyRejectProxyCountryCodes"].as_array().unwrap();
        assert!(codes.iter().any(|entry| entry == "IR"));

        let off = provisioned(
            r#"{"core":"psiphon","psiphonMode":"conduit","psiphonRejectCensoredPeers":false}"#,
        );
        assert!(off.get("InproxyRejectProxyCountryCodes").is_none());
    }

    #[test]
    fn custom_edge_addresses_become_a_scan_spec() {
        let parsed = provisioned(
            r#"{"core":"psiphon","psiphonMode":"cdn",
                "psiphonCdnIps":"23.215.0.1, 104.16.0.0/13 bogus 999.1.1.1",
                "psiphonCdnSni":"www.example.com, HTTPS://Cdn.Example.com/path"}"#,
        );
        let spec = &parsed["FrontedMeekCDNScanSpec"];
        assert_eq!(
            spec["IPCandidates"],
            json!(["23.215.0.1", "104.16.0.0/13"])
        );
        assert_eq!(
            spec["SNIServerNames"],
            json!(["www.example.com", "cdn.example.com"])
        );
    }

    #[test]
    fn without_custom_addresses_there_is_no_scan_spec() {
        let parsed = provisioned(r#"{"core":"psiphon","psiphonMode":"cdn"}"#);
        assert!(parsed.get("FrontedMeekCDNScanSpec").is_none());
    }

    #[test]
    fn a_custom_sni_replaces_the_edge_sni() {
        let parsed = provisioned(
            r#"{"core":"psiphon","psiphonCdnSni":"cdn.example.com"}"#,
        );
        let overrides = parsed["FrontedMeekDialOverrides"].as_array().unwrap();
        let edge = overrides
            .iter()
            .find(|entry| entry["OverrideID"] == json!("edge-a-1"))
            .unwrap();
        assert_eq!(edge["SNIServerName"], json!("cdn.example.com"));
        assert_eq!(edge["DialAddresses"], json!(["23.215.0.206"]));
        let verify = edge["VerifyServerNames"].as_array().unwrap();
        assert_eq!(verify[0], json!("cdn.example.com"));
        assert!(verify.iter().any(|entry| entry == "a248.e.akamai.net"));
    }

    #[test]
    fn an_edge_without_a_custom_sni_uses_its_own_address() {
        let parsed = provisioned(r#"{"core":"psiphon"}"#);
        let overrides = parsed["FrontedMeekDialOverrides"].as_array().unwrap();
        let edge = overrides
            .iter()
            .find(|entry| entry["OverrideID"] == json!("edge-original"))
            .unwrap();
        assert_eq!(edge["SNIServerName"], json!("92.123.102.43"));
    }

    #[test]
    fn a_country_becomes_an_egress_region() {
        let parsed = provisioned(r#"{"core":"psiphon","psiphonCountry":"de"}"#);
        assert_eq!(parsed["EgressRegion"], json!("DE"));

        let auto = provisioned(r#"{"core":"psiphon"}"#);
        assert!(auto.get("EgressRegion").is_none());
    }

    #[test]
    fn address_lists_reject_rubbish() {
        assert_eq!(
            cdn_ip_candidates("1.2.3.4 1.2.3.4 300.1.1.1 1.2.3 10.0.0.0/8 10.0.0.0/33"),
            vec!["1.2.3.4", "10.0.0.0/8"]
        );
        assert_eq!(cdn_sni_candidates("nodots, ok.example, ok.example"), vec!["ok.example"]);
    }

    #[test]
    fn notices_are_read() {
        assert_eq!(
            parse_notice(r#"{"noticeType":"ListeningSocksProxyPort","data":{"port":1819}}"#),
            Some(Notice::SocksPort(1819))
        );
        assert_eq!(
            parse_notice(r#"{"noticeType":"Tunnels","data":{"count":1}}"#),
            Some(Notice::Tunnels(1))
        );
        assert_eq!(
            parse_notice(
                r#"{"noticeType":"ConnectedServer","data":{"routeBypassIPAddress":"1.2.3.4"}}"#
            ),
            Some(Notice::RouteBypass("1.2.3.4".to_string()))
        );
        assert_eq!(
            parse_notice(r#"{"noticeType":"ConnectedServer","data":{"region":"NL"}}"#),
            None
        );
        assert!(matches!(
            parse_notice(r#"{"noticeType":"EstablishTunnelTimeout","data":{}}"#),
            Some(Notice::Failure(_))
        ));
        assert_eq!(parse_notice("starting up"), None);
    }

    #[test]
    fn defaults_are_set() {
        let propagation = propagation_channel_id();
        let sponsor = sponsor_id();
        let url = server_list_url();
        let key = server_list_signature_key();

        assert!(!propagation.is_empty(), "propagation channel id should not be empty");
        assert!(!sponsor.is_empty(), "sponsor id should not be empty");
        assert!(!url.is_empty(), "server list url should not be empty");
        assert!(!key.is_empty(), "signature key should not be empty");

        // Check the warp-plus values
        assert_eq!(propagation, "FFFFFFFFFFFFFFFF", "expected FFFFFFFFFFFFFFFF");
        assert_eq!(sponsor, "FFFFFFFFFFFFFFFF", "expected FFFFFFFFFFFFFFFF");
    }
}
