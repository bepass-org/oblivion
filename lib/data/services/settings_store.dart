import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/tunnel_settings.dart';

class AppPreferences {
  const AppPreferences({
    this.themeMode = ThemeMode.dark,
    this.localeCode = 'fa',
    this.introSeen = false,
  });

  final ThemeMode themeMode;
  final String localeCode;
  final bool introSeen;

  Locale get locale => Locale(localeCode);

  AppPreferences copyWith({
    ThemeMode? themeMode,
    String? localeCode,
    bool? introSeen,
  }) {
    return AppPreferences(
      themeMode: themeMode ?? this.themeMode,
      localeCode: localeCode ?? this.localeCode,
      introSeen: introSeen ?? this.introSeen,
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
    'tlsGroups',
    'socksPort',
    'allowLan',
    'routingMode',
    'tunnelInterface',
    'tunnelMtu',
    'overrideDns',
    'dnsPrimary',
    'dnsSecondary',
    'fragment',
    'fragmentSize',
    'fragmentDelay',
    'quickReconnect',
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

  String? _string(String key) => _prefs.getString('$_prefix$key');

  TunnelSettings readTunnelSettings() {
    const fallback = TunnelSettings();

    return TunnelSettings(
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
      tlsGroups: _string('tlsGroups') ?? fallback.tlsGroups,
      socksPort: _prefs.getInt('${_prefix}socksPort') ?? fallback.socksPort,
      allowLan: _prefs.getBool('${_prefix}allowLan') ?? fallback.allowLan,
      routingMode: RoutingMode.fromWire(_string('routingMode')),
      tunnelInterface: _prefs.getString('${_prefix}tunnelInterface') ??
          fallback.tunnelInterface,
      tunnelMtu:
          _prefs.getInt('${_prefix}tunnelMtu') ?? fallback.tunnelMtu,
      overrideDns:
          _prefs.getBool('${_prefix}overrideDns') ?? fallback.overrideDns,
      dnsPrimary:
          _prefs.getString('${_prefix}dnsPrimary') ?? fallback.dnsPrimary,
      dnsSecondary: _prefs.getString('${_prefix}dnsSecondary') ??
          fallback.dnsSecondary,
      fragment: _prefs.getBool('${_prefix}fragment') ?? fallback.fragment,
      fragmentSize: _string('fragmentSize') ?? fallback.fragmentSize,
      fragmentDelay: _string('fragmentDelay') ?? fallback.fragmentDelay,
      quickReconnect:
          _prefs.getBool('${_prefix}quickReconnect') ?? fallback.quickReconnect,
      dataCheck: _prefs.getBool('${_prefix}dataCheck') ?? fallback.dataCheck,
      validateSeconds: _prefs.getInt('${_prefix}validateSeconds') ??
          fallback.validateSeconds,
      reconnectSeconds: _prefs.getInt('${_prefix}reconnectSeconds') ??
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
  }

  Future<void> writeTunnelSettings(TunnelSettings settings) async {
    await _prefs.setString('${_prefix}protocol', settings.protocol.wire);
    await _prefs.setString('${_prefix}transport', settings.transport.wire);
    await _prefs.setString('${_prefix}scanMode', settings.scanMode.wire);
    await _prefs.setString('${_prefix}obfuscation', settings.obfuscation.wire);
    await _prefs.setString('${_prefix}ipVersion', settings.ipVersion.wire);
    await _prefs.setString('${_prefix}logLevel', settings.logLevel.wire);
    await _prefs.setString('${_prefix}perfProfile', settings.perfProfile.wire);
    await _prefs.setString('${_prefix}echMode', settings.echMode.wire);
    await _prefs.setString(
      '${_prefix}splitTunnelMode',
      settings.splitTunnelMode.name,
    );
    await _prefs.setStringList(
      '${_prefix}bypassedApps',
      settings.bypassedApps.toList(),
    );
    await _prefs.setString('${_prefix}endpoint', settings.endpoint);
    await _prefs.setString('${_prefix}wgEndpoint', settings.wgEndpoint);
    await _prefs.setString('${_prefix}h2Endpoint', settings.h2Endpoint);
    await _prefs.setString('${_prefix}tlsGroups', settings.tlsGroups);
    await _prefs.setInt('${_prefix}socksPort', settings.socksPort);
    await _prefs.setBool('${_prefix}allowLan', settings.allowLan);
    await _prefs.setString('${_prefix}routingMode', settings.routingMode.wire);
    await _prefs.setString(
      '${_prefix}tunnelInterface',
      settings.tunnelInterface,
    );
    await _prefs.setInt('${_prefix}tunnelMtu', settings.tunnelMtu);
    await _prefs.setBool('${_prefix}overrideDns', settings.overrideDns);
    await _prefs.setString('${_prefix}dnsPrimary', settings.dnsPrimary);
    await _prefs.setString('${_prefix}dnsSecondary', settings.dnsSecondary);
    await _prefs.setBool('${_prefix}fragment', settings.fragment);
    await _prefs.setString('${_prefix}fragmentSize', settings.fragmentSize);
    await _prefs.setString('${_prefix}fragmentDelay', settings.fragmentDelay);
    await _prefs.setBool('${_prefix}quickReconnect', settings.quickReconnect);
    await _prefs.setBool('${_prefix}dataCheck', settings.dataCheck);
    await _prefs.setInt('${_prefix}validateSeconds', settings.validateSeconds);
    await _prefs.setInt('${_prefix}reconnectSeconds', settings.reconnectSeconds);
    await _prefs.setInt('${_prefix}wgKeepalive', settings.wgKeepalive);
    await _prefs.setBool('${_prefix}wgProfileRetry', settings.wgProfileRetry);
    await _prefs.setString('${_prefix}routeBlock', settings.routeBlock);
    await _prefs.setString('${_prefix}routeDirect', settings.routeDirect);
    await _prefs.setString('${_prefix}team', settings.team);
    await _prefs.setString('${_prefix}accessToken', settings.accessToken);
    await _prefs.setString('${_prefix}accessId', settings.accessId);
    await _prefs.setString('${_prefix}accessSecret', settings.accessSecret);
    await _prefs.setString('${_prefix}accessEmail', settings.accessEmail);
    await _prefs.setBool('${_prefix}gatewayProxy', settings.gatewayProxy);
  }

  Future<void> resetTunnelSettings() async {
    for (final key in _coreKeys) {
      await _prefs.remove('$_prefix$key');
    }
  }

  AppPreferences readAppPreferences() {
    final themeName = _prefs.getString(_kThemeMode);
    return AppPreferences(
      themeMode: ThemeMode.values.firstWhere(
        (mode) => mode.name == themeName,
        orElse: () => ThemeMode.dark,
      ),
      localeCode: _prefs.getString(_kLocale) ?? 'fa',
      introSeen: _prefs.getBool(_kIntroSeen) ?? false,
    );
  }

  Future<void> writeAppPreferences(AppPreferences prefs) async {
    await _prefs.setString(_kThemeMode, prefs.themeMode.name);
    await _prefs.setString(_kLocale, prefs.localeCode);
    await _prefs.setBool(_kIntroSeen, prefs.introSeen);
  }
}
