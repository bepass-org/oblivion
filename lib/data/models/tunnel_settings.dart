import 'dart:io';

enum CoreEngine {
  aether('aether'),
  psiphon('psiphon'),
  chain('chain'),
  psiphonReverse('psiphon-reverse'),
  tor('tor'),
  torChain('tor-chain'),
  torReverse('tor-reverse');

  const CoreEngine(this.wire);

  final String wire;

  static CoreEngine fromWire(String? value) =>
      values.firstWhere((e) => e.wire == value, orElse: () => aether);

  static CoreEngine migrate(String? core, String? legacyTorMode) =>
      switch (legacyTorMode?.trim().toLowerCase()) {
        'only' => tor,
        'chain' => torChain,
        'reverse' => torReverse,
        _ => fromWire(core),
      };
}

enum PsiphonMode {
  auto('auto'),
  cdn('cdn'),
  conduit('conduit'),
  direct('direct');

  const PsiphonMode(this.wire);

  final String wire;

  static PsiphonMode fromWire(String? value) {
    if (value == 'conduit') return auto;
    return values.firstWhere((e) => e.wire == value, orElse: () => auto);
  }
}

enum ConduitPeers {
  auto('auto'),
  private('private'),
  public('public');

  const ConduitPeers(this.wire);

  final String wire;

  static ConduitPeers fromWire(String? value) =>
      values.firstWhere((e) => e.wire == value, orElse: () => auto);
}

const psiphonCdnSetNames = <String>[
  'cloudflare',
  'fastly',
  'cloudfront',
  'psiphon-akamai',
  'psiphon-bunny',
  'vercel',
  'github',
  'curated-fronting',
  'legacy-android-overrides',
];

const psiphonCountries = <String>[
  'AT',
  'AU',
  'BE',
  'BG',
  'CA',
  'CH',
  'CZ',
  'DE',
  'DK',
  'EE',
  'ES',
  'FI',
  'FR',
  'GB',
  'HR',
  'HU',
  'IE',
  'IN',
  'IT',
  'JP',
  'LV',
  'NL',
  'NO',
  'PL',
  'PT',
  'RO',
  'RS',
  'SE',
  'SG',
  'SK',
  'US',
];

enum TorRelays {
  auto('auto'),
  only('only'),
  off('off');

  const TorRelays(this.wire);

  final String wire;

  static TorRelays fromWire(String? value) =>
      values.firstWhere((e) => e.wire == value, orElse: () => auto);
}

enum TorBridges {
  auto('auto'),
  first('first'),
  never('never'),
  own('own');

  const TorBridges(this.wire);

  final String wire;

  static TorBridges fromWire(String? value) =>
      values.firstWhere((e) => e.wire == value, orElse: () => auto);
}

enum TlsFingerprint {
  chrome('chrome', 'ALL:!aPSK:!ECDSA+SHA1:!3DES', true),
  firefox(
    'firefox',
    'ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:'
        'ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:'
        'ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:'
        'ECDHE-RSA-AES128-SHA:ECDHE-RSA-AES256-SHA:'
        'AES128-GCM-SHA256:AES256-GCM-SHA384:AES128-SHA:AES256-SHA',
    false,
  ),
  semiPython(
    'semi-python',
    'ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:'
        'ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:'
        'ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:'
        'ECDHE-ECDSA-AES256-SHA:ECDHE-RSA-AES256-SHA:'
        'ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA256',
    false,
  ),
  go(
    'go',
    'ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:'
        'ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:'
        'ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:'
        'ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES128-SHA:'
        'ECDHE-ECDSA-AES256-SHA:ECDHE-RSA-AES256-SHA',
    false,
  ),
  custom('custom', '', true);

  const TlsFingerprint(this.wire, this.ciphers, this.grease);

  final String wire;
  final String ciphers;
  final bool grease;

  static TlsFingerprint fromWire(String? value) =>
      values.firstWhere((e) => e.wire == value, orElse: () => chrome);
}

enum CoreProtocol {
  masque('masque'),
  wireguard('wg'),
  gool('gool'),
  goolClassic('gool-classic'),
  mim('mim');

  const CoreProtocol(this.wire);

  final String wire;

  static CoreProtocol fromWire(String? value) =>
      values.firstWhere((e) => e.wire == value, orElse: () => masque);
}

enum WarpKeyKind {
  all('all'),
  masque('masque'),
  wireguard('wg'),
  gool('gool'),
  goolClassic('gool-classic'),
  mim('mim');

  const WarpKeyKind(this.wire);

  final String wire;

  static WarpKeyKind of(CoreProtocol protocol) => switch (protocol) {
    CoreProtocol.masque => masque,
    CoreProtocol.wireguard => wireguard,
    CoreProtocol.gool => gool,
    CoreProtocol.goolClassic => goolClassic,
    CoreProtocol.mim => mim,
  };
}

class GatewayScan {
  const GatewayScan(this.endpoint, [this.inner]);

  final String endpoint;
  final String? inner;

  @override
  bool operator ==(Object other) =>
      other is GatewayScan &&
      other.endpoint == endpoint &&
      other.inner == inner;

  @override
  int get hashCode => Object.hash(endpoint, inner);

  @override
  String toString() => inner == null ? endpoint : '$endpoint → $inner';
}

enum MasqueTransport {
  http3('h3'),
  http2('h2');

  const MasqueTransport(this.wire);

  final String wire;

  static MasqueTransport fromWire(String? value) =>
      values.firstWhere((e) => e.wire == value, orElse: () => http3);
}

