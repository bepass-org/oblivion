package org.bepass.oblivion.vpn

import android.util.Base64
import java.io.File
import org.json.JSONArray
import org.json.JSONObject

object PsiphonConfig {

    const val MODE_AUTO = "auto"
    const val MODE_CDN = "cdn"
    const val MODE_CONDUIT = "conduit"
    const val MODE_DIRECT = "direct"

    private val CDN_PROTOCOLS = listOf(
        "FRONTED-MEEK-CDN-OSSH",
        "FRONTED-MEEK-CDN-HTTP-OSSH",
        "FRONTED-MEEK-CDN-QUIC-OSSH",
    )

    private val CONDUIT_PROTOCOLS = listOf(
        "INPROXY-WEBRTC-OSSH",
        "INPROXY-WEBRTC-TLS-OSSH",
        "INPROXY-WEBRTC-UNFRONTED-MEEK-OSSH",
        "INPROXY-WEBRTC-UNFRONTED-MEEK-HTTPS-OSSH",
        "INPROXY-WEBRTC-UNFRONTED-MEEK-SESSION-TICKET-OSSH",
        "INPROXY-WEBRTC-FRONTED-MEEK-OSSH",
        "INPROXY-WEBRTC-FRONTED-MEEK-HTTP-OSSH",
        "INPROXY-WEBRTC-QUIC-OSSH",
        "INPROXY-WEBRTC-SHADOWSOCKS-OSSH",
    )

    private val NON_INPROXY_PROTOCOLS = listOf(
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
    )

    private val CHAINED_PROTOCOLS = listOf(
        "SSH",
        "OSSH",
        "TLS-OSSH",
        "UNFRONTED-MEEK-OSSH",
        "UNFRONTED-MEEK-HTTPS-OSSH",
        "UNFRONTED-MEEK-SESSION-TICKET-OSSH",
        "SHADOWSOCKS-OSSH",
        "FRONTED-MEEK-OSSH",
        "FRONTED-MEEK-CDN-OSSH",
        "FRONTED-MEEK-HTTP-OSSH",
        "FRONTED-MEEK-CDN-HTTP-OSSH",
    )

    private val CENSORED_COUNTRY_CODES = listOf("IR", "CN", "RU", "TM", "BY", "MM")

    private const val PROPAGATION_CHANNEL_ID = "FFFFFFFFFFFFFFFF"
    private const val SPONSOR_ID = "FFFFFFFFFFFFFFFF"

    private const val SERVER_ENTRY_SIGNATURE_PUBLIC_KEY = ""

    val supportsInproxy: Boolean get() = SERVER_ENTRY_SIGNATURE_PUBLIC_KEY.isNotEmpty()

    private const val SERVER_LIST_URL =
        "https://s3.amazonaws.com//psiphon/web/mjr4-p23r-puwl/server_list_compressed"

    private const val SERVER_LIST_SIGNATURE_KEY =
        "MIICIDANBgkqhkiG9w0BAQEFAAOCAg0AMIICCAKCAgEAt7Ls+/39r+T6zNW7GiVpJfzq/xvL9SBH" +
            "5rIFnk0RXYEYavax3WS6HOD35eTAqn8AniOwiH+DOkvgSKF2caqk/y1dfq47Pdymtwzp9ikpB1C5" +
            "OfAysXzBiwVJlCdajBKvBZDerV1cMvRzCKvKwRmvDmHgphQQ7WfXIGbRbmmk6opMBh3roE42Kcot" +
            "LFtqp0RRwLtcBRNtCdsrVsjiI1Lqz/lH+T61sGjSjQ3CHMuZYSQJZo/KrvzgQXpkaCTdbObxHqb6" +
            "/+i1qaVOfEsvjoiyzTxJADvSytVtcTjijhPEV6XskJVHE1Zgl+7rATr/pDQkw6DPCNBS1+Y6fy7G" +
            "stZALQXwEDN/qhQI9kWkHijT8ns+i1vGg00Mk/6J75arLhqcodWsdeG/M/moWgqQAnlZAGVtJI1O" +
            "geF5fsPpXu4kctOfuZlGjVZXQNW34aOzm8r8S0eVZitPlbhcPiR4gT/aSMz/wd8lZlzZYsje/Jr8" +
            "u/YtlwjjreZrGRmG8KMOzukV3lLmMppXFMvl4bxv6YFEmIuTsOhbLTwFgh7KYNjodLj/LsqRVfwz" +
            "31PgWQFTEPICV7GCvgVlPRxnofqKSjgTWI4mxDhBpVcATvaoBl1L/6WLbFvBsoAUBItWwctO2xal" +
            "KxF5szhGm8lccoc5MZr8kfE0uxMgsxz4er68iCID+rsCAQM="

