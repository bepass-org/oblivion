import 'package:flutter/cupertino.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oblivion/data/models/geo_endpoint.dart';
import 'package:oblivion/data/models/tunnel_settings.dart';
import 'package:oblivion/data/models/tunnel_status.dart';
import 'package:oblivion/l10n/generated/app_localizations.dart';
import 'package:oblivion/presentation/providers/tunnel_providers.dart';
import 'package:oblivion/presentation/screens/home_screen.dart';

const _connected = TunnelStatus(stage: TunnelStage.connected);

GeoSnapshot _exit(String ip) => GeoSnapshot(
  exit: GeoEndpoint(
    ip: ip,
    countryCode: 'DE',
    country: 'Germany',
    isp: 'Cloudflare, Inc.',
    colo: 'FRA',
    warp: WarpStatus.on,
  ),
);

Widget _host(Widget child, {double width = 360}) {
  return CupertinoApp(
    supportedLocales: L10n.supportedLocales,
    localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
      L10n.delegate,
      GlobalCupertinoLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
    ],
    home: Center(
      child: SizedBox(width: width, height: 44, child: child),
    ),
  );
}

void main() {
  group('connection detail', () {
    testWidgets('fits the 44 pixel slot the home screen gives it', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          ConnectionDetail(status: _connected, geo: _exit('104.28.214.161')),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.text('WARP'), findsOneWidget);
    });

    testWidgets('an exit that is not warp by design shows no warp badge', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          ConnectionDetail(
            status: _connected,
            geo: _exit('104.28.214.161'),
            warpExit: false,
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.text('WARP'), findsNothing);
      expect(find.text('WARP OFF'), findsNothing);
    });

    testWidgets('a long ipv6 exit on a narrow phone still fits', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          ConnectionDetail(
            status: _connected,
            geo: _exit('2606:4700:110:88f0:af53:6034:7cd8:c9ad'),
          ),
          width: 300,
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });

  group('mode badge', () {
    for (final core in CoreEngine.values) {
      for (final protocol in CoreProtocol.values) {
        final mode = TunnelSettings(core: core, protocol: protocol).modeLabel;
        testWidgets('names what runs on a narrow phone: $mode', (tester) async {
          await tester.pumpWidget(
            _host(Center(child: ModeBadge(mode: mode)), width: 300),
          );
          await tester.pump();
          expect(tester.takeException(), isNull);
          expect(find.text(mode), findsOneWidget);
        });
      }
    }
  });

  group('warp exit', () {
    test('only the cores that leave through warp expect a warp exit', () {
      for (final core in <CoreEngine>[
        CoreEngine.aether,
        CoreEngine.psiphonReverse,
        CoreEngine.torReverse,
      ]) {
        expect(
          TunnelSettings(core: core).exitIsWarp,
          isTrue,
          reason: core.wire,
        );
      }
      for (final core in <CoreEngine>[
        CoreEngine.psiphon,
        CoreEngine.chain,
        CoreEngine.tor,
        CoreEngine.torChain,
      ]) {
        expect(
          TunnelSettings(core: core).exitIsWarp,
          isFalse,
          reason: core.wire,
        );
      }
    });
  });
}