enum ScanMode {
  turbo('turbo'),
  balanced('balanced'),
  thorough('thorough'),
  verified('verified'),
  ironclad('ironclad');

  const ScanMode(this.wire);

  final String wire;

  static ScanMode fromWire(String? value) {
    if (value == 'stealth') return verified;
    return values.firstWhere((e) => e.wire == value, orElse: () => balanced);
  }
}

enum ObfuscationProfile {
  auto('auto'),
  off('off'),
  light('light'),
  firewall('firewall'),
  balanced('balanced'),
  gfw('gfw'),
  aggressive('aggressive');

  const ObfuscationProfile(this.wire);

  final String wire;

  static ObfuscationProfile fromWire(String? value) =>
      values.firstWhere((e) => e.wire == value, orElse: () => balanced);
}

enum IpVersion {
  v4('v4'),
  v6('v6'),
  dual('both');

  const IpVersion(this.wire);

  final String wire;

  static IpVersion fromWire(String? value) =>
      values.firstWhere((e) => e.wire == value, orElse: () => v4);
}

enum CoreLogLevel {
  error('error'),
  warn('warn'),
  info('info'),
  debug('debug'),
  trace('trace');

  const CoreLogLevel(this.wire);

  final String wire;

  static CoreLogLevel fromWire(String? value) =>
      values.firstWhere((e) => e.wire == value, orElse: () => info);
}

enum PerfProfile {
  auto(''),
  low('low'),
  medium('medium'),
  high('high');

  const PerfProfile(this.wire);

  final String wire;

  static PerfProfile fromWire(String? value) =>
      values.firstWhere((e) => e.wire == value, orElse: () => auto);
}

enum EchMode {
  off(''),
  auto('auto');

  const EchMode(this.wire);

  final String wire;

  static EchMode fromWire(String? value) =>
      values.firstWhere((e) => e.wire == value, orElse: () => off);
}

enum RoutingMode {
  socksOnly('socks'),
  systemProxy('system'),
  fullTunnel('tunnel');

  const RoutingMode(this.wire);

  final String wire;

  bool get needsPrivileges => this == fullTunnel;

  static RoutingMode fromWire(String? value) =>
      values.firstWhere((e) => e.wire == value, orElse: () => fullTunnel);
}

enum SplitTunnelMode {
  disabled,
  bypassSelected,
  onlySelected;

  bool get picksApps => this != disabled;

  static SplitTunnelMode fromName(String? value) =>
      values.firstWhere((e) => e.name == value, orElse: () => disabled);
}

class TunnelSettings {
  const TunnelSettings({
    this.core = CoreEngine.aether,
    this.psiphonCountry = '',
    this.psiphonMode = PsiphonMode.auto,
    this.psiphonCdnIps = '',
    this.psiphonCdnSni = '',
    this.psiphonCdnSets = const <String>{},
    this.psiphonConduitPeers = ConduitPeers.auto,
    this.psiphonRejectCensoredPeers = true,
    this.psiphonBundledList = true,
    this.torRelays = TorRelays.auto,
    this.torBridges = TorBridges.auto,
    this.torBridgeLines = '',
    this.exitLoc = '',
    this.protocol = CoreProtocol.masque,
    this.transport = MasqueTransport.http3,
    this.scanMode = ScanMode.balanced,
    this.obfuscation = ObfuscationProfile.balanced,
    this.ipVersion = IpVersion.v4,
    this.logLevel = CoreLogLevel.info,
    this.perfProfile = PerfProfile.auto,
    this.echMode = EchMode.off,
    this.splitTunnelMode = SplitTunnelMode.disabled,
    this.bypassedApps = const <String>{},
    this.endpoint = '',
    this.wgEndpoint = '',
    this.h2Endpoint = '',
    this.wiwOuter = '',
    this.wiwInner = '',
    this.goolPeer = '',
    this.mimInner = '',
    this.masqueSni = '',
    this.echDns = '',
    this.echDomain = '',
    this.tlsGroups = '',
    this.tlsFingerprint = TlsFingerprint.chrome,
    this.tlsCiphers = '',
    this.grease = true,
    this.apiAddress = '',
    this.socksPort = 1819,
    this.allowLan = false,
    this.routingMode = RoutingMode.fullTunnel,
    this.tunnelInterface = 'oblivion0',
    this.tunnelMtu = 8500,
    this.coreMtu = 0,
    this.pathMtu = 0,
    this.overrideDns = true,
    this.dnsPrimary = '1.1.1.1',
    this.dnsSecondary = '1.0.0.1',
    this.fragment = false,
    this.fragmentSize = '8-16',
    this.fragmentDelay = '2-10',
    this.quickReconnect = true,
    this.fastFirstConnect = true,
    this.dataCheck = true,
    this.validateSeconds = 10,
    this.reconnectSeconds = 2,
    this.wgKeepalive = 5,
    this.wgProfileRetry = true,
    this.routeBlock = '',
    this.routeDirect = '',
    this.team = '',
    this.accessToken = '',
    this.accessId = '',
    this.accessSecret = '',
    this.accessEmail = '',
    this.gatewayProxy = false,
  });

  final CoreEngine core;
  final String psiphonCountry;
  final PsiphonMode psiphonMode;
  final String psiphonCdnIps;
  final String psiphonCdnSni;
  final Set<String> psiphonCdnSets;
  final ConduitPeers psiphonConduitPeers;
  final bool psiphonRejectCensoredPeers;
  final bool psiphonBundledList;

  final TorRelays torRelays;
  final TorBridges torBridges;
  final String torBridgeLines;
  final String exitLoc;

