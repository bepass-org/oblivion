import 'dart:async';
import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/tunnel_settings.dart';

const List<String> supportedLocaleCodes = <String>['en', 'fa'];

const String fallbackLocaleCode = 'en';

String resolveDeviceLocaleCode() {
  for (final locale in PlatformDispatcher.instance.locales) {
    final code = locale.languageCode.toLowerCase();
    if (supportedLocaleCodes.contains(code)) return code;
  }
  return fallbackLocaleCode;
}

class AppPreferences {
  const AppPreferences({
    this.themeMode = ThemeMode.dark,
    this.localeCode = fallbackLocaleCode,
    this.introSeen = false,
    this.devNoteSeen = false,
  });

  final ThemeMode themeMode;
  final String localeCode;
  final bool introSeen;
  final bool devNoteSeen;

  Locale get locale => Locale(localeCode);

  AppPreferences copyWith({
    ThemeMode? themeMode,
    String? localeCode,
    bool? introSeen,
    bool? devNoteSeen,
  }) {
    return AppPreferences(
      themeMode: themeMode ?? this.themeMode,
      localeCode: localeCode ?? this.localeCode,
      introSeen: introSeen ?? this.introSeen,
      devNoteSeen: devNoteSeen ?? this.devNoteSeen,
    );
  }
}

class SettingsStore {
  SettingsStore(this._prefs);

  final SharedPreferences _prefs;

  static Future<SettingsStore> open() async =>
      SettingsStore(await SharedPreferences.getInstance());

  static const String _prefix = 'core.';
  static const List<String> _coreKeys = <String>[
    'core',
    'psiphonCountry',
    'psiphonMode',
    'psiphonCdnIps',
    'psiphonCdnSni',
    'psiphonConduitPeers',
    'psiphonRejectCensoredPeers',
    'torRelays',
    'exitLoc',
    'protocol',
    'transport',
    'scanMode',
    'obfuscation',
    'ipVersion',
    'logLevel',
    'perfProfile',
    'echMode',
    'splitTunnelMode',
    'bypassedApps',
    'endpoint',
    'wgEndpoint',
    'h2Endpoint',
    'wiwOuter',
    'wiwInner',
    'tlsGroups',
    'socksPort',
    'allowLan',
    'routingMode',
    'tunnelInterface',
    'tunnelMtu',
    'coreMtu',
    'pathMtu',
    'overrideDns',
    'dnsPrimary',
    'dnsSecondary',
    'fragment',
    'fragmentSize',
    'fragmentDelay',
    'quickReconnect',
    'fastFirstConnect',
    'dataCheck',
    'validateSeconds',
    'reconnectSeconds',
    'wgKeepalive',
    'wgProfileRetry',
    'routeBlock',
    'routeDirect',
    'team',
    'accessToken',
    'accessId',
    'accessSecret',
    'accessEmail',
    'gatewayProxy',
  ];

  static const _kThemeMode = 'app.themeMode';
  static const _kLocale = 'app.locale';
  static const _kIntroSeen = 'app.introSeen';
  static const _kDevNoteSeen = 'app.devNoteSeen';

  Map<String, Object>? _stored;

  String? _string(String key) => _prefs.getString('$_prefix$key');

  static const String _legacyTorModeKey = 'torMode';