    fun chainedProtocols(selected: String): List<String> {
        fun carriesUdp(name: String) = name.contains("QUIC") || name.startsWith("INPROXY")

        return when (selected) {
            MODE_CDN -> CDN_PROTOCOLS.filterNot(::carriesUdp)
            MODE_DIRECT -> CHAINED_PROTOCOLS.filterNot { it.startsWith("FRONTED") }
            else -> CHAINED_PROTOCOLS
        }
    }

    fun chainedMode(raw: String): String = when (val selected = mode(raw)) {
        MODE_CONDUIT -> MODE_AUTO
        else -> selected
    }

    fun mode(raw: String): String = when (raw.trim()) {
        MODE_CDN -> MODE_CDN
        MODE_CONDUIT -> MODE_CONDUIT
        MODE_DIRECT -> MODE_DIRECT
        else -> MODE_AUTO
    }

    fun build(target: TunnelConfig, dataDirectory: File): String {
        val config = JSONObject()

        config.put("PropagationChannelId", PROPAGATION_CHANNEL_ID)
        config.put("SponsorId", SPONSOR_ID)
        config.put("ClientVersion", "1")
        config.put("DataRootDirectory", dataDirectory.absolutePath)

        config.put("LocalSocksProxyPort", target.socksPort)
        config.put("LocalHttpProxyPort", target.httpProxyPort)
        if (target.allowLan) {
            config.put("ListenInterface", "any")
        }

        config.put("EmitDiagnosticNotices", true)
        config.put("EmitDiagnosticNetworkParameters", true)
        config.put("EmitServerAlerts", true)

        val region = target.psiphonCountry.trim().uppercase()
        if (region.isNotEmpty()) {
            config.put("EgressRegion", region)
        }

        config.put(
            "RemoteServerListURLs",
            JSONArray().put(
                JSONObject().put(
                    "URL",
                    Base64.encodeToString(SERVER_LIST_URL.toByteArray(), Base64.NO_WRAP),
                ),
            ),
        )
        config.put("RemoteServerListSignaturePublicKey", SERVER_LIST_SIGNATURE_KEY)

        if (supportsInproxy) {
            config.put("ServerEntrySignaturePublicKey", SERVER_ENTRY_SIGNATURE_PUBLIC_KEY)
        }

        val chained = target.usesChain
        val selected = if (chained) chainedMode(target.psiphonMode) else mode(target.psiphonMode)

        if (chained) {
            config.put("UpstreamProxyURL", target.chainUpstreamUrl)
        }

        if (selected == MODE_CONDUIT && !supportsInproxy) {
            throw IllegalStateException(
                "conduit mode needs a server entry signature public key that this build " +
                    "does not embed, pick auto, cdn or direct instead",
            )
        }

        if (selected != MODE_CONDUIT) {
            putCdnFronting(config, target)
        }

        if (!supportsInproxy) {
            config.put("InproxyTunnelProtocolPreferProbability", 0.0)
            config.put("InproxyTunnelProtocolSelectionProbability", 0.0)
        }

        if (chained) {
            config.put("LimitTunnelProtocols", JSONArray(chainedProtocols(selected)))
            if (selected != MODE_AUTO) config.put("DisableTactics", true)
            return config.toString()
        }

        when (selected) {
            MODE_AUTO -> {
                if (!supportsInproxy) {
                    config.put("LimitTunnelProtocols", JSONArray(NON_INPROXY_PROTOCOLS))
                }
            }

            MODE_CDN -> {
                config.put("LimitTunnelProtocols", JSONArray(CDN_PROTOCOLS))
                config.put("DisableTactics", true)
            }

            MODE_DIRECT -> {
                config.put("LimitTunnelProtocols", JSONArray(NON_INPROXY_PROTOCOLS))
                config.put("DisableTactics", true)
            }

            MODE_CONDUIT -> {
                config.put("LimitTunnelProtocols", JSONArray(CONDUIT_PROTOCOLS))
                if (target.psiphonRejectCensoredPeers) {
                    config.put(
                        "InproxyRejectProxyCountryCodes",
                        JSONArray(CENSORED_COUNTRY_CODES),
                    )
                }
            }
        }

        return config.toString()
    }

