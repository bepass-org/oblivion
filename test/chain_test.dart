import 'package:flutter_test/flutter_test.dart';
import 'package:oblivion/data/models/tunnel_settings.dart';

TunnelSettings _chain({int socksPort = 1819, bool allowLan = false}) {
  return TunnelSettings(
    core: CoreEngine.chain,
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
      const settings = TunnelSettings(core: CoreEngine.psiphon);
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
        core: CoreEngine.chain,
        transport: MasqueTransport.http3,
      );
      expect(h3.usesHttp2, isFalse);
      expect(h3.toCoreArguments(), isNot(contains('--h2')));
      expect(h3.toPlatformPayload()['transport'], 'h3');

      final h2 = TunnelSettings(
        core: CoreEngine.chain,
        transport: MasqueTransport.http2,
      );
      expect(h2.usesHttp2, isTrue);
      expect(h2.toCoreArguments(), contains('--h2'));
    });

    test('the chain still carries the aether protocol flags', () {
      final args = TunnelSettings(
        core: CoreEngine.chain,
        protocol: CoreProtocol.gool,
        wiwOuter: '162.159.192.1:2408',
      ).toCoreArguments();

      expect(args, contains('--gool'));
      expect(args, containsAllInOrder(['--wiw-outer', '162.159.192.1:2408']));
    });
  });

  group('tor as a core, and every chain either way round', () {
    test(
      'tor inside the tunnel moves aether aside, exactly as psiphon does',
      () {
        const settings = TunnelSettings(
          core: CoreEngine.torChain,
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
      const settings = TunnelSettings(core: CoreEngine.tor);
      expect(settings.usesAether, isFalse);
      expect(settings.toCoreArguments(), isEmpty);
      expect(settings.aetherSocksPort, settings.socksPort);
    });

    test('dialled through tor or psiphon, aether keeps the public port', () {
      for (final core in [CoreEngine.torReverse, CoreEngine.psiphonReverse]) {
        final settings = TunnelSettings(core: core);
        expect(settings.dialsThrough, isTrue, reason: core.wire);
        expect(settings.carriesInside, isFalse, reason: core.wire);
        expect(settings.aetherSocksPort, settings.socksPort, reason: core.wire);
      }
    });

    test(
      'through a carrier only masque over http/2 runs, without rewriting the choice',
      () {
        const settings = TunnelSettings(
          core: CoreEngine.torReverse,
          protocol: CoreProtocol.wireguard,
        );
        expect(settings.protocol, CoreProtocol.wireguard);
        expect(settings.effectiveProtocol, CoreProtocol.masque);
        expect(settings.usesHttp2, isTrue);
        final args = settings.toCoreArguments();
        expect(args, contains('--masque'));
        expect(args, contains('--h2'));
        expect(args, isNot(contains('--wg')));

        final back = settings.copyWith(core: CoreEngine.aether);
        expect(back.effectiveProtocol, CoreProtocol.wireguard);
      },
    );

    test('tor saved as a switch beside the core becomes the core', () {
      expect(CoreEngine.migrate('aether', 'chain'), CoreEngine.torChain);
      expect(CoreEngine.migrate('chain', 'reverse'), CoreEngine.torReverse);
      expect(CoreEngine.migrate('psiphon', 'only'), CoreEngine.tor);
      expect(CoreEngine.migrate('chain', 'off'), CoreEngine.chain);
      expect(CoreEngine.migrate(null, null), CoreEngine.aether);
      expect(CoreEngine.fromWire('tor-chain'), CoreEngine.torChain);
    });
  });
}