  final CoreProtocol protocol;
  final MasqueTransport transport;
  final ScanMode scanMode;
  final ObfuscationProfile obfuscation;
  final IpVersion ipVersion;
  final CoreLogLevel logLevel;
  final PerfProfile perfProfile;
  final EchMode echMode;
  final SplitTunnelMode splitTunnelMode;
  final Set<String> bypassedApps;

  final String endpoint;
  final String wgEndpoint;
  final String h2Endpoint;
  final String wiwOuter;
  final String wiwInner;
  final String goolPeer;
  final String mimInner;
  final String masqueSni;
  final String echDns;
  final String echDomain;
  final String tlsGroups;
  final TlsFingerprint tlsFingerprint;
  final String tlsCiphers;
  final bool grease;
  final String apiAddress;

  final int socksPort;
  final bool allowLan;
  final RoutingMode routingMode;
  final String tunnelInterface;
  final int tunnelMtu;
  final int coreMtu;
  final int pathMtu;
  final bool overrideDns;
  final String dnsPrimary;
  final String dnsSecondary;

  final bool fragment;
  final String fragmentSize;
  final String fragmentDelay;

  final bool quickReconnect;
  final bool fastFirstConnect;
  final bool dataCheck;
  final int validateSeconds;
  final int reconnectSeconds;

  final int wgKeepalive;
  final bool wgProfileRetry;

  final String routeBlock;
  final String routeDirect;

  final String team;
  final String accessToken;
  final String accessId;
  final String accessSecret;
  final String accessEmail;
  final bool gatewayProxy;

  bool get splitTunnelActive => splitTunnelMode.picksApps;

  bool get splitTunnelStarved =>
      splitTunnelMode == SplitTunnelMode.onlySelected && bypassedApps.isEmpty;

  bool get usesChain => core == CoreEngine.chain;

  bool get psiphonReverse => core == CoreEngine.psiphonReverse;

  bool get psiphonOnly => core == CoreEngine.psiphon;

  bool get usesPsiphon => psiphonOnly || usesChain || psiphonReverse;

  bool get torOnly => core == CoreEngine.tor;

  bool get torChain => core == CoreEngine.torChain;

  bool get torReverse => core == CoreEngine.torReverse;

  bool get usesTor => torOnly || torChain || torReverse;

  bool get usesAether => !psiphonOnly && !torOnly;

  bool get carriesInside => usesChain || torChain;

  bool get dialsThrough => psiphonReverse || torReverse;

  bool get exitIsWarp => usesAether && !carriesInside;

  int get _chainPortShift => socksPort + 11 <= 65535 ? 10 : -10;

  int get aetherSocksPort =>
      carriesInside ? socksPort + _chainPortShift : socksPort;

  int get aetherHttpProxyPort => aetherSocksPort + 1;

  String get aetherBindAddress =>
      '${allowLan && !carriesInside ? '0.0.0.0' : '127.0.0.1'}:$aetherSocksPort';

  String get aetherHttpProxyAddress =>
      '${allowLan && !carriesInside ? '0.0.0.0' : '127.0.0.1'}:$aetherHttpProxyPort';

  String get chainUpstreamUrl => 'socks5://127.0.0.1:$aetherSocksPort';

  bool get psiphonUsesCdnFronting => psiphonMode != PsiphonMode.conduit;

  bool get psiphonUsesConduit => psiphonMode == PsiphonMode.conduit;

  static bool needsUdpToWarp(CoreProtocol value) =>
      value == CoreProtocol.wireguard || value == CoreProtocol.goolClassic;

  CoreProtocol get effectiveProtocol =>
      dialsThrough && needsUdpToWarp(protocol) ? CoreProtocol.masque : protocol;

  bool get isMasque =>
      effectiveProtocol == CoreProtocol.masque ||
      effectiveProtocol == CoreProtocol.mim ||
      effectiveProtocol == CoreProtocol.gool;

  bool get usesMim => effectiveProtocol == CoreProtocol.mim;

  String get modeLabel {
    final String carrier = switch (effectiveProtocol) {
      CoreProtocol.masque => usesHttp2 ? 'MASQUE H2' : 'MASQUE H3',
      CoreProtocol.mim => usesHttp2 ? 'MIM H2' : 'MIM H3',
      CoreProtocol.gool => usesHttp2 ? 'GOOL H2' : 'GOOL H3',
      CoreProtocol.goolClassic => 'GOOL CLASSIC',
      CoreProtocol.wireguard => 'WARP',
    };

    return switch (core) {
      CoreEngine.aether => carrier,
      CoreEngine.psiphon => 'PSIPHON',
      CoreEngine.chain => '$carrier + PSIPHON',
      CoreEngine.psiphonReverse => 'PSIPHON + $carrier',
      CoreEngine.tor => 'TOR',
      CoreEngine.torChain => '$carrier + TOR',
      CoreEngine.torReverse => 'TOR + $carrier',
    };
  }

  String get teamName => team.trim();

  bool get usesZeroTrust => teamName.isNotEmpty;

  bool get hasServiceToken =>
      accessId.trim().isNotEmpty && accessSecret.trim().isNotEmpty;

  bool get hasAccessToken => accessToken.trim().isNotEmpty;

  bool get hasAccessEmail => accessEmail.trim().isNotEmpty;

  bool get signsInByEmail =>
      usesZeroTrust && hasAccessEmail && !hasAccessToken && !hasServiceToken;

  bool get zeroTrustReady =>
      usesZeroTrust && (hasAccessToken || hasServiceToken || hasAccessEmail);

  bool get usesHttp2 =>
      isMasque && (dialsThrough || transport == MasqueTransport.http2);

