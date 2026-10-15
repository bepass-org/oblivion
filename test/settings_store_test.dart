import 'package:flutter_test/flutter_test.dart';
import 'package:oblivion/data/models/tunnel_settings.dart';
import 'package:oblivion/data/services/settings_store.dart';
import 'package:oblivion/data/services/tunnel_channel.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:shared_preferences_platform_interface/types.dart';

class _CountingStore extends SharedPreferencesStorePlatform {
  final Map<String, Object> values = <String, Object>{};
  final List<String> writes = <String>[];

  @override
  bool get isMock => true;

  @override
  Future<bool> clear() async {
    values.clear();
    return true;
  }

  @override
  Future<bool> clearWithParameters(ClearParameters parameters) => clear();

  @override
  Future<bool> clearWithPrefix(String prefix) => clear();

  @override
  Future<Map<String, Object>> getAll() async => Map<String, Object>.of(values);

  @override
  Future<Map<String, Object>> getAllWithParameters(
    GetAllParameters parameters,
  ) => getAll();

  @override
  Future<Map<String, Object>> getAllWithPrefix(String prefix) => getAll();

  @override
  Future<bool> remove(String key) async {
    values.remove(key);
    return true;
  }

  @override
  Future<bool> setValue(String valueType, String key, Object value) async {
    writes.add(key);
    values[key] = value;
    return true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _CountingStore backing;
  late SettingsStore store;

  setUp(() async {
    backing = _CountingStore();
    SharedPreferencesStorePlatform.instance = backing;
    SharedPreferences.resetStatic();
    store = await SettingsStore.open();
  });

  group('settings store', () {
    test('a single change writes a single key', () async {
      final settings = store.readTunnelSettings();
      backing.writes.clear();

      await store.writeTunnelSettings(settings.copyWith(tunnelMtu: 1280));

      expect(backing.writes, <String>['flutter.core.tunnelMtu']);
    });

    test('picking an app writes only the bypass list', () async {
      final settings = store.readTunnelSettings();
      backing.writes.clear();

      await store.writeTunnelSettings(
        settings.copyWith(bypassedApps: <String>{'com.example.one'}),
      );

      expect(backing.writes, <String>['flutter.core.bypassedApps']);
    });

    test('writing the same settings twice touches nothing the second time',
        () async {
      final settings = store.readTunnelSettings().copyWith(socksPort: 2000);
      await store.writeTunnelSettings(settings);
      backing.writes.clear();

      await store.writeTunnelSettings(settings);

      expect(backing.writes, isEmpty);
    });

    test('an mtu the user typed comes back after a reopen', () async {
      await store.writeTunnelSettings(
        store.readTunnelSettings().copyWith(
          tunnelMtu: 1400,
          coreMtu: 1328,
          pathMtu: 1400,
        ),
      );

      final reopened = SettingsStore(await SharedPreferences.getInstance());
      final settings = reopened.readTunnelSettings();

      expect(settings.tunnelMtu, 1400);
      expect(settings.coreMtu, 1328);
      expect(settings.pathMtu, 1400);
      expect(settings.effectiveCoreMtu, 1328);
    });

    test('the options of the new core come back after a reopen', () async {
      await store.writeTunnelSettings(
        store.readTunnelSettings().copyWith(
          protocol: CoreProtocol.goolClassic,
          goolPeer: '162.159.192.1:2408',
          masqueSni: 'consumer-masque.cloudflareclient.com',
          echDns: 'tcp://1.1.1.1',
          echDomain: 'crypto.cloudflare.com',
          tlsCiphers: 'ECDHE-RSA-AES128-GCM-SHA256',
          grease: false,
          apiAddress: '188.114.97.6:2053',
          psiphonCdnSets: <String>{'fastly', 'cloudflare'},
        ),
      );

      final reopened = SettingsStore(await SharedPreferences.getInstance());
      final settings = reopened.readTunnelSettings();

      expect(settings.protocol, CoreProtocol.goolClassic);
      expect(settings.goolPeer, '162.159.192.1:2408');
      expect(settings.masqueSni, 'consumer-masque.cloudflareclient.com');
      expect(settings.echDns, 'tcp://1.1.1.1');
      expect(settings.echDomain, 'crypto.cloudflare.com');
      expect(settings.tlsCiphers, 'ECDHE-RSA-AES128-GCM-SHA256');
      expect(settings.grease, isFalse);
      expect(settings.apiAddress, '188.114.97.6:2053');
      expect(settings.psiphonCdnSetList, <String>['cloudflare', 'fastly']);
    });

    test('gool saved by an earlier version opens as gool over masque', () async {
      backing.values['flutter.core.protocol'] = 'gool';
      backing.values['flutter.core.wiwOuter'] = '162.159.192.1:2408';
      SharedPreferences.resetStatic();

      final reopened = SettingsStore(await SharedPreferences.getInstance());
      final settings = reopened.readTunnelSettings();

      expect(settings.protocol, CoreProtocol.gool);
      expect(settings.wiwOuter, '162.159.192.1:2408');
      expect(settings.toCoreArguments(), contains('--gool'));
      expect(settings.toCoreArguments(), isNot(contains('--wiw-outer')));
    });

    test('a fragment size left at the old default is kept as it was', () async {
      backing.values['flutter.core.fragmentSize'] = '16-32';
      SharedPreferences.resetStatic();

      final reopened = SettingsStore(await SharedPreferences.getInstance());
      expect(reopened.readTunnelSettings().fragmentSize, '16-32');
    });

    test('the pattng options come back after a reopen', () async {
      await store.writeTunnelSettings(
        store.readTunnelSettings().copyWith(
          tlsFingerprint: TlsFingerprint.go,
          obfuscation: ObfuscationProfile.auto,
          mimInner: '162.159.198.2:443',
          torBridges: TorBridges.own,
          torBridgeLines: 'obfs4 1.2.3.4:443 AAAA cert=x iat-mode=0',
          psiphonBundledList: false,
        ),
      );

      final reopened = SettingsStore(await SharedPreferences.getInstance());
      final settings = reopened.readTunnelSettings();

      expect(settings.tlsFingerprint, TlsFingerprint.go);
      expect(settings.obfuscation, ObfuscationProfile.auto);
      expect(settings.mimInner, '162.159.198.2:443');
      expect(settings.torBridges, TorBridges.own);
      expect(settings.torBridgeLines, 'obfs4 1.2.3.4:443 AAAA cert=x iat-mode=0');
      expect(settings.psiphonBundledList, isFalse);
    });

    test('ciphers written before fingerprints existed stay in use', () async {
      backing.values['flutter.core.tlsCiphers'] = 'ECDHE-RSA-AES128-GCM-SHA256';
      SharedPreferences.resetStatic();

      final reopened = SettingsStore(await SharedPreferences.getInstance());
      final settings = reopened.readTunnelSettings();
      expect(settings.tlsFingerprint, TlsFingerprint.custom);
      expect(
        settings.toCoreArguments(),
        containsAllInOrder(<String>['--tls-ciphers', 'ECDHE-RSA-AES128-GCM-SHA256']),
      );
    });

    test('a fresh install takes the chrome fingerprint', () {
      expect(store.readTunnelSettings().tlsFingerprint, TlsFingerprint.chrome);
    });

    test('a cdn list name psiphon does not know is dropped', () async {
      backing.values['flutter.core.psiphonCdnSets'] = <String>[
        'cloudflare',
        'nowhere',
      ];
      SharedPreferences.resetStatic();

      final reopened = SettingsStore(await SharedPreferences.getInstance());
      expect(reopened.readTunnelSettings().psiphonCdnSets, <String>{
        'cloudflare',
      });
    });

    test('a reset drops the stored values and the diff along with them',
        () async {
      await store.writeTunnelSettings(
        store.readTunnelSettings().copyWith(tunnelMtu: 1400),
      );

      await store.resetTunnelSettings();
      backing.writes.clear();

      await store.writeTunnelSettings(const TunnelSettings());
      expect(backing.writes, isNotEmpty);
      expect(store.readTunnelSettings().tunnelMtu, 8500);
    });
  });

  group('app preferences', () {
    test('the developer note is unseen on a fresh install', () {
      expect(store.readAppPreferences().devNoteSeen, isFalse);
    });

    test('once seen the note stays seen across a reopen', () async {
      final prefs = store.readAppPreferences();
      await store.writeAppPreferences(prefs.copyWith(devNoteSeen: true));

      final reopened = SettingsStore(await SharedPreferences.getInstance());
      expect(reopened.readAppPreferences().devNoteSeen, isTrue);
    });
  });

  group('installed apps', () {
    test('an entry without a package name is dropped', () {
      expect(
        InstalledApp.tryFromMap(<dynamic, dynamic>{'label': 'Nameless'}),
        isNull,
      );
    });

    test('a missing label falls back to the package name', () {
      final app = InstalledApp.tryFromMap(<dynamic, dynamic>{
        'packageName': 'com.example.app',
      });

      expect(app?.label, 'com.example.app');
      expect(app?.isSystem, isFalse);
    });
  });
}
