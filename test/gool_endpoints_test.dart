import 'package:flutter_test/flutter_test.dart';
import 'package:oblivion/data/models/tunnel_settings.dart';

TunnelSettings _gool({String outer = '', String inner = '', String endpoint = ''}) {
  return TunnelSettings(
    protocol: CoreProtocol.gool,
    wiwOuter: outer,
    wiwInner: inner,
    endpoint: endpoint,
  );
}

void main() {
  group('endpoint parsing', () {
    test('an address and a port are read together', () {
      expect(TunnelSettings.isValidEndpoint('162.159.192.1:2408'), isTrue);
      expect(
        TunnelSettings.endpointHost('162.159.192.1:2408'),
        '162.159.192.1',
      );
    });

    test('an address without a port is refused', () {
      expect(TunnelSettings.isValidEndpoint('162.159.192.1'), isFalse);
    });

    test('an impossible port is refused', () {
      expect(TunnelSettings.isValidEndpoint('162.159.192.1:0'), isFalse);
      expect(TunnelSettings.isValidEndpoint('162.159.192.1:70000'), isFalse);
      expect(TunnelSettings.isValidEndpoint('162.159.192.1:http'), isFalse);
      expect(TunnelSettings.isValidEndpoint('162.159.192.1:'), isFalse);
    });

    test('a port the core would refuse is refused here too', () {
      expect(TunnelSettings.isValidEndpoint('162.159.192.1: 2408'), isFalse);
      expect(TunnelSettings.isValidEndpoint('162.159.192.1:+2408'), isFalse);
      expect(TunnelSettings.isValidEndpoint('162.159.192.1:-1'), isFalse);
    });

    test('ipv6 is read when it is bracketed and carries its port', () {
      expect(
        TunnelSettings.isValidEndpoint('[2606:4700:d0::a29f:c001]:2408'),
        isTrue,
      );
      expect(
        TunnelSettings.endpointHost('[2606:4700:d0::a29f:c001]:2408'),
        '2606:4700:d0::a29f:c001',
      );
    });

    test('a bare ipv6 address is refused because it carries no port', () {
      expect(
        TunnelSettings.isValidEndpoint('2606:4700:d0::a29f:c001'),
        isFalse,
      );
    });

    test('a hostname is not an endpoint', () {
      expect(TunnelSettings.isValidEndpoint('example.com:443'), isFalse);
      expect(TunnelSettings.isValidEndpoint(''), isFalse);
      expect(TunnelSettings.isValidEndpoint('   '), isFalse);
    });

    test('surrounding whitespace is forgiven', () {
      expect(TunnelSettings.isValidEndpoint('  162.159.192.1:2408  '), isTrue);
    });
  });

  group('gool hops', () {
    test('both hops reach the core when they are named by hand', () {
      final args = _gool(
        outer: '162.159.192.1:2408',
        inner: '188.114.96.1:894',
      ).toCoreArguments();

      expect(args, containsAllInOrder(['--wiw-outer', '162.159.192.1:2408']));
      expect(args, containsAllInOrder(['--wiw-inner', '188.114.96.1:894']));
      expect(args, isNot(contains('--wiw-scan')));
    });

    test('naming one hop leaves the other to the scan', () {
      final args = _gool(outer: '162.159.192.1:2408').toCoreArguments();

      expect(args, containsAllInOrder(['--wiw-outer', '162.159.192.1:2408']));
      expect(args, isNot(contains('--wiw-inner')));
      expect(args, isNot(contains('--wiw-scan')));
    });

    test('naming neither hop asks the core to scan for both', () {
      final args = _gool().toCoreArguments();

      expect(args, contains('--wiw-scan'));
      expect(args, isNot(contains('--wiw-outer')));
      expect(args, isNot(contains('--wiw-inner')));
    });

    test('the masque endpoint never becomes a gool hop', () {
      final args = _gool(endpoint: '162.159.198.1:443').toCoreArguments();

      expect(args, isNot(contains('--peer')));
      expect(args, contains('--wiw-scan'));
    });

    test('the wireguard peer is not sent alongside the gool hops', () {
      final args = TunnelSettings(
        protocol: CoreProtocol.gool,
        wgEndpoint: '162.159.192.1:2408',
      ).toCoreArguments();

      expect(args, isNot(contains('--wg-peer')));
    });

    test('plain wireguard still takes its own peer', () {
      final args = TunnelSettings(
        protocol: CoreProtocol.wireguard,
        wgEndpoint: '162.159.192.1:2408',
      ).toCoreArguments();

      expect(args, containsAllInOrder(['--wg-peer', '162.159.192.1:2408']));
      expect(args, isNot(contains('--wiw-scan')));
    });

    test('masque still takes its manual gateway', () {
      final args = TunnelSettings(
        endpoint: '162.159.198.1:443',
      ).toCoreArguments();

      expect(args, containsAllInOrder(['--peer', '162.159.198.1:443']));
      expect(args, isNot(contains('--wiw-scan')));
    });

    test('two hops on one edge are caught before the core sees them', () {
      expect(
        _gool(
          outer: '162.159.192.1:2408',
          inner: '162.159.192.1:894',
        ).wiwHopsCollide,
        isTrue,
      );
      expect(
        _gool(
          outer: '162.159.192.1:2408',
          inner: '188.114.96.1:894',
        ).wiwHopsCollide,
        isFalse,
      );
      expect(_gool(outer: '162.159.192.1:2408').wiwHopsCollide, isFalse);
    });

    test('hops set on another protocol stay out of the payload', () {
      final settings = TunnelSettings(
        wiwOuter: '162.159.192.1:2408',
        wiwInner: '188.114.96.1:894',
      );

      expect(settings.toPlatformPayload()['wiwOuter'], '');
      expect(settings.toPlatformPayload()['wiwInner'], '');
      expect(settings.toCoreArguments(), isNot(contains('--wiw-outer')));
    });

    test('the payload carries the trimmed hops on gool', () {
      final payload = _gool(
        outer: '  162.159.192.1:2408 ',
        inner: ' 188.114.96.1:894  ',
      ).toPlatformPayload();

      expect(payload['wiwOuter'], '162.159.192.1:2408');
      expect(payload['wiwInner'], '188.114.96.1:894');
    });
  });
}