  bool get usesWireGuard =>
      effectiveProtocol == CoreProtocol.wireguard ||
      effectiveProtocol == CoreProtocol.goolClassic;

  bool get usesGool => effectiveProtocol == CoreProtocol.gool;

  bool get usesGoolClassic => effectiveProtocol == CoreProtocol.goolClassic;

  String get goolPeerValue => goolPeer.trim();

  String get mimInnerValue => mimInner.trim();

  bool get mimHopsCollide {
    final outer = endpointHost(manualGateway);
    final inner = endpointHost(mimInnerValue);
    if (outer == null || inner == null) return false;
    return outer == inner;
  }

  bool get obfuscationAuto => obfuscation == ObfuscationProfile.auto;

  String get effectiveTlsCiphers => tlsFingerprint == TlsFingerprint.custom
      ? tlsCiphers.trim()
      : tlsFingerprint.ciphers;

  bool get effectiveGrease =>
      tlsFingerprint == TlsFingerprint.custom ? grease : tlsFingerprint.grease;

  List<String> get torBridgeLineList => bridgeLines(torBridgeLines);

  bool get torBridgesMissing =>
      torBridges == TorBridges.own && torBridgeLineList.isEmpty;

  String get torBridgesValue => switch (torBridges) {
    TorBridges.auto => '',
    TorBridges.first => 'auto',
    TorBridges.never => 'off',
    TorBridges.own => torBridgeLineList.join(';'),
  };

