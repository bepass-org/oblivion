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
}
