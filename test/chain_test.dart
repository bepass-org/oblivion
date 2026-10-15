import 'package:flutter_test/flutter_test.dart';
import 'package:oblivion/data/models/tunnel_settings.dart';

TunnelSettings _chain({int socksPort = 1819, bool allowLan = false}) {
  return TunnelSettings(
    psiphon: CarrierMode.chain,
    socksPort: socksPort,
    allowLan: allowLan,
  );
}

String? _valueAfter(List<String> args, String flag) {
  final at = args.indexOf(flag);
  if (at < 0 || at + 1 >= args.length) return null;
  return args[at + 1];
}

void main() {
  group('chain engine', () {
    test('a chain runs both cores and leads with aether', () {
      final settings = _chain();
      expect(settings.usesChain, isTrue);
      expect(settings.usesAether, isTrue);
      expect(settings.usesPsiphon, isTrue);
      expect(settings.psiphonOnly, isFalse);
    });

    test('psiphon on its own runs no aether', () {
      const settings = TunnelSettings(psiphon: CarrierMode.only);
      expect(settings.usesAether, isFalse);
      expect(settings.psiphonOnly, isTrue);
      expect(settings.toCoreArguments(), isEmpty);
    });

    test('aether on its own runs no psiphon', () {
      const settings = TunnelSettings();
      expect(settings.usesPsiphon, isFalse);
      expect(settings.aetherSocksPort, settings.socksPort);
    });

    test('chaining moves aether aside so psiphon holds the public port', () {
      final settings = _chain(socksPort: 1819);
      expect(settings.socksPort, 1819);
      expect(settings.httpProxyPort, 1820);
      expect(settings.aetherSocksPort, 1829);
      expect(settings.aetherHttpProxyPort, 1830);
    });

    test('the core is told to listen on the inner port', () {
      final args = _chain(socksPort: 1819).toCoreArguments();
      expect(_valueAfter(args, '--bind'), '127.0.0.1:1829');
      expect(_valueAfter(args, '--http-proxy'), '127.0.0.1:1830');
    });

    test('an unchained aether keeps the public port', () {
      const args = TunnelSettings();
      expect(_valueAfter(args.toCoreArguments(), '--bind'), '127.0.0.1:1819');
    });

    test('a chained inner port stays on loopback even when lan is allowed', () {
      final settings = _chain(allowLan: true);
      expect(settings.aetherBindAddress, startsWith('127.0.0.1:'));
      expect(settings.bindAddress, startsWith('0.0.0.0:'));
    });

    test('a socks port near the ceiling shifts downwards', () {
      final settings = _chain(socksPort: 65530);
      expect(settings.aetherSocksPort, 65520);
      expect(settings.aetherHttpProxyPort, 65521);
    });

    test('psiphon is pointed at the port aether listens on', () {
      expect(_chain(socksPort: 1819).chainUpstreamUrl,
          'socks5://127.0.0.1:1829');
    });

    test('a chain leaves the masque transport exactly as it was picked', () {
      final h3 = TunnelSettings(
        psiphon: CarrierMode.chain,
        transport: MasqueTransport.http3,
      );
      expect(h3.usesHttp2, isFalse);
      expect(h3.toCoreArguments(), isNot(contains('--h2')));
      expect(h3.toPlatformPayload()['transport'], 'h3');

      final h2 = TunnelSettings(
        psiphon: CarrierMode.chain,
        transport: MasqueTransport.http2,
      );
      expect(h2.usesHttp2, isTrue);
      expect(h2.toCoreArguments(), contains('--h2'));
    });

    test('the chain still carries the aether protocol flags', () {
      final classic = TunnelSettings(
        psiphon: CarrierMode.chain,
        protocol: CoreProtocol.goolClassic,
        wiwOuter: '162.159.192.1:2408',
      ).toCoreArguments();

      expect(classic, contains('--gool-classic'));
      expect(
        classic,
        containsAllInOrder(['--wiw-outer', '162.159.192.1:2408']),
      );

      final gool = TunnelSettings(
        psiphon: CarrierMode.chain,
        protocol: CoreProtocol.gool,
        goolPeer: '162.159.192.1:2408',
      ).toCoreArguments();

      expect(gool, contains('--gool'));
      expect(gool, containsAllInOrder(['--gool-peer', '162.159.192.1:2408']));
    });
  });

  group('tor as a core, and every chain either way round', () {
    test(
      'tor inside the tunnel moves aether aside, exactly as psiphon does',
      () {
        const settings = TunnelSettings(
          tor: CarrierMode.chain,
          socksPort: 1819,
        );
        expect(settings.usesTor, isTrue);
        expect(settings.usesAether, isTrue);
        expect(settings.carriesInside, isTrue);
        expect(settings.aetherSocksPort, 1829);
        expect(
          _valueAfter(settings.toCoreArguments(), '--bind'),
          '127.0.0.1:1829',
        );
      },
    );

    test('tor on its own runs no aether', () {
      const settings = TunnelSettings(tor: CarrierMode.only);
      expect(settings.usesAether, isFalse);
      expect(settings.toCoreArguments(), isEmpty);
      expect(settings.aetherSocksPort, settings.socksPort);
    });

    test('dialled through tor or psiphon, aether keeps the public port', () {
      for (final settings in const <TunnelSettings>[
        TunnelSettings(tor: CarrierMode.reverse),
        TunnelSettings(psiphon: CarrierMode.reverse),
      ]) {
        final reason = settings.modeLabel;
        expect(settings.dialsThrough, isTrue, reason: reason);
        expect(settings.carriesInside, isFalse, reason: reason);
        expect(settings.aetherSocksPort, settings.socksPort, reason: reason);
      }
    });

    test(
      'through a carrier only masque over http/2 runs, without rewriting the choice',
      () {
        const settings = TunnelSettings(
          tor: CarrierMode.reverse,
          protocol: CoreProtocol.wireguard,
        );
        expect(settings.protocol, CoreProtocol.wireguard);
        expect(settings.effectiveProtocol, CoreProtocol.masque);
        expect(settings.usesHttp2, isTrue);
        final args = settings.toCoreArguments();
        expect(args, contains('--masque'));
        expect(args, contains('--h2'));
        expect(args, isNot(contains('--wg')));

        final back = settings.copyWith(tor: CarrierMode.off);
        expect(back.effectiveProtocol, CoreProtocol.wireguard);
      },
    );

    test('a core saved by an earlier version keeps its places', () {
      expect(CarrierMode.fromLegacyCore('aether', 'chain'), (
        CarrierMode.off,
        CarrierMode.chain,
      ));
      expect(CarrierMode.fromLegacyCore('chain', 'reverse'), (
        CarrierMode.off,
        CarrierMode.reverse,
      ));
      expect(CarrierMode.fromLegacyCore('psiphon', 'only'), (
        CarrierMode.off,
        CarrierMode.only,
      ));
      expect(CarrierMode.fromLegacyCore('chain', 'off'), (
        CarrierMode.chain,
        CarrierMode.off,
      ));
      expect(CarrierMode.fromLegacyCore(null, null), (
        CarrierMode.off,
        CarrierMode.off,
      ));
      expect(CarrierMode.fromLegacyCore('tor-chain', null), (
        CarrierMode.off,
        CarrierMode.chain,
      ));
      expect(CarrierMode.fromLegacyCore('psiphon-reverse', null), (
        CarrierMode.reverse,
        CarrierMode.off,
      ));
      expect(CarrierMode.fromLegacyCore('psiphon', null), (
        CarrierMode.only,
        CarrierMode.off,
      ));
    });
  });
}