  static List<String> bridgeLines(String raw) => raw
      .split('\n')
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty && !line.startsWith('#'))
      .map(
        (line) => line.startsWith('Bridge ') || line.startsWith('bridge ')
            ? line.substring('Bridge '.length).trim()
            : line,
      )
      .where((line) => line.isNotEmpty && !line.contains(';'))
      .toList();

  static final RegExp _exitRule = RegExp(r'^!?[A-Z]{2}(,[A-Z]{2})*$');

  static String normalizeExitRule(String value) =>
      value.replaceAll(RegExp(r'\s'), '').toUpperCase();

  static bool isExitRule(String value) {
    final rule = normalizeExitRule(value);
    return rule.isEmpty || _exitRule.hasMatch(rule);
  }

  static const String defaultMasqueSni = 'www.cloudflare.com';

  static const String warpMasqueSni = 'consumer-masque.cloudflareclient.com';

  static const List<String> masqueSniPresets = <String>[
    defaultMasqueSni,
    warpMasqueSni,
  ];

  String get masqueServerName {
    final chosen = masqueSni.trim();
    return chosen.isEmpty ? defaultMasqueSni : chosen;
  }

  bool get masqueSniCustom => !masqueSniPresets.contains(masqueServerName);

  bool get usesEch => echMode != EchMode.off;

  List<String> get psiphonCdnSetList => <String>[
    for (final name in psiphonCdnSetNames)
      if (psiphonCdnSets.contains(name)) name,
  ];

  String get wiwOuterPeer => wiwOuter.trim();

  String get wiwInnerPeer => wiwInner.trim();

  bool get wiwHopsCollide {
    final outer = endpointHost(wiwOuterPeer);
    final inner = endpointHost(wiwInnerPeer);
    if (outer == null || inner == null) return false;
    return outer == inner;
  }

  bool get wiwPinned => wiwOuterPeer.isNotEmpty || wiwInnerPeer.isNotEmpty;

  static String? endpointHost(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;

    String host;
    String port;

    if (trimmed.startsWith('[')) {
      final close = trimmed.indexOf(']');
      if (close < 0 || !trimmed.startsWith(':', close + 1)) return null;
      host = trimmed.substring(1, close);
      port = trimmed.substring(close + 2);
    } else {
      final separator = trimmed.lastIndexOf(':');
      if (separator <= 0) return null;
      host = trimmed.substring(0, separator);
      port = trimmed.substring(separator + 1);
      if (host.contains(':')) return null;
    }

    if (port.isEmpty ||
        port.length > 5 ||
        !port.codeUnits.every((unit) => unit >= 0x30 && unit <= 0x39)) {
      return null;
    }

    final parsedPort = int.parse(port);
    if (parsedPort < 1 || parsedPort > 65535) return null;

    final address = InternetAddress.tryParse(host);
    if (address == null) return null;
    return address.address;
  }

  static bool isValidEndpoint(String value) => endpointHost(value) != null;

  static final RegExp rangePattern = RegExp(r'^\d{1,5}(-\d{1,5})?$');

  static bool isValidRange(String value) {
    final trimmed = value.trim();
    if (!rangePattern.hasMatch(trimmed)) return false;
    final parts = trimmed.split('-').map(int.parse).toList();
    if (parts.any((part) => part <= 0)) return false;
    if (parts.length == 2 && parts[1] < parts[0]) return false;
    return true;
  }

  static final RegExp _domainLabel = RegExp(r'^[A-Za-z0-9_-]{1,63}$');

  static final RegExp _cipherList = RegExp(r'^[A-Za-z0-9_+!:,.=@ -]+$');

  static String _stripTrailingDot(String value) =>
      value.endsWith('.') ? value.substring(0, value.length - 1) : value;

  static String _stripBrackets(String value) =>
      value.length > 1 && value.startsWith('[') && value.endsWith(']')
      ? value.substring(1, value.length - 1)
      : value;

  static bool _isIpAddress(String value) =>
      InternetAddress.tryParse(value) != null;

  static int? _digitsPort(String text) {
    if (text.isEmpty ||
        text.length > 5 ||
        !text.codeUnits.every((unit) => unit >= 0x30 && unit <= 0x39)) {
      return null;
    }
    final port = int.parse(text);
    return port >= 1 && port <= 65535 ? port : null;
  }

  static bool isDomainName(String value) {
    final name = _stripTrailingDot(value);
    if (name.isEmpty || name.length > 253) return false;
    return name.split('.').every(_domainLabel.hasMatch);
  }

  static bool isServerName(String value) {
    final name = _stripTrailingDot(value.trim());
    if (name.isEmpty || name.endsWith('.') || _isIpAddress(name)) return false;
    return isDomainName(name);
  }

  static bool _isHostAddress(String value) =>
      _isIpAddress(_stripBrackets(value)) || isDomainName(value);

  static bool isApiAddress(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return false;
    if (_isHostAddress(trimmed)) return true;

    final separator = trimmed.lastIndexOf(':');
    if (separator <= 0) return false;
    final host = trimmed.substring(0, separator);
    final port = trimmed.substring(separator + 1);
    if (host.contains(':') && !host.startsWith('[')) return false;
    final digits = port.startsWith('+') ? port.substring(1) : port;
    if (_digitsPort(digits) == null) return false;
    return _isHostAddress(host);
  }

  static bool _isSocketAddress(String text) {
    if (_isIpAddress(text)) return true;

    if (text.startsWith('[') && text.endsWith(']')) {
      return InternetAddress.tryParse(_stripBrackets(text))?.type ==
          InternetAddressType.IPv6;
    }

    final separator = text.lastIndexOf(':');
    if (separator <= 0) return false;
    final host = text.substring(0, separator);
    if (_digitsPort(text.substring(separator + 1)) == null) return false;

    if (host.startsWith('[') && host.endsWith(']')) {
      return InternetAddress.tryParse(_stripBrackets(host))?.type ==
          InternetAddressType.IPv6;
    }
    return InternetAddress.tryParse(host)?.type == InternetAddressType.IPv4;
  }

  static bool _isDohEndpoint(String value) {
    final pieces = value.split('@');
    final url = pieces.first.trim();
    final host = url.substring('https://'.length).split(RegExp('[/?#]')).first;
    if (host.isEmpty) return false;

    final named = <String>{};
    for (final piece in pieces.skip(1)) {
      final split = piece.indexOf('=');
      if (split < 0) return false;
      final name = piece.substring(0, split).trim().toLowerCase();
      final setting = piece.substring(split + 1).trim();
      if (!named.add(name)) return false;

      switch (name) {
        case 'address':
          if (!_isHostAddress(setting)) return false;
        case 'sni':
          if (_isIpAddress(_stripBrackets(setting)) || !isDomainName(setting)) {
            return false;
          }
        default:
          return false;
      }
    }
    return true;
  }

  static bool isEchResolver(String value) {
    final trimmed = value.trim();
    final lower = trimmed.toLowerCase();

    if (lower.startsWith('https://')) return _isDohEndpoint(trimmed);
    if (!lower.startsWith('udp://') && !lower.startsWith('tcp://')) {
      return false;
    }

    var rest = trimmed.substring('udp://'.length);
    while (rest.endsWith('/')) {
      rest = rest.substring(0, rest.length - 1);
    }
    return rest.isNotEmpty && _isSocketAddress(rest);
  }

  static bool isCipherList(String value) {
    final trimmed = value.trim();
    if (!_cipherList.hasMatch(trimmed)) return false;
    return trimmed
        .split(RegExp('[:, ]+'))
        .any((entry) => entry.trim().isNotEmpty);
  }

  String get noizeProfile => obfuscation.wire;

  String get bindAddress => '${allowLan ? '0.0.0.0' : '127.0.0.1'}:$socksPort';

  int get httpProxyPort => socksPort + 1;

  String get httpProxyAddress =>
      '${allowLan ? '0.0.0.0' : '127.0.0.1'}:$httpProxyPort';

  int get effectiveCoreMtu {
    if (coreMtu >= 576 && coreMtu <= 1500) return coreMtu;
    if (tunnelMtu >= 576 && tunnelMtu <= 1500) return tunnelMtu;
    return 0;
  }

  bool get proxyOnly => routingMode != RoutingMode.fullTunnel;

  bool get tunnelMode => routingMode == RoutingMode.fullTunnel;

  bool get systemProxy => routingMode == RoutingMode.systemProxy;

  String get manualGateway => endpoint.trim();

  bool get scannerBypassed => manualGateway.isNotEmpty;

  int? get bypassUid {
    if (!Platform.isLinux && !Platform.isMacOS) return null;
    final override = int.tryParse(
      Platform.environment['OBLIVION_BYPASS_UID'] ?? '',
    );
    if (override != null && override >= 0) return override;
    return null;
  }

  TunnelSettings copyWith({
    CoreEngine? core,
    String? psiphonCountry,
    PsiphonMode? psiphonMode,
    String? psiphonCdnIps,
    String? psiphonCdnSni,
    Set<String>? psiphonCdnSets,
    ConduitPeers? psiphonConduitPeers,
    bool? psiphonRejectCensoredPeers,
    bool? psiphonBundledList,
    TorRelays? torRelays,
    TorBridges? torBridges,
    String? torBridgeLines,
    String? exitLoc,
    CoreProtocol? protocol,
    MasqueTransport? transport,
    ScanMode? scanMode,
    ObfuscationProfile? obfuscation,
    IpVersion? ipVersion,
    CoreLogLevel? logLevel,
    PerfProfile? perfProfile,
    EchMode? echMode,
    SplitTunnelMode? splitTunnelMode,
    Set<String>? bypassedApps,
    String? endpoint,
    String? wgEndpoint,
    String? h2Endpoint,
    String? wiwOuter,
    String? wiwInner,
    String? goolPeer,
    String? mimInner,
    String? masqueSni,
    String? echDns,
    String? echDomain,
    String? tlsGroups,
    TlsFingerprint? tlsFingerprint,
    String? tlsCiphers,
    bool? grease,
    String? apiAddress,
    int? socksPort,
    bool? allowLan,
    RoutingMode? routingMode,
    String? tunnelInterface,
    int? tunnelMtu,
    int? coreMtu,
    int? pathMtu,
    bool? overrideDns,
    String? dnsPrimary,
    String? dnsSecondary,
    bool? fragment,
    String? fragmentSize,
    String? fragmentDelay,
    bool? quickReconnect,
    bool? fastFirstConnect,
    bool? dataCheck,
    int? validateSeconds,
    int? reconnectSeconds,
    int? wgKeepalive,
    bool? wgProfileRetry,
    String? routeBlock,
    String? routeDirect,
    String? team,
    String? accessToken,
    String? accessId,
    String? accessSecret,
    String? accessEmail,
    bool? gatewayProxy,
  }) {
    return TunnelSettings(
      core: core ?? this.core,
      psiphonCountry: psiphonCountry ?? this.psiphonCountry,
      psiphonMode: psiphonMode ?? this.psiphonMode,
      psiphonCdnIps: psiphonCdnIps ?? this.psiphonCdnIps,
      psiphonCdnSni: psiphonCdnSni ?? this.psiphonCdnSni,
      psiphonCdnSets: psiphonCdnSets ?? this.psiphonCdnSets,
      psiphonConduitPeers: psiphonConduitPeers ?? this.psiphonConduitPeers,
      psiphonRejectCensoredPeers:
          psiphonRejectCensoredPeers ?? this.psiphonRejectCensoredPeers,
      psiphonBundledList: psiphonBundledList ?? this.psiphonBundledList,
      torRelays: torRelays ?? this.torRelays,
      torBridges: torBridges ?? this.torBridges,
      torBridgeLines: torBridgeLines ?? this.torBridgeLines,
      exitLoc: exitLoc ?? this.exitLoc,
      protocol: protocol ?? this.protocol,
      transport: transport ?? this.transport,
      scanMode: scanMode ?? this.scanMode,
      obfuscation: obfuscation ?? this.obfuscation,
      ipVersion: ipVersion ?? this.ipVersion,
      logLevel: logLevel ?? this.logLevel,
      perfProfile: perfProfile ?? this.perfProfile,
      echMode: echMode ?? this.echMode,
      splitTunnelMode: splitTunnelMode ?? this.splitTunnelMode,
      bypassedApps: bypassedApps ?? this.bypassedApps,
      endpoint: endpoint ?? this.endpoint,
      wgEndpoint: wgEndpoint ?? this.wgEndpoint,
      h2Endpoint: h2Endpoint ?? this.h2Endpoint,
      wiwOuter: wiwOuter ?? this.wiwOuter,
      wiwInner: wiwInner ?? this.wiwInner,
      goolPeer: goolPeer ?? this.goolPeer,
      mimInner: mimInner ?? this.mimInner,
      masqueSni: masqueSni ?? this.masqueSni,
      echDns: echDns ?? this.echDns,
      echDomain: echDomain ?? this.echDomain,
      tlsGroups: tlsGroups ?? this.tlsGroups,
      tlsFingerprint: tlsFingerprint ?? this.tlsFingerprint,
      tlsCiphers: tlsCiphers ?? this.tlsCiphers,
      grease: grease ?? this.grease,
      apiAddress: apiAddress ?? this.apiAddress,
      socksPort: socksPort ?? this.socksPort,
      allowLan: allowLan ?? this.allowLan,
      routingMode: routingMode ?? this.routingMode,
      tunnelInterface: tunnelInterface ?? this.tunnelInterface,
      tunnelMtu: tunnelMtu ?? this.tunnelMtu,
      coreMtu: coreMtu ?? this.coreMtu,
      pathMtu: pathMtu ?? this.pathMtu,
      overrideDns: overrideDns ?? this.overrideDns,
      dnsPrimary: dnsPrimary ?? this.dnsPrimary,
      dnsSecondary: dnsSecondary ?? this.dnsSecondary,
      fragment: fragment ?? this.fragment,
      fragmentSize: fragmentSize ?? this.fragmentSize,
      fragmentDelay: fragmentDelay ?? this.fragmentDelay,
      quickReconnect: quickReconnect ?? this.quickReconnect,
      fastFirstConnect: fastFirstConnect ?? this.fastFirstConnect,
      dataCheck: dataCheck ?? this.dataCheck,
      validateSeconds: validateSeconds ?? this.validateSeconds,
      reconnectSeconds: reconnectSeconds ?? this.reconnectSeconds,
      wgKeepalive: wgKeepalive ?? this.wgKeepalive,
      wgProfileRetry: wgProfileRetry ?? this.wgProfileRetry,
      routeBlock: routeBlock ?? this.routeBlock,
      routeDirect: routeDirect ?? this.routeDirect,
      team: team ?? this.team,
      accessToken: accessToken ?? this.accessToken,
      accessId: accessId ?? this.accessId,
      accessSecret: accessSecret ?? this.accessSecret,
      accessEmail: accessEmail ?? this.accessEmail,
      gatewayProxy: gatewayProxy ?? this.gatewayProxy,
    );
  }

  Map<String, dynamic> toPlatformPayload() => <String, dynamic>{
    'core': core.wire,
    'psiphonCountry': psiphonCountry.trim(),
    'psiphonMode': psiphonMode.wire,
    'psiphonCdnIps': psiphonCdnIps.trim(),
    'psiphonCdnSni': psiphonCdnSni.trim(),
    'psiphonCdnSets': psiphonCdnSetList.join(','),
    'psiphonConduitPeers': psiphonConduitPeers.wire,
    'psiphonRejectCensoredPeers': psiphonRejectCensoredPeers,
    'torRelays': torRelays.wire,
    'torBridges': torBridgesValue,
    'exitLoc': exitLoc.trim(),
    'protocol': protocol.wire,
    'modeLabel': modeLabel,
    'transport': transport.wire,
    'scanMode': scanMode.wire,
    'obfuscation': obfuscation.wire,
    'noizeProfile': noizeProfile,
    'ipVersion': ipVersion.wire,
    'logLevel': logLevel.wire,
    'perfProfile': perfProfile.wire,
    'echMode': echMode.wire,
    'endpoint': endpoint.trim(),
    'wgEndpoint': wgEndpoint.trim(),
    'h2Endpoint': h2Endpoint.trim(),
    'wiwOuter': usesGoolClassic ? wiwOuterPeer : '',
    'wiwInner': usesGoolClassic ? wiwInnerPeer : '',
    'tlsGroups': tlsGroups.trim(),
    'socksPort': socksPort,
    'bindAddress': bindAddress,
    'httpProxyPort': httpProxyPort,
    'httpProxyAddress': httpProxyAddress,
    'allowLan': allowLan,
    'proxyOnly': proxyOnly,
    'systemProxy': systemProxy,
    'routingMode': routingMode.wire,
    'tunnelInterface': tunnelInterface,
    'tunnelMtu': tunnelMtu,
    'coreMtu': effectiveCoreMtu,
    'overrideDns': overrideDns,
    'dnsPrimary': dnsPrimary.trim(),
    'dnsSecondary': dnsSecondary.trim(),
    if (bypassUid != null) 'bypassUid': bypassUid,
    'fragment': fragment,
    'fragmentSize': fragmentSize,
    'fragmentDelay': fragmentDelay,
    'quickReconnect': quickReconnect,
    'fastFirstConnect': fastFirstConnect,
    'dataCheck': dataCheck,
    'validateSeconds': validateSeconds,
    'reconnectSeconds': reconnectSeconds,
    'wgKeepalive': wgKeepalive,
    'wgProfileRetry': wgProfileRetry,
    'routeBlock': routeRules(routeBlock).join(','),
    'routeDirect': routeRules(routeDirect).join(','),
    'team': teamName,
    'accessToken': accessToken.trim(),
    'accessId': accessId.trim(),
    'accessSecret': accessSecret.trim(),
    'accessEmail': accessEmail.trim(),
    'gatewayProxy': gatewayProxy,
    'splitTunnelMode': splitTunnelMode.name,
    'bypassedApps': bypassedApps.toList(),
  };

  static List<String> routeRules(String raw) => raw
      .split(RegExp(r'[\n,;]+'))
      .map((entry) => entry.trim())
      .where((entry) => entry.isNotEmpty && !entry.startsWith('#'))
      .toList();

  List<String> toCoreArguments() {
    if (psiphonOnly || torOnly) return const <String>[];

    final args = <String>[
      '--bind',
      aetherBindAddress,
      '--http-proxy',
      aetherHttpProxyAddress,
      '--scan',
      scanMode.wire,
      '--log-level',
      logLevel.wire,
      '--ip',
      ipVersion.wire,
      '--validate-secs',
      '$validateSeconds',
      '--reconnect-secs',
      '$reconnectSeconds',
    ];

    if (!obfuscationAuto) args.addAll(<String>['--noize', noizeProfile]);

    switch (effectiveProtocol) {
      case CoreProtocol.masque:
        args.add('--masque');
      case CoreProtocol.wireguard:
        args.add('--wg');
      case CoreProtocol.gool:
        args.add('--gool');
      case CoreProtocol.goolClassic:
        args.add('--gool-classic');
      case CoreProtocol.mim:
        args.add('--mim');
    }

    if (usesHttp2) {
      args.add('--h2');
      if (h2Endpoint.trim().isNotEmpty) {
        args.addAll(<String>['--h2-peer', h2Endpoint.trim()]);
      }
    }

    if (fragment) {
      args.add('--fragment');
      if (fragmentSize.trim().isNotEmpty) {
        args.addAll(<String>['--fragment-size', fragmentSize.trim()]);
      }
      if (fragmentDelay.trim().isNotEmpty) {
        args.addAll(<String>['--fragment-delay', fragmentDelay.trim()]);
      }
    }

    if (isMasque) {
      args.addAll(<String>['--masque-sni', masqueServerName]);
    }

    if (usesEch) {
      args.addAll(<String>['--ech', echMode.wire]);
      if (echDns.trim().isNotEmpty) {
        args.addAll(<String>['--ech-dns', echDns.trim()]);
      }
      if (echDomain.trim().isNotEmpty) {
        args.addAll(<String>['--ech-domain', echDomain.trim()]);
      }
    }

    if (usesWireGuard) {
      args.addAll(<String>['--keepalive', '$wgKeepalive']);
      if (!wgProfileRetry) args.add('--no-profile-retry');
      if (!usesGoolClassic && wgEndpoint.trim().isNotEmpty) {
        args.addAll(<String>['--wg-peer', wgEndpoint.trim()]);
      }
    }

    if (usesGoolClassic) {
      if (wiwOuterPeer.isNotEmpty) {
        args.addAll(<String>['--wiw-outer', wiwOuterPeer]);
      }
      if (wiwInnerPeer.isNotEmpty) {
        args.addAll(<String>['--wiw-inner', wiwInnerPeer]);
      }
      if (!wiwPinned) args.add('--wiw-scan');
    } else if (usesMim) {
      if (manualGateway.isNotEmpty) {
        args.addAll(<String>['--mim-outer', manualGateway]);
      }
      if (mimInnerValue.isNotEmpty) {
        args.addAll(<String>['--mim-inner', mimInnerValue]);
      }
    } else {
      if (manualGateway.isNotEmpty) {
        args.addAll(<String>['--peer', manualGateway]);
      }
      if (usesGool && goolPeerValue.isNotEmpty) {
        args.addAll(<String>['--gool-peer', goolPeerValue]);
      }
    }
    if (overrideDns) {
      final resolvers = <String>[
        dnsPrimary.trim(),
        dnsSecondary.trim(),
      ].where((entry) => entry.isNotEmpty).toList();
      if (resolvers.isNotEmpty) {
        args.addAll(<String>['--dns', resolvers.join(',')]);
      }
    }
    if (tlsGroups.trim().isNotEmpty) {
      args.addAll(<String>['--tls-groups', tlsGroups.trim()]);
    }
    final ciphers = effectiveTlsCiphers;
    if (ciphers.isNotEmpty) args.addAll(<String>['--tls-ciphers', ciphers]);
    if (!effectiveGrease) args.add('--disable-grease');
    if (apiAddress.trim().isNotEmpty) {
      args.addAll(<String>['--api-address', apiAddress.trim()]);
    }
    if (perfProfile != PerfProfile.auto) {
      args.addAll(<String>['--perf', perfProfile.wire]);
    }
    if (!dataCheck) args.add('--no-data-check');
    args.add(quickReconnect ? '--quick-reconnect' : '--no-quick-reconnect');

    final blocked = routeRules(routeBlock);
    if (blocked.isNotEmpty) {
      args.addAll(<String>['--route-block', blocked.join(',')]);
    }
    final direct = routeRules(routeDirect);
    if (direct.isNotEmpty) {
      args.addAll(<String>['--route-direct', direct.join(',')]);
    }

    if (usesZeroTrust) {
      args.addAll(<String>['--team', teamName]);

      if (hasAccessToken) {
        args.addAll(<String>['--access-token', accessToken.trim()]);
      } else if (hasServiceToken) {
        args.addAll(<String>[
          '--access-id',
          accessId.trim(),
          '--access-secret',
          accessSecret.trim(),
        ]);
      } else if (hasAccessEmail) {
        args.addAll(<String>['--access-email', accessEmail.trim()]);
      }

      if (gatewayProxy) args.add('--gateway');
    }

    return args;
  }

  bool get canFindGateway => usesAether && !dialsThrough;

  bool get canRenewKeys => !usesZeroTrust;

  List<String> toRegistrationArguments(WarpKeyKind kind) {
    final args = <String>[
      '--register',
      kind.wire,
      '--log-level',
      'info',
      '--ip',
      ipVersion.wire,
    ];

    if (fragment) {
      args.add('--fragment');
      if (fragmentSize.trim().isNotEmpty) {
        args.addAll(<String>['--fragment-size', fragmentSize.trim()]);
      }
      if (fragmentDelay.trim().isNotEmpty) {
        args.addAll(<String>['--fragment-delay', fragmentDelay.trim()]);
      }
    }

    if (usesEch) {
      args.addAll(<String>['--ech', echMode.wire]);
      if (echDns.trim().isNotEmpty) {
        args.addAll(<String>['--ech-dns', echDns.trim()]);
      }
      if (echDomain.trim().isNotEmpty) {
        args.addAll(<String>['--ech-domain', echDomain.trim()]);
      }
    }

    if (tlsGroups.trim().isNotEmpty) {
      args.addAll(<String>['--tls-groups', tlsGroups.trim()]);
    }
    final ciphers = effectiveTlsCiphers;
    if (ciphers.isNotEmpty) args.addAll(<String>['--tls-ciphers', ciphers]);
    if (!effectiveGrease) args.add('--disable-grease');
    if (apiAddress.trim().isNotEmpty) {
      args.addAll(<String>['--api-address', apiAddress.trim()]);
    }

    return args;
  }

  List<String> toScanArguments({
    required String bindAddress,
    required String httpProxyAddress,
  }) {
    final args = <String>[
      ...copyWith(
        endpoint: '',
        mimInner: '',
        wiwOuter: '',
        wiwInner: '',
      ).toCoreArguments(),
    ];
    for (final (flag, value) in <(String, String)>[
      ('--bind', bindAddress),
      ('--http-proxy', httpProxyAddress),
      ('--log-level', 'info'),
    ]) {
      final index = args.indexOf(flag);
      if (index >= 0 && index + 1 < args.length) args[index + 1] = value;
    }
    return args;
  }

  TunnelSettings withFoundGateway(GatewayScan found) =>
      switch (effectiveProtocol) {
        CoreProtocol.goolClassic => copyWith(
          wiwOuter: found.endpoint,
          wiwInner: found.inner ?? '',
        ),
        CoreProtocol.mim => copyWith(
          endpoint: found.endpoint,
          mimInner: found.inner ?? '',
        ),
        _ => copyWith(endpoint: found.endpoint),
      };
}
