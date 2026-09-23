package org.bepass.oblivion.vpn

data class TunnelConfig(
    val core: String,
    val psiphonCountry: String,
    val psiphonMode: String,
    val psiphonCdnIps: String,
    val psiphonCdnSni: String,
    val psiphonConduitPeers: String,
    val psiphonRejectCensoredPeers: Boolean,
    val torRelays: String,
    val exitLoc: String,
    val protocol: String,
    val transport: String,
    val scanMode: String,
    val obfuscation: String,
    val noizeProfile: String,
    val ipVersion: String,
    val logLevel: String,
    val perfProfile: String,
    val endpoint: String,
    val wiwOuter: String,
    val wiwInner: String,
    val socksPort: Int,
    val allowLan: Boolean,
    val proxyOnly: Boolean,
    val tunnelMtu: Int,
    val coreMtu: Int,
    val fragment: Boolean,
    val quickReconnect: Boolean,
    val splitTunnelMode: String,
    val bypassedApps: List<String>,
    val routeBlock: String,
    val routeDirect: String,
    val dnsPrimary: String,
    val dnsSecondary: String,
    val team: String,
    val accessToken: String,
    val accessId: String,
    val accessSecret: String,
    val gatewayProxy: Boolean,
    val coreArguments: List<String>,
) {
    val bindHost: String get() = if (allowLan) "0.0.0.0" else "127.0.0.1"

    val httpProxyPort: Int get() = socksPort + 1

    val usesChain: Boolean get() = core == CORE_CHAIN

    val psiphonOnly: Boolean get() = core == CORE_PSIPHON

    val psiphonReverse: Boolean get() = core == CORE_PSIPHON_REVERSE

    val torOnly: Boolean get() = core == CORE_TOR

    val torChain: Boolean get() = core == CORE_TOR_CHAIN

    val torReverse: Boolean get() = core == CORE_TOR_REVERSE

    val runsAether: Boolean get() = true

    val runsPsiphon: Boolean get() = psiphonOnly || usesChain || psiphonReverse

    val runsAlone: Boolean get() = psiphonOnly || torOnly

    val carriesInside: Boolean get() = usesChain || torChain

    val dialsThrough: Boolean get() = psiphonReverse || torReverse

    val aetherSocksPort: Int
        get() = when {
            !carriesInside -> socksPort
            socksPort + 11 <= 65535 -> socksPort + 10
            else -> socksPort - 10
        }

    val aetherHttpProxyPort: Int get() = aetherSocksPort + 1

    val aetherBindHost: String
        get() = if (allowLan && !carriesInside) "0.0.0.0" else "127.0.0.1"

    val chainUpstreamUrl: String get() = "socks5://127.0.0.1:$aetherSocksPort"

    val bypassSelected: Boolean get() = splitTunnelMode == "bypassSelected"

    val allowSelected: Boolean get() = splitTunnelMode == "onlySelected"

    val usesZeroTrust: Boolean get() = team.isNotBlank()

    val effectiveProtocol: String
        get() = if (dialsThrough && protocol in setOf("wg", "wireguard", "gool")) "masque" else protocol

    val usesGool: Boolean get() = effectiveProtocol == "gool"

    val usesMim: Boolean get() = effectiveProtocol == "mim"

    val usesMasque: Boolean get() = effectiveProtocol == "masque" || usesMim

    val usesHttp2: Boolean get() = usesMasque && (transport == "h2" || dialsThrough)

    val torWire: String
        get() = when {
            torOnly -> "only"
            torChain -> "chain"
            torReverse -> "reverse"
            else -> ""
        }

    val usesTor: Boolean get() = torWire.isNotEmpty()

    val psiphonWire: String
        get() = when {
            psiphonOnly -> "only"
            usesChain -> "chain"
            psiphonReverse -> "reverse"
            else -> ""
        }

    val carrierSidePort: Int get() = aetherHttpProxyPort + 1

    val psiphonListenHost: String get() = if (allowLan) "0.0.0.0" else "127.0.0.1"

    val torBindAddress: String
        get() = if (torChain) "$psiphonListenHost:$socksPort" else "127.0.0.1:$carrierSidePort"

    val psiphonBindAddress: String
        get() = if (psiphonReverse) "127.0.0.1:$carrierSidePort" else "$psiphonListenHost:$socksPort"

    val psiphonCoreMode: String
        get() = when (psiphonMode.trim().lowercase()) {
            "cdn" -> "cdn"
            "direct" -> "direct"
            else -> "auto"
        }

    val wiwOuterPeer: String get() = if (usesGool) wiwOuter.trim() else ""

    val wiwInnerPeer: String get() = if (usesGool) wiwInner.trim() else ""

    val wiwPinned: Boolean get() = wiwOuterPeer.isNotEmpty() || wiwInnerPeer.isNotEmpty()

    val dnsServers: List<String>
        get() {
            val resolvers = listOf(dnsPrimary, dnsSecondary)
                .map { it.trim() }
                .filter { it.isNotEmpty() }
                .distinct()
            return resolvers.ifEmpty { listOf("1.1.1.1", "1.0.0.1") }
        }

    val hasServiceToken: Boolean
        get() = accessId.isNotBlank() && accessSecret.isNotBlank()

    val mtu: Int get() = tunnelMtu.coerceIn(TUN_MTU_MIN, TUN_MTU_MAX)

    val innerMtu: Int
        get() = when {
            coreMtu in CORE_MTU_MIN..CORE_MTU_MAX -> coreMtu
            tunnelMtu in CORE_MTU_MIN..CORE_MTU_MAX -> tunnelMtu
            else -> 0
        }

    fun hevYaml(logPath: String? = null): String = buildString {
        appendLine("tunnel:")
        appendLine("  mtu: $mtu")
        appendLine("  ipv4: $TUN_IPV4")
        appendLine("  ipv6: '$TUN_IPV6'")
        appendLine("  post-up-script: ''")
        appendLine("socks5:")
        appendLine("  port: $socksPort")
        appendLine("  address: 127.0.0.1")
        appendLine("  udp: 'udp'")
        appendLine("misc:")
        appendLine("  task-stack-size: 20480")
        appendLine("  tcp-buffer-size: 8192")
        appendLine("  connect-timeout: 10000")
        appendLine("  read-write-timeout: 60000")
        appendLine("  log-level: '${hevLogLevel()}'")
        if (!logPath.isNullOrBlank()) appendLine("  log-file: '$logPath'")
    }

    private fun hevLogLevel(): String = when (logLevel) {
        "trace" -> "debug"
        "debug" -> "info"
        else -> "warn"
    }

    companion object {
        const val CORE_AETHER = "aether"
        const val CORE_PSIPHON = "psiphon"
        const val CORE_CHAIN = "chain"
        const val CORE_PSIPHON_REVERSE = "psiphon-reverse"
        const val CORE_TOR = "tor"
        const val CORE_TOR_CHAIN = "tor-chain"
        const val CORE_TOR_REVERSE = "tor-reverse"

        const val TUN_MTU = 8500
        const val TUN_MTU_MIN = 1280
        const val TUN_MTU_MAX = 9000
        const val CORE_MTU_MIN = 576
        const val CORE_MTU_MAX = 1500
        const val TUN_IPV4 = "198.18.0.1"
        const val TUN_IPV6 = "fc00::1"
        const val TUN_IPV4_PREFIX = 30
        const val TUN_IPV6_PREFIX = 126

        @Suppress("UNCHECKED_CAST")
        fun fromMap(settings: Map<String, Any?>, arguments: List<String>): TunnelConfig {
            fun str(key: String, fallback: String = "") = settings[key] as? String ?: fallback
            fun bool(key: String, fallback: Boolean = false) = settings[key] as? Boolean ?: fallback
            fun int(key: String, fallback: Int) = (settings[key] as? Number)?.toInt() ?: fallback

            return TunnelConfig(
                core = str("core", "aether"),
                psiphonCountry = str("psiphonCountry"),
                psiphonMode = str("psiphonMode", "auto"),
                psiphonCdnIps = str("psiphonCdnIps"),
                psiphonCdnSni = str("psiphonCdnSni"),
                psiphonConduitPeers = str("psiphonConduitPeers", "auto"),
                psiphonRejectCensoredPeers = bool("psiphonRejectCensoredPeers", true),
                torRelays = str("torRelays", "auto"),
                exitLoc = str("exitLoc"),
                protocol = str("protocol", "masque"),
                transport = str("transport", "h3"),
                scanMode = str("scanMode", "balanced"),
                obfuscation = str("obfuscation", "balanced"),
                noizeProfile = str("noizeProfile", str("obfuscation", "balanced")),
                ipVersion = str("ipVersion", "v4"),
                logLevel = str("logLevel", "info"),
                perfProfile = str("perfProfile"),
                endpoint = str("endpoint"),
                wiwOuter = str("wiwOuter"),
                wiwInner = str("wiwInner"),
                socksPort = int("socksPort", 1819),
                allowLan = bool("allowLan"),
                proxyOnly = bool("proxyOnly"),
                tunnelMtu = int("tunnelMtu", TUN_MTU),
                coreMtu = int("coreMtu", 0),
                fragment = bool("fragment"),
                quickReconnect = bool("quickReconnect", true),
                splitTunnelMode = str("splitTunnelMode", "disabled"),
                bypassedApps = (settings["bypassedApps"] as? List<String>) ?: emptyList(),
                routeBlock = str("routeBlock"),
                routeDirect = str("routeDirect"),
                dnsPrimary = str("dnsPrimary", "1.1.1.1"),
                dnsSecondary = str("dnsSecondary", "1.0.0.1"),
                team = str("team"),
                accessToken = str("accessToken"),
                accessId = str("accessId"),
                accessSecret = str("accessSecret"),
                gatewayProxy = bool("gatewayProxy"),
                coreArguments = arguments,
            )
        }
    }
}
