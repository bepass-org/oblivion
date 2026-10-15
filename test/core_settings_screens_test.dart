import 'package:flutter/cupertino.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oblivion/data/models/tunnel_settings.dart';
import 'package:oblivion/data/models/tunnel_status.dart';
import 'package:oblivion/data/services/settings_store.dart';
import 'package:oblivion/l10n/generated/app_localizations.dart';
import 'package:oblivion/presentation/providers/app_providers.dart';
import 'package:oblivion/presentation/providers/tunnel_providers.dart';
import 'package:oblivion/presentation/screens/advanced_screen.dart';
import 'package:oblivion/presentation/screens/psiphon_screen.dart';
import 'package:oblivion/presentation/screens/settings_screen.dart';
import 'package:oblivion/presentation/widgets/pickers.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<SettingsStore> _storeWith(TunnelSettings settings) async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  SharedPreferences.resetStatic();
  final store = await SettingsStore.open();
  store.readTunnelSettings();
  await store.writeTunnelSettings(settings);
  return store;
}

Widget _app(Widget home, {Locale locale = const Locale('en')}) {
  return CupertinoApp(
    locale: locale,
    supportedLocales: L10n.supportedLocales,
    localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
      L10n.delegate,
      GlobalCupertinoLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
    ],
    home: home,
  );
}

Future<L10n> _open(
  WidgetTester tester,
  TunnelSettings settings,
  Widget screen, {
  Locale locale = const Locale('en'),
}) async {
  tester.view.physicalSize = const Size(1000, 5200);
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final store = await _storeWith(settings);
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        settingsStoreProvider.overrideWithValue(store),
        tunnelCapabilityProvider.overrideWith(
          (ref) async =>
              const TunnelCapability(embedded: true, privileged: true),
        ),
      ],
      child: _app(screen, locale: locale),
    ),
  );
  await tester.pumpAndSettle();
  return L10n.delegate.load(locale);
}

TunnelSettings _current(WidgetTester tester, Type screen) {
  final container = ProviderScope.containerOf(
    tester.element(find.byType(screen)),
  );
  return container.read(tunnelSettingsProvider);
}

Future<void> _edit(
  WidgetTester tester,
  L10n l10n,
  String rowTitle,
  String value,
) async {
  await tester.tap(find.text(rowTitle).first);
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(CupertinoTextField), value);
  await tester.tap(find.text(l10n.save));
  await tester.pumpAndSettle();
}

