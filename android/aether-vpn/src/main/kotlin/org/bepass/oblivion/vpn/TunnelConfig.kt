package org.bepass.oblivion.vpn

data class TunnelConfig(
    val core: String,
    val psiphonCountry: String,
    val psiphonMode: String,
    val psiphonCdnIps: String,
    val psiphonCdnSni: String,
    val psiphonConduitPeers: String,
    val psiphonRejectCensoredPeers: Boolean,
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

    val runsAether: Boolean get() = !psiphonOnly

    val runsPsiphon: Boolean get() = psiphonOnly || usesChain

    val aetherSocksPort: Int
        get() = when {
            !usesChain -> socksPort
            socksPort + 11 <= 65535 -> socksPort + 10
            else -> socksPort - 10
        }

    val aetherHttpProxyPort: Int get() = aetherSocksPort + 1

    val aetherBindHost: String
        get() = if (allowLan && !usesChain) "0.0.0.0" else "127.0.0.1"

    val chainUpstreamUrl: String get() = "socks5://127.0.0.1:$aetherSocksPort"

    val bypassSelected: Boolean get() = splitTunnelMode == "bypassSelected"

    val usesZeroTrust: Boolean get() = team.isNotBlank()

    val usesGool: Boolean get() = protocol == "gool"

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

    val mtu: Int get() = tunnelMtu.coerceIn(1280, 9000)

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
        "trace", "debug" -> "debug"
        "info" -> "info"
        "warn" -> "warn"
        else -> "error"
    }

    companion object {
        const val CORE_AETHER = "aether"
        const val CORE_PSIPHON = "psiphon"
        const val CORE_CHAIN = "chain"

        const val TUN_MTU = 8500
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