  TunnelSettings readTunnelSettings() {
    const fallback = TunnelSettings();

    final legacyTorMode = _string(_legacyTorModeKey);
    final core = CoreEngine.migrate(_string('core'), legacyTorMode);
    if (legacyTorMode != null) {
      unawaited(_prefs.setString('${_prefix}core', core.wire));
      unawaited(_prefs.remove('$_prefix$_legacyTorModeKey'));
    }

    final settings = TunnelSettings(
      core: core,
      psiphonCountry: _string('psiphonCountry') ?? fallback.psiphonCountry,
      psiphonMode: PsiphonMode.fromWire(_string('psiphonMode')),
      psiphonCdnIps: _string('psiphonCdnIps') ?? fallback.psiphonCdnIps,
      psiphonCdnSni: _string('psiphonCdnSni') ?? fallback.psiphonCdnSni,
      psiphonConduitPeers: ConduitPeers.fromWire(
        _string('psiphonConduitPeers'),
      ),
      psiphonRejectCensoredPeers:
          _prefs.getBool('${_prefix}psiphonRejectCensoredPeers') ??
          fallback.psiphonRejectCensoredPeers,
      torRelays: TorRelays.fromWire(_string('torRelays')),
      exitLoc: _string('exitLoc') ?? '',
      protocol: CoreProtocol.fromWire(_string('protocol')),
      transport: MasqueTransport.fromWire(_string('transport')),
      scanMode: ScanMode.fromWire(_string('scanMode')),
      obfuscation: ObfuscationProfile.fromWire(_string('obfuscation')),
      ipVersion: IpVersion.fromWire(_string('ipVersion')),
      logLevel: CoreLogLevel.fromWire(_string('logLevel')),
      perfProfile: PerfProfile.fromWire(_string('perfProfile')),
      echMode: EchMode.fromWire(_string('echMode')),
      splitTunnelMode: SplitTunnelMode.fromName(_string('splitTunnelMode')),
      bypassedApps:
          (_prefs.getStringList('${_prefix}bypassedApps') ?? const <String>[])
              .toSet(),
      endpoint: _string('endpoint') ?? fallback.endpoint,
      wgEndpoint: _string('wgEndpoint') ?? fallback.wgEndpoint,
      h2Endpoint: _string('h2Endpoint') ?? fallback.h2Endpoint,
      wiwOuter: _string('wiwOuter') ?? fallback.wiwOuter,
      wiwInner: _string('wiwInner') ?? fallback.wiwInner,
      tlsGroups: _string('tlsGroups') ?? fallback.tlsGroups,
      socksPort: _prefs.getInt('${_prefix}socksPort') ?? fallback.socksPort,
      allowLan: _prefs.getBool('${_prefix}allowLan') ?? fallback.allowLan,
      routingMode: RoutingMode.fromWire(_string('routingMode')),
      tunnelInterface:
          _prefs.getString('${_prefix}tunnelInterface') ??
          fallback.tunnelInterface,
      tunnelMtu: _prefs.getInt('${_prefix}tunnelMtu') ?? fallback.tunnelMtu,
      coreMtu: _prefs.getInt('${_prefix}coreMtu') ?? fallback.coreMtu,
      pathMtu: _prefs.getInt('${_prefix}pathMtu') ?? fallback.pathMtu,
      overrideDns:
          _prefs.getBool('${_prefix}overrideDns') ?? fallback.overrideDns,
      dnsPrimary:
          _prefs.getString('${_prefix}dnsPrimary') ?? fallback.dnsPrimary,
      dnsSecondary:
          _prefs.getString('${_prefix}dnsSecondary') ?? fallback.dnsSecondary,
      fragment: _prefs.getBool('${_prefix}fragment') ?? fallback.fragment,
      fragmentSize: _string('fragmentSize') ?? fallback.fragmentSize,
      fragmentDelay: _string('fragmentDelay') ?? fallback.fragmentDelay,
      quickReconnect:
          _prefs.getBool('${_prefix}quickReconnect') ?? fallback.quickReconnect,
      fastFirstConnect:
          _prefs.getBool('${_prefix}fastFirstConnect') ??
          fallback.fastFirstConnect,
      dataCheck: _prefs.getBool('${_prefix}dataCheck') ?? fallback.dataCheck,
      validateSeconds:
          _prefs.getInt('${_prefix}validateSeconds') ??
          fallback.validateSeconds,
      reconnectSeconds:
          _prefs.getInt('${_prefix}reconnectSeconds') ??
          fallback.reconnectSeconds,
      wgKeepalive:
          _prefs.getInt('${_prefix}wgKeepalive') ?? fallback.wgKeepalive,
      wgProfileRetry:
          _prefs.getBool('${_prefix}wgProfileRetry') ?? fallback.wgProfileRetry,
      routeBlock: _string('routeBlock') ?? fallback.routeBlock,
      routeDirect: _string('routeDirect') ?? fallback.routeDirect,
      team: _string('team') ?? fallback.team,
      accessToken: _string('accessToken') ?? fallback.accessToken,
      accessId: _string('accessId') ?? fallback.accessId,
      accessSecret: _string('accessSecret') ?? fallback.accessSecret,
      accessEmail: _string('accessEmail') ?? fallback.accessEmail,
      gatewayProxy:
          _prefs.getBool('${_prefix}gatewayProxy') ?? fallback.gatewayProxy,
    );

    _stored = _snapshot(settings);
    return settings;
  }

