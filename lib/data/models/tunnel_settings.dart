import 'dart:io';

enum CoreProtocol {
  masque('masque'),
  wireguard('wg'),
  gool('gool');

  const CoreProtocol(this.wire);

  final String wire;

  static CoreProtocol fromWire(String? value) =>
      values.firstWhere((e) => e.wire == value, orElse: () => masque);
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
  stealth('stealth'),
  ironclad('ironclad');

  const ScanMode(this.wire);

  final String wire;

  static ScanMode fromWire(String? value) =>
      values.firstWhere((e) => e.wire == value, orElse: () => balanced);
}

enum ObfuscationProfile {
  off('off'),
  light('light'),
  balanced('balanced'),
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
  bypassSelected;

  static SplitTunnelMode fromName(String? value) =>
      values.firstWhere((e) => e.name == value, orElse: () => disabled);
}

class TunnelSettings {
  const TunnelSettings({
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
    this.tlsGroups = '',
    this.socksPort = 1819,
    this.allowLan = false,
    this.routingMode = RoutingMode.fullTunnel,
    this.tunnelInterface = 'oblivion0',
    this.tunnelMtu = 8500,
    this.overrideDns = true,
    this.dnsPrimary = '1.1.1.1',
    this.dnsSecondary = '1.0.0.1',
    this.fragment = false,
    this.fragmentSize = '16-32',
    this.fragmentDelay = '2-10',
    this.quickReconnect = true,
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
  final String tlsGroups;

  final int socksPort;
  final bool allowLan;
  final RoutingMode routingMode;
  final String tunnelInterface;
  final int tunnelMtu;
  final bool overrideDns;
  final String dnsPrimary;
  final String dnsSecondary;

  final bool fragment;
  final String fragmentSize;
  final String fragmentDelay;

  final bool quickReconnect;
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

  bool get isMasque => protocol == CoreProtocol.masque;

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

  bool get usesHttp2 => isMasque && transport == MasqueTransport.http2;

  bool get usesWireGuard =>
      protocol == CoreProtocol.wireguard || protocol == CoreProtocol.gool;

  static final RegExp rangePattern = RegExp(r'^\d{1,5}(-\d{1,5})?$');

  static bool isValidRange(String value) {
    final trimmed = value.trim();
    if (!rangePattern.hasMatch(trimmed)) return false;
    final parts = trimmed.split('-').map(int.parse).toList();
    if (parts.any((part) => part <= 0)) return false;
    if (parts.length == 2 && parts[1] < parts[0]) return false;
    return true;
  }

  String get noizeProfile => obfuscation.wire;

  String get bindAddress => '${allowLan ? '0.0.0.0' : '127.0.0.1'}:$socksPort';

  int get httpProxyPort => socksPort + 1;

  String get httpProxyAddress =>
      '${allowLan ? '0.0.0.0' : '127.0.0.1'}:$httpProxyPort';

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
    String? tlsGroups,
    int? socksPort,
    bool? allowLan,
    RoutingMode? routingMode,
    String? tunnelInterface,
    int? tunnelMtu,
    bool? overrideDns,
    String? dnsPrimary,
    String? dnsSecondary,
    bool? fragment,
    String? fragmentSize,
    String? fragmentDelay,
    bool? quickReconnect,
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
      tlsGroups: tlsGroups ?? this.tlsGroups,
      socksPort: socksPort ?? this.socksPort,
      allowLan: allowLan ?? this.allowLan,
      routingMode: routingMode ?? this.routingMode,
      tunnelInterface: tunnelInterface ?? this.tunnelInterface,
      tunnelMtu: tunnelMtu ?? this.tunnelMtu,
      overrideDns: overrideDns ?? this.overrideDns,
      dnsPrimary: dnsPrimary ?? this.dnsPrimary,
      dnsSecondary: dnsSecondary ?? this.dnsSecondary,
      fragment: fragment ?? this.fragment,
      fragmentSize: fragmentSize ?? this.fragmentSize,
      fragmentDelay: fragmentDelay ?? this.fragmentDelay,
      quickReconnect: quickReconnect ?? this.quickReconnect,
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
        'protocol': protocol.wire,
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
        'overrideDns': overrideDns,
        'dnsPrimary': dnsPrimary.trim(),
        'dnsSecondary': dnsSecondary.trim(),
        if (bypassUid != null) 'bypassUid': bypassUid,
        'fragment': fragment,
        'fragmentSize': fragmentSize,
        'fragmentDelay': fragmentDelay,
        'quickReconnect': quickReconnect,
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
    final args = <String>[
      '--bind',
      bindAddress,
      '--http-proxy',
      httpProxyAddress,
      '--scan',
      scanMode.wire,
      '--noize',
      noizeProfile,
      '--log-level',
      logLevel.wire,
      '--ip',
      ipVersion.wire,
      '--validate-secs',
      '$validateSeconds',
      '--reconnect-secs',
      '$reconnectSeconds',
    ];

    switch (protocol) {
      case CoreProtocol.masque:
        args.add('--masque');
      case CoreProtocol.wireguard:
        args.add('--wg');
      case CoreProtocol.gool:
        args.add('--gool');
    }

    if (usesHttp2) {
      args.add('--h2');
      if (h2Endpoint.trim().isNotEmpty) {
        args.addAll(<String>['--h2-peer', h2Endpoint.trim()]);
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
    }

    if (isMasque && echMode != EchMode.off) {
      args.addAll(<String>['--ech', echMode.wire]);
    }

    if (usesWireGuard) {
      args.addAll(<String>['--keepalive', '$wgKeepalive']);
      if (!wgProfileRetry) args.add('--no-profile-retry');
      if (wgEndpoint.trim().isNotEmpty) {
        args.addAll(<String>['--wg-peer', wgEndpoint.trim()]);
      }
    }

    if (manualGateway.isNotEmpty) {
      args.addAll(<String>['--peer', manualGateway]);
    }
    if (overrideDns) {
      final resolvers = <String>[dnsPrimary.trim(), dnsSecondary.trim()]
          .where((entry) => entry.isNotEmpty)
          .toList();
      if (resolvers.isNotEmpty) {
        args.addAll(<String>['--dns', resolvers.join(',')]);
      }
    }
    if (tlsGroups.trim().isNotEmpty) {
      args.addAll(<String>['--tls-groups', tlsGroups.trim()]);
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
}