void main() {
  group('settings screen', () {
    testWidgets('gool offers its wireguard server and keeps the gateway', (
      tester,
    ) async {
      final l10n = await _open(
        tester,
        const TunnelSettings(protocol: CoreProtocol.gool),
        const SettingsScreen(),
      );

      expect(find.text(l10n.goolPeer), findsOneWidget);
      expect(find.text(l10n.wiwSection), findsNothing);
      expect(find.text(l10n.endpointIgnoredOnGool), findsNothing);
      expect(find.text(l10n.protocolGool), findsOneWidget);
    });

    testWidgets('classic gool offers its two hops and ignores the gateway', (
      tester,
    ) async {
      final l10n = await _open(
        tester,
        const TunnelSettings(protocol: CoreProtocol.goolClassic),
        const SettingsScreen(),
      );

      expect(find.text(l10n.wiwSection), findsOneWidget);
      expect(find.text(l10n.goolPeer), findsNothing);
      expect(find.text(l10n.endpointIgnoredOnGool), findsOneWidget);
      expect(find.text(l10n.protocolGoolClassic), findsOneWidget);
    });

    testWidgets('the wireguard server of gool takes an address and a port', (
      tester,
    ) async {
      final l10n = await _open(
        tester,
        const TunnelSettings(protocol: CoreProtocol.gool),
        const SettingsScreen(),
      );

      await _edit(tester, l10n, l10n.goolPeer, '162.159.192.1');
      expect(find.text(l10n.wiwInvalidEndpoint), findsOneWidget);

      await tester.enterText(
        find.byType(CupertinoTextField),
        ' 162.159.192.1:2408 ',
      );
      await tester.tap(find.text(l10n.save));
      await tester.pumpAndSettle();

      expect(_current(tester, SettingsScreen).goolPeer, '162.159.192.1:2408');
      expect(find.text('162.159.192.1:2408'), findsOneWidget);
    });

    testWidgets('the masque server name is picked, typed or set back', (
      tester,
    ) async {
      final l10n = await _open(
        tester,
        const TunnelSettings(),
        const SettingsScreen(),
      );

      expect(find.text('www.cloudflare.com'), findsOneWidget);

      await tester.tap(find.text(l10n.masqueSni).first);
      await tester.pumpAndSettle();
      expect(find.text(l10n.masqueSniDefaultDesc), findsOneWidget);
      expect(find.text(l10n.masqueSniWarpDesc), findsOneWidget);
      await tester.tap(find.text(TunnelSettings.warpMasqueSni));
      await tester.pumpAndSettle();

      var settings = _current(tester, SettingsScreen);
      expect(settings.masqueSni, TunnelSettings.warpMasqueSni);
      expect(
        settings.toCoreArguments(),
        containsAllInOrder(<String>[
          '--masque-sni',
          TunnelSettings.warpMasqueSni,
        ]),
      );

      await tester.tap(find.text(l10n.masqueSni).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.masqueSniCustom));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(CupertinoTextField), '1.1.1.1');
      await tester.tap(find.text(l10n.save));
      await tester.pumpAndSettle();
      expect(find.text(l10n.serverNameRefusal), findsOneWidget);

      await tester.enterText(
        find.byType(CupertinoTextField),
        ' front.example.test ',
      );
      await tester.tap(find.text(l10n.save));
      await tester.pumpAndSettle();

      settings = _current(tester, SettingsScreen);
      expect(settings.masqueSni, 'front.example.test');
      expect(settings.masqueSniCustom, isTrue);
      expect(find.text('front.example.test'), findsOneWidget);

      await tester.tap(find.text(l10n.masqueSni).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.masqueSniCustom));
      await tester.pumpAndSettle();
      final editor = tester.widget<CupertinoTextField>(
        find.byType(CupertinoTextField),
      );
      expect(editor.controller?.text, 'front.example.test');
      await tester.tap(find.text(l10n.cancel));
      await tester.pumpAndSettle();
      expect(_current(tester, SettingsScreen).masqueSni, 'front.example.test');

      await tester.tap(find.text(l10n.masqueSni).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text(TunnelSettings.defaultMasqueSni).last);
      await tester.pumpAndSettle();

      settings = _current(tester, SettingsScreen);
      expect(settings.masqueSni, isEmpty);
      expect(
        settings.toCoreArguments(),
        containsAllInOrder(<String>['--masque-sni', 'www.cloudflare.com']),
      );
    });

    testWidgets('wireguard has no masque server name to pick', (tester) async {
      final l10n = await _open(
        tester,
        const TunnelSettings(protocol: CoreProtocol.wireguard),
        const SettingsScreen(),
      );

      await tester.tap(find.text(l10n.masqueSni));
      await tester.pumpAndSettle();
      expect(find.text(l10n.masqueSniDefaultDesc), findsNothing);
    });

    testWidgets('tor offers its bridges and asks for lines of its own', (
      tester,
    ) async {
      final l10n = await _open(
        tester,
        const TunnelSettings(core: CoreEngine.tor),
        const SettingsScreen(),
      );

      expect(find.text(l10n.torBridges), findsOneWidget);
      expect(find.text(l10n.torBridgeLines), findsNothing);

      await tester.tap(find.text(l10n.torBridges));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.torBridgesOwn).last);
      await tester.pumpAndSettle();

      expect(find.text(l10n.torBridgeLines), findsOneWidget);
      expect(find.text(l10n.torBridgeLinesRefusal), findsOneWidget);

      await _edit(tester, l10n, l10n.torBridgeLines, '# nothing here');
      expect(find.text(l10n.torBridgeLinesRefusal), findsWidgets);

      await tester.enterText(
        find.byType(CupertinoTextField),
        'obfs4 1.2.3.4:443 AAAA cert=x iat-mode=0',
      );
      await tester.tap(find.text(l10n.save));
      await tester.pumpAndSettle();

      final settings = _current(tester, SettingsScreen);
      expect(settings.torBridges, TorBridges.own);
      expect(
        settings.torBridgesValue,
        'obfs4 1.2.3.4:443 AAAA cert=x iat-mode=0',
      );
      expect(find.text(l10n.torBridgeLinesRefusal), findsNothing);
    });

    testWidgets('no bridge row without tor', (tester) async {
      final l10n = await _open(
        tester,
        const TunnelSettings(),
        const SettingsScreen(),
      );
      expect(find.text(l10n.torBridges), findsNothing);
    });

    testWidgets('masque in masque takes an inner hop on another edge', (
      tester,
    ) async {
      final l10n = await _open(
        tester,
        const TunnelSettings(
          protocol: CoreProtocol.mim,
          endpoint: '162.159.198.1:443',
        ),
        const SettingsScreen(),
      );

      await _edit(tester, l10n, l10n.mimInner, '162.159.198.1:8443');
      expect(find.text(l10n.wiwSameEdge), findsOneWidget);

      await tester.enterText(
        find.byType(CupertinoTextField),
        '162.159.198.2:443',
      );
      await tester.tap(find.text(l10n.save));
      await tester.pumpAndSettle();
      expect(_current(tester, SettingsScreen).mimInner, '162.159.198.2:443');
    });

    testWidgets('an exit country rule is checked and written in capitals', (
      tester,
    ) async {
      final l10n = await _open(
        tester,
        const TunnelSettings(),
        const SettingsScreen(),
      );

      await _edit(tester, l10n, l10n.exitLocTitle, 'iran');
      expect(find.text(l10n.exitLocRefusal), findsOneWidget);

      await tester.enterText(find.byType(CupertinoTextField), ' !ir, ru ');
      await tester.tap(find.text(l10n.save));
      await tester.pumpAndSettle();
      expect(_current(tester, SettingsScreen).exitLoc, '!IR,RU');
    });

    testWidgets('automatic obfuscation can be picked', (tester) async {
      final l10n = await _open(
        tester,
        const TunnelSettings(),
        const SettingsScreen(),
      );

      await tester.tap(find.text(l10n.obfuscation));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.obfuscationAutoDesc));
      await tester.pumpAndSettle();

      final settings = _current(tester, SettingsScreen);
      expect(settings.obfuscation, ObfuscationProfile.auto);
      expect(settings.toCoreArguments(), isNot(contains('--noize')));
    });

    testWidgets('both gools are offered when the tunnel goes out directly', (
      tester,
    ) async {
      final l10n = await _open(
        tester,
        const TunnelSettings(),
        const SettingsScreen(),
      );

      await tester.tap(find.text(l10n.protocol));
      await tester.pumpAndSettle();

      expect(find.text(l10n.protocolGoolDesc), findsOneWidget);
      expect(find.text(l10n.protocolGoolClassicDesc), findsOneWidget);
      expect(find.text(l10n.protocolWireGuardDesc), findsOneWidget);

      await tester.tap(find.text(l10n.protocolGoolClassicDesc));
      await tester.pumpAndSettle();
      expect(
        _current(tester, SettingsScreen).protocol,
        CoreProtocol.goolClassic,
      );
    });

    testWidgets('through tor only what rides tcp is offered, gool included', (
      tester,
    ) async {
      final l10n = await _open(
        tester,
        const TunnelSettings(core: CoreEngine.torReverse),
        const SettingsScreen(),
      );

      await tester.tap(find.text(l10n.protocol));
      await tester.pumpAndSettle();

      expect(find.text(l10n.protocolGoolDesc), findsOneWidget);
      expect(find.text(l10n.protocolMimDesc), findsOneWidget);
      expect(find.text(l10n.protocolGoolClassicDesc), findsNothing);
      expect(find.text(l10n.protocolWireGuardDesc), findsNothing);
    });
  });

  group('advanced screen', () {
    testWidgets('the tls rows of the new core are all there', (tester) async {
      final l10n = await _open(
        tester,
        const TunnelSettings(),
        const AdvancedScreen(),
      );

      for (final title in <String>[
        l10n.ech,
        l10n.echDns,
        l10n.echDomain,
        l10n.fragment,
        l10n.tlsGroups,
        l10n.tlsCiphers,
        l10n.grease,
        l10n.apiAddress,
      ]) {
        expect(find.text(title), findsOneWidget, reason: title);
      }
      expect(find.text(l10n.wiwSection), findsNothing);
    });

    testWidgets('classic gool shows its hops here and gool does not', (
      tester,
    ) async {
      final l10n = await _open(
        tester,
        const TunnelSettings(protocol: CoreProtocol.goolClassic),
        const AdvancedScreen(),
      );
      expect(find.text(l10n.wiwSection), findsOneWidget);
    });

    testWidgets('the warp api address is checked as the core checks it', (
      tester,
    ) async {
      final l10n = await _open(
        tester,
        const TunnelSettings(),
        const AdvancedScreen(),
      );

      await _edit(tester, l10n, l10n.apiAddress, '188.114.97.6:0');
      expect(find.text(l10n.apiAddressRefusal), findsOneWidget);

      await tester.enterText(find.byType(CupertinoTextField), '188.114.97.6');
      await tester.tap(find.text(l10n.save));
      await tester.pumpAndSettle();

      expect(_current(tester, AdvancedScreen).apiAddress, '188.114.97.6');
    });

    testWidgets('the ech resolver opens only once ech is on', (tester) async {
      final l10n = await _open(
        tester,
        const TunnelSettings(),
        const AdvancedScreen(),
      );

      await tester.tap(find.text(l10n.echDns));
      await tester.pumpAndSettle();
      expect(find.byType(CupertinoTextField), findsNothing);

      final echSwitch = find.descendant(
        of: find
            .ancestor(
              of: find.text(l10n.ech),
              matching: find.byType(GestureDetector),
            )
            .first,
        matching: find.byType(CupertinoSwitch),
      );
      await tester.tap(echSwitch);
      await tester.pumpAndSettle();
      expect(_current(tester, AdvancedScreen).echMode, EchMode.auto);

      await _edit(tester, l10n, l10n.echDns, 'dns.google');
      expect(find.text(l10n.echDnsRefusal), findsOneWidget);

      await tester.enterText(
        find.byType(CupertinoTextField),
        'https://doq.dns4all.eu/dns-query@address=2.2.2.2',
      );
      await tester.tap(find.text(l10n.save));
      await tester.pumpAndSettle();
      expect(
        _current(tester, AdvancedScreen).echDns,
        'https://doq.dns4all.eu/dns-query@address=2.2.2.2',
      );
    });

    testWidgets('grease and the cipher list belong to a custom fingerprint', (
      tester,
    ) async {
      final l10n = await _open(
        tester,
        const TunnelSettings(),
        const AdvancedScreen(),
      );

      CupertinoSwitch greaseSwitch() => tester.widget<CupertinoSwitch>(
        find.descendant(
          of: find
              .ancestor(
                of: find.text(l10n.grease),
                matching: find.byType(GestureDetector),
              )
              .first,
          matching: find.byType(CupertinoSwitch),
        ),
      );

      expect(greaseSwitch().onChanged, isNull);
      expect(greaseSwitch().value, isTrue);

      await tester.tap(find.text(l10n.tlsFingerprint));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.fingerprintFirefox));
      await tester.pumpAndSettle();
      var settings = _current(tester, AdvancedScreen);
      expect(settings.tlsFingerprint, TlsFingerprint.firefox);
      expect(greaseSwitch().value, isFalse);
      expect(settings.toCoreArguments(), contains('--disable-grease'));

      await tester.tap(find.text(l10n.tlsFingerprint));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.fingerprintCustom));
      await tester.pumpAndSettle();
      expect(greaseSwitch().onChanged, isNotNull);

      await tester.tap(
        find.descendant(
          of: find
              .ancestor(
                of: find.text(l10n.grease),
                matching: find.byType(GestureDetector),
              )
              .first,
          matching: find.byType(CupertinoSwitch),
        ),
      );
      await tester.pumpAndSettle();
      settings = _current(tester, AdvancedScreen);
      expect(settings.grease, isFalse);
      expect(settings.toCoreArguments(), contains('--disable-grease'));
      expect(settings.toCoreArguments(), isNot(contains('--tls-ciphers')));
    });

    for (final locale in const <Locale>[Locale('en'), Locale('fa')]) {
      testWidgets(
        'the screen lays out without overflow in ${locale.languageCode}',
        (tester) async {
          await _open(
            tester,
            const TunnelSettings(
              protocol: CoreProtocol.goolClassic,
              masqueSni: 'consumer-masque.cloudflareclient.com',
              echMode: EchMode.auto,
              echDns: 'https://doq.dns4all.eu/dns-query@address=2.2.2.2',
              tlsCiphers:
                  'ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256',
              apiAddress: '[2606:4700::1]:8443',
            ),
            const AdvancedScreen(),
            locale: locale,
          );
          expect(tester.takeException(), isNull);
        },
      );
    }
  });

  group('psiphon screen', () {
    testWidgets('the built-in edge lists are picked and saved', (tester) async {
      final l10n = await _open(
        tester,
        const TunnelSettings(core: CoreEngine.psiphon),
        const PsiphonScreen(),
      );

      expect(find.text(l10n.psiphonCdnSetsAll), findsOneWidget);

      await tester.tap(find.text(l10n.psiphonCdnSets));
      await tester.pumpAndSettle();
      await tester.tap(find.text('fastly'));
      await tester.tap(find.text('cloudflare'));
      await tester.pump();
      await tester.tap(find.text(l10n.save));
      await tester.pumpAndSettle();

      final settings = _current(tester, PsiphonScreen);
      expect(settings.psiphonCdnSetList, <String>['cloudflare', 'fastly']);
      expect(find.text('cloudflare +1'), findsOneWidget);
    });

    testWidgets('own addresses without lists say so', (tester) async {
      final l10n = await _open(
        tester,
        const TunnelSettings(
          core: CoreEngine.psiphon,
          psiphonCdnIps: '104.16.0.0/13',
        ),
        const PsiphonScreen(),
      );
      expect(find.text(l10n.psiphonCdnSetsNone), findsOneWidget);
    });
  });

  group('multi choice sheet', () {
    Widget host(ValueChanged<Set<String>> onSaved) => _app(
      Builder(
        builder: (context) => CupertinoButton(
          onPressed: () => showMultiChoiceSheet<String>(
            context: context,
            title: 'Lists',
            message: 'Pick some',
            selected: const <String>{'b'},
            options: const <PickerOption<String>>[
              PickerOption(value: 'a', title: 'a'),
              PickerOption(value: 'b', title: 'b', subtitle: 'second'),
              PickerOption(value: 'c', title: 'c'),
            ],
            cancelLabel: 'Cancel',
            saveLabel: 'Save',
            onSaved: onSaved,
          ),
          child: const Text('open'),
        ),
      ),
    );

    testWidgets('a tap picks and unpicks, and save hands the choice back', (
      tester,
    ) async {
      Set<String>? saved;
      await tester.pumpWidget(host((value) => saved = value));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('Pick some'), findsOneWidget);
      expect(find.text('second'), findsOneWidget);
      expect(find.byIcon(CupertinoIcons.check_mark), findsOneWidget);

      await tester.tap(find.text('a'));
      await tester.tap(find.text('b'));
      await tester.tap(find.text('c'));
      await tester.pump();
      expect(find.byIcon(CupertinoIcons.check_mark), findsNWidgets(2));

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(saved, <String>{'a', 'c'});
    });

    testWidgets('cancel hands nothing back', (tester) async {
      Set<String>? saved;
      await tester.pumpWidget(host((value) => saved = value));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('a'));
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(saved, isNull);
    });
  });
}