    private fun putCdnFronting(config: JSONObject, target: TunnelConfig) {
        val addresses = ipCandidates(target.psiphonCdnIps)
        val serverNames = sniCandidates(target.psiphonCdnSni)

        if (addresses.isEmpty()) {
            config.put("FrontedMeekCDNScanUseBuiltInSpec", true)
        } else {
            val spec = JSONObject().put("IPCandidates", JSONArray(addresses))
            if (serverNames.isNotEmpty()) {
                spec.put("SNIServerNames", JSONArray(serverNames))
            }
            config.put("FrontedMeekCDNScanSpec", spec)
        }

        val dialAddresses = addresses.ifEmpty { serverNames }
        if (dialAddresses.isEmpty() || serverNames.isEmpty()) return

        val override = JSONObject().apply {
            put("OverrideID", "user")
            put("MatchDialAddressRegexes", JSONArray(listOf(".*")))
            put("DialAddresses", JSONArray(dialAddresses))
            put("SNIServerName", serverNames.first())
            put("VerifyServerNames", JSONArray(serverNames))
        }
        config.put("FrontedMeekDialOverrides", JSONArray().put(override))
    }

    private val SEPARATORS = charArrayOf(' ', '\t', '\n', '\r', ',', ';')

    fun ipCandidates(raw: String): List<String> = raw.split(*SEPARATORS)
        .map { it.trim() }
        .filter { it.isNotEmpty() && (isIpv4(it) || isIpv4Cidr(it)) }
        .distinct()

    fun sniCandidates(raw: String): List<String> = raw.split(*SEPARATORS)
        .map { normalizeHostname(it) }
        .filter { it.isNotEmpty() }
        .distinct()

    private fun isIpv4(value: String): Boolean {
        val parts = value.split('.')
        if (parts.size != 4) return false
        return parts.all { part ->
            part.isNotEmpty() &&
                part.length <= 3 &&
                part.all { it.isDigit() } &&
                (part.toIntOrNull() ?: 256) <= 255
        }
    }

    private fun isIpv4Cidr(value: String): Boolean {
        val parts = value.split('/')
        if (parts.size != 2) return false
        val prefix = parts[1]
        return isIpv4(parts[0]) &&
            prefix.isNotEmpty() &&
            prefix.all { it.isDigit() } &&
            (prefix.toIntOrNull() ?: 33) <= 32
    }

    private fun normalizeHostname(raw: String): String {
        var value = raw.trim().lowercase()
        for (prefix in listOf("https://", "http://")) {
            value = value.removePrefix(prefix)
        }
        value = value.substringBefore('/').trim('.')

        if (value.isEmpty() || !value.contains('.')) return ""
        if (value.any { it.code > 127 || !(it.isLetterOrDigit() || it == '.' || it == '-') }) {
            return ""
        }
        return value
    }
}