  Map<String, Object> _snapshot(TunnelSettings s) => <String, Object>{
    'core': s.core.wire,
    'psiphonCountry': s.psiphonCountry,
    'psiphonMode': s.psiphonMode.wire,
    'psiphonCdnIps': s.psiphonCdnIps,
    'psiphonCdnSni': s.psiphonCdnSni,
    'psiphonConduitPeers': s.psiphonConduitPeers.wire,
    'psiphonRejectCensoredPeers': s.psiphonRejectCensoredPeers,
    'torRelays': s.torRelays.wire,
    'exitLoc': s.exitLoc,
    'protocol': s.protocol.wire,
    'transport': s.transport.wire,
    'scanMode': s.scanMode.wire,
    'obfuscation': s.obfuscation.wire,
    'ipVersion': s.ipVersion.wire,
    'logLevel': s.logLevel.wire,
    'perfProfile': s.perfProfile.wire,
    'echMode': s.echMode.wire,
    'splitTunnelMode': s.splitTunnelMode.name,
    'bypassedApps': s.bypassedApps.toList(),
    'endpoint': s.endpoint,
    'wgEndpoint': s.wgEndpoint,
    'h2Endpoint': s.h2Endpoint,
    'wiwOuter': s.wiwOuter,
    'wiwInner': s.wiwInner,
    'tlsGroups': s.tlsGroups,
    'socksPort': s.socksPort,
    'allowLan': s.allowLan,
    'routingMode': s.routingMode.wire,
    'tunnelInterface': s.tunnelInterface,
    'tunnelMtu': s.tunnelMtu,
    'coreMtu': s.coreMtu,
    'pathMtu': s.pathMtu,
    'overrideDns': s.overrideDns,
    'dnsPrimary': s.dnsPrimary,
    'dnsSecondary': s.dnsSecondary,
    'fragment': s.fragment,
    'fragmentSize': s.fragmentSize,
    'fragmentDelay': s.fragmentDelay,
    'quickReconnect': s.quickReconnect,
    'fastFirstConnect': s.fastFirstConnect,
    'dataCheck': s.dataCheck,
    'validateSeconds': s.validateSeconds,
    'reconnectSeconds': s.reconnectSeconds,
    'wgKeepalive': s.wgKeepalive,
    'wgProfileRetry': s.wgProfileRetry,
    'routeBlock': s.routeBlock,
    'routeDirect': s.routeDirect,
    'team': s.team,
    'accessToken': s.accessToken,
    'accessId': s.accessId,
    'accessSecret': s.accessSecret,
    'accessEmail': s.accessEmail,
    'gatewayProxy': s.gatewayProxy,
  };

  static bool _unchanged(Object? stored, Object next) {
    if (stored is List<String> && next is List<String>) {
      if (stored.length != next.length) return false;
      for (var i = 0; i < stored.length; i++) {
        if (stored[i] != next[i]) return false;
      }
      return true;
    }
    return stored == next;
  }

  Future<void> _put(String key, Object value) async {
    final name = '$_prefix$key';
    switch (value) {
      case final String text:
        await _prefs.setString(name, text);
      case final int number:
        await _prefs.setInt(name, number);
      case final bool flag:
        await _prefs.setBool(name, flag);
      case final List<String> items:
        await _prefs.setStringList(name, items);
    }
  }

  Future<void> writeTunnelSettings(TunnelSettings settings) async {
    final next = _snapshot(settings);
    final stored = _stored;
    _stored = next;

    for (final entry in next.entries) {
      if (stored != null && _unchanged(stored[entry.key], entry.value)) {
        continue;
      }
      await _put(entry.key, entry.value);
    }
  }

  Future<void> resetTunnelSettings() async {
    _stored = null;
    for (final key in _coreKeys) {
      await _prefs.remove('$_prefix$key');
    }
    await _prefs.remove('$_prefix$_legacyTorModeKey');
  }

  AppPreferences readAppPreferences() {
    final themeName = _prefs.getString(_kThemeMode);
    return AppPreferences(
      themeMode: ThemeMode.values.firstWhere(
        (mode) => mode.name == themeName,
        orElse: () => ThemeMode.dark,
      ),
      localeCode: _prefs.getString(_kLocale) ?? resolveDeviceLocaleCode(),
      introSeen: _prefs.getBool(_kIntroSeen) ?? false,
      devNoteSeen: _prefs.getBool(_kDevNoteSeen) ?? false,
    );
  }

  Future<void> writeAppPreferences(AppPreferences prefs) async {
    await _prefs.setString(_kThemeMode, prefs.themeMode.name);
    await _prefs.setBool(_kIntroSeen, prefs.introSeen);
    await _prefs.setBool(_kDevNoteSeen, prefs.devNoteSeen);
  }

  bool get hasLocaleOverride => _prefs.getString(_kLocale) != null;

  Future<void> writeLocaleOverride(String code) async {
    await _prefs.setString(_kLocale, code);
  }
}
