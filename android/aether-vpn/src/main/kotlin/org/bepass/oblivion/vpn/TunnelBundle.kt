package org.bepass.oblivion.vpn

import android.os.Bundle

object TunnelBundle {
    fun encode(config: TunnelConfig): Bundle = Bundle().apply {
        putString("core", config.core)
        putString("psiphonCountry", config.psiphonCountry)
        putString("psiphonMode", config.psiphonMode)
        putString("psiphonCdnIps", config.psiphonCdnIps)
        putString("psiphonCdnSni", config.psiphonCdnSni)
        putString("psiphonConduitPeers", config.psiphonConduitPeers)
        putBoolean("psiphonRejectCensoredPeers", config.psiphonRejectCensoredPeers)
        putString("protocol", config.protocol)
        putString("transport", config.transport)
        putString("scanMode", config.scanMode)
        putString("obfuscation", config.obfuscation)
        putString("noizeProfile", config.noizeProfile)
        putInt("tunnelMtu", config.tunnelMtu)
        putString("ipVersion", config.ipVersion)
        putString("logLevel", config.logLevel)
        putString("perfProfile", config.perfProfile)
        putString("endpoint", config.endpoint)
        putString("wiwOuter", config.wiwOuter)
        putString("wiwInner", config.wiwInner)
        putInt("socksPort", config.socksPort)
        putBoolean("allowLan", config.allowLan)
        putBoolean("proxyOnly", config.proxyOnly)
        putBoolean("fragment", config.fragment)
        putBoolean("quickReconnect", config.quickReconnect)
        putString("splitTunnelMode", config.splitTunnelMode)
        putStringArrayList("bypassedApps", ArrayList(config.bypassedApps))
        putString("routeBlock", config.routeBlock)
        putString("routeDirect", config.routeDirect)
        putString("dnsPrimary", config.dnsPrimary)
        putString("dnsSecondary", config.dnsSecondary)
        putString("team", config.team)
        putString("accessToken", config.accessToken)
        putString("accessId", config.accessId)
        putString("accessSecret", config.accessSecret)
        putBoolean("gatewayProxy", config.gatewayProxy)
        putStringArrayList("coreArguments", ArrayList(config.coreArguments))
    }

    fun decode(bundle: Bundle): TunnelConfig = TunnelConfig(
        core = bundle.getString("core", "aether"),
        psiphonCountry = bundle.getString("psiphonCountry", ""),
        psiphonMode = bundle.getString("psiphonMode", "auto"),
        psiphonCdnIps = bundle.getString("psiphonCdnIps", ""),
        psiphonCdnSni = bundle.getString("psiphonCdnSni", ""),
        psiphonConduitPeers = bundle.getString("psiphonConduitPeers", "auto"),
        psiphonRejectCensoredPeers = bundle.getBoolean("psiphonRejectCensoredPeers", true),
        protocol = bundle.getString("protocol", "masque"),
        transport = bundle.getString("transport", "h3"),
        scanMode = bundle.getString("scanMode", "balanced"),
        obfuscation = bundle.getString("obfuscation", "balanced"),
        noizeProfile = bundle.getString("noizeProfile", "balanced"),
        tunnelMtu = bundle.getInt("tunnelMtu", TunnelConfig.TUN_MTU),
        ipVersion = bundle.getString("ipVersion", "v4"),
        logLevel = bundle.getString("logLevel", "info"),
        perfProfile = bundle.getString("perfProfile", ""),
        endpoint = bundle.getString("endpoint", ""),
        wiwOuter = bundle.getString("wiwOuter", ""),
        wiwInner = bundle.getString("wiwInner", ""),
        socksPort = bundle.getInt("socksPort", 1819),
        allowLan = bundle.getBoolean("allowLan", false),
        proxyOnly = bundle.getBoolean("proxyOnly", false),
        fragment = bundle.getBoolean("fragment", false),
        quickReconnect = bundle.getBoolean("quickReconnect", true),
        splitTunnelMode = bundle.getString("splitTunnelMode", "disabled"),
        bypassedApps = bundle.getStringArrayList("bypassedApps") ?: emptyList(),
        routeBlock = bundle.getString("routeBlock", ""),
        routeDirect = bundle.getString("routeDirect", ""),
        dnsPrimary = bundle.getString("dnsPrimary", "1.1.1.1"),
        dnsSecondary = bundle.getString("dnsSecondary", "1.0.0.1"),
        team = bundle.getString("team", ""),
        accessToken = bundle.getString("accessToken", ""),
        accessId = bundle.getString("accessId", ""),
        accessSecret = bundle.getString("accessSecret", ""),
        gatewayProxy = bundle.getBoolean("gatewayProxy", false),
        coreArguments = bundle.getStringArrayList("coreArguments") ?: emptyList(),
    )
}
