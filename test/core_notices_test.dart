import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oblivion/data/models/tunnel_settings.dart';
import 'package:oblivion/data/models/tunnel_status.dart';
import 'package:oblivion/data/services/psiphon_data.dart';
import 'package:oblivion/data/services/settings_store.dart';
import 'package:oblivion/data/services/tunnel_channel.dart';
import 'package:oblivion/l10n/generated/app_localizations.dart';
import 'package:oblivion/presentation/providers/app_providers.dart';
import 'package:oblivion/presentation/providers/tunnel_providers.dart';
import 'package:oblivion/presentation/screens/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Channel implements TunnelChannel {
  final StreamController<String> logs = StreamController<String>.broadcast();
  final StreamController<TunnelStatus> statuses =
      StreamController<TunnelStatus>.broadcast();
  final List<String?> handedEntries = <String?>[];

  @override
  Stream<String> get logStream => logs.stream;

  @override
  Stream<TunnelStatus> get statusStream => statuses.stream;

  @override
  Future<TunnelStatus> currentStatus() async => TunnelStatus.initial;

  @override
  Future<bool> prepare() async => true;

  @override
  Future<void> connect(
    TunnelSettings settings, {
    String? psiphonServerEntries,
  }) async {
    handedEntries.add(psiphonServerEntries);
  }

  @override
  Future<bool> requestNotifications() async => true;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Bundle extends CachingAssetBundle {
  _Bundle(this.bytes);

  final Uint8List bytes;

  @override
  Future<ByteData> load(String key) async {
    if (key != PsiphonServerList.asset) throw StateError('no asset $key');
    return ByteData.sublistView(bytes);
  }
}

String _entry(String address, String region) => utf8
    .encode(
      '$address 443 secret certificate '
      '{"ipAddress":"$address","region":"$region"}',
    )
    .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
    .join();

Uint8List _package(List<String> entries) => Uint8List.fromList(
  zlib.encode(
    utf8.encode(
      jsonEncode(<String, String>{
        'data': '${entries.join('\n')}\n',
        'signature': 'c2ln',
        'signingPublicKeyDigest': 'a2V5',
      }),
    ),
  ),
);

Future<void> _settle() async {
  for (var round = 0; round < 20; round++) {
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}

void main() {
  late Directory support;
  late _Channel channel;
  late SettingsStore store;
  late ProviderContainer container;

  Future<void> start(TunnelSettings settings) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    SharedPreferences.resetStatic();
    store = await SettingsStore.open();
    store.readTunnelSettings();
    await store.writeTunnelSettings(settings);
    container = ProviderContainer(
      overrides: <Override>[
        settingsStoreProvider.overrideWithValue(store),
        tunnelChannelProvider.overrideWithValue(channel),
        psiphonDataProvider.overrideWithValue(
          PsiphonData(
            bundle: _Bundle(
              _package(<String>[
                _entry('1.2.3.4', 'JP'),
                _entry('5.6.7.8', 'ID'),
              ]),
            ),
            support: () async => support,
          ),
        ),
      ],
    );
    container.read(tunnelProvider);
  }

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    support = Directory.systemTemp.createTempSync('oblivion-notices-');
    channel = _Channel();
  });

  tearDown(() {
    container.dispose();
    if (support.existsSync()) support.deleteSync(recursive: true);
  });

  group('what the core says in its log', () {
    test('a core that stops for want of an ech key is told apart', () async {
      await start(const TunnelSettings(routingMode: RoutingMode.socksOnly));
      channel.logs.add('[aether] [+] fetched ECHConfigList automatically');
      await _settle();
      expect(container.read(echKeyMissingProvider), isFalse);

      channel.logs.add(
        '[aether] Error: Ech("ECH is on but there is no ECH key to offer '
        '(udp://1.1.1.1:53 did not answer for cloudflare-ech.com); stopping '
        'rather than send the server name in the clear")',
      );
      await _settle();
      expect(container.read(echKeyMissingProvider), isTrue);

      await container.read(tunnelProvider.notifier).connect();
      expect(container.read(echKeyMissingProvider), isFalse);
    });

    test('where psiphon can leave from is remembered and offered', () async {
      await start(const TunnelSettings(routingMode: RoutingMode.socksOnly));
      container.read(psiphonRegionsProvider);
      await _settle();
      expect(container.read(psiphonRegionsProvider), <String>{'ID', 'JP'});

      channel.logs.add(
        '[aether] [2026-10-15T10:36:18.487Z INFO  aether::psiphon] [*] '
        'psiphon can leave from: US CA DE',
      );
      await _settle();
      expect(container.read(psiphonRegionsProvider).toList(), <String>[
        'CA',
        'DE',
        'ID',
        'JP',
        'US',
      ]);
      expect(store.readPsiphonRegions(), <String>{'CA', 'DE', 'US'});

      channel.logs.add('[aether] [*] psiphon can leave from: GB');
      await _settle();
      expect(store.readPsiphonRegions(), <String>{'GB'});

      await container.read(psiphonRegionsProvider.notifier).forget();
      expect(store.readPsiphonRegions(), isEmpty);
      expect(container.read(psiphonRegionsProvider), <String>{'ID', 'JP'});
    });
  });

  group('the bundled server list on connect', () {
    test('psiphon gets the unpacked list', () async {
      await start(
        const TunnelSettings(
          psiphon: CarrierMode.only,
          routingMode: RoutingMode.socksOnly,
        ),
      );
      await container.read(tunnelProvider.notifier).connect();

      final handed = channel.handedEntries.single;
      expect(handed, isNotNull);
      expect(
        File(handed!).readAsStringSync(),
        contains(_entry('1.2.3.4', 'JP')),
      );
    });

    test('a chain through psiphon gets it as well', () async {
      await start(
        const TunnelSettings(
          psiphon: CarrierMode.chain,
          routingMode: RoutingMode.socksOnly,
        ),
      );
      await container.read(tunnelProvider.notifier).connect();
      expect(channel.handedEntries.single, isNotNull);
    });

    test('nothing is handed when the list is turned off', () async {
      await start(
        const TunnelSettings(
          psiphon: CarrierMode.only,
          routingMode: RoutingMode.socksOnly,
          psiphonBundledList: false,
        ),
      );
      await container.read(tunnelProvider.notifier).connect();
      expect(channel.handedEntries.single, isNull);
    });

    test('a session without psiphon is handed nothing', () async {
      await start(const TunnelSettings(routingMode: RoutingMode.socksOnly));
      await container.read(tunnelProvider.notifier).connect();
      expect(channel.handedEntries.single, isNull);
    });
  });

  group('the failure shown under the switch', () {
    late L10n l10n;

    setUp(() async {
      l10n = await L10n.delegate.load(const Locale('en'));
      container = ProviderContainer();
    });

    test('a missing ech key is explained instead of the exit code', () {
      const failed = TunnelStatus(
        stage: TunnelStage.failed,
        message: 'core exited with code 1',
      );
      expect(
        failureText(l10n, failed, echKeyMissing: true),
        l10n.echKeyMissing,
      );
      expect(
        failureText(l10n, failed, echKeyMissing: false),
        'core exited with code 1',
      );
    });

    test('nothing is shown unless the connection failed', () {
      expect(
        failureText(
          l10n,
          const TunnelStatus(stage: TunnelStage.connected),
          echKeyMissing: true,
        ),
        isNull,
      );
      expect(
        failureText(
          l10n,
          const TunnelStatus(stage: TunnelStage.failed, message: '  '),
          echKeyMissing: false,
        ),
        isNull,
      );
    });
  });
}
