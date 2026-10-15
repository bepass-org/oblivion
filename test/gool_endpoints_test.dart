import 'package:flutter_test/flutter_test.dart';
import 'package:oblivion/data/models/tunnel_settings.dart';

TunnelSettings _classic({
  String outer = '',
  String inner = '',
  String endpoint = '',
}) {
  return TunnelSettings(
    protocol: CoreProtocol.goolClassic,
    wiwOuter: outer,
    wiwInner: inner,
    endpoint: endpoint,
  );
}

String? _valueAfter(List<String> args, String flag) {
  final at = args.indexOf(flag);
  if (at < 0 || at + 1 >= args.length) return null;
  return args[at + 1];
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

  group('classic gool hops', () {
    test('classic gool asks the core for wireguard inside wireguard', () {
      final args = _classic().toCoreArguments();

      expect(args, contains('--gool-classic'));
      expect(args, isNot(contains('--gool')));
      expect(args, isNot(contains('--masque')));
    });

    test('both hops reach the core when they are named by hand', () {
      final args = _classic(
        outer: '162.159.192.1:2408',
        inner: '188.114.96.1:894',
      ).toCoreArguments();

      expect(args, containsAllInOrder(['--wiw-outer', '162.159.192.1:2408']));
      expect(args, containsAllInOrder(['--wiw-inner', '188.114.96.1:894']));
      expect(args, isNot(contains('--wiw-scan')));
    });

    test('naming one hop leaves the other to the scan', () {
      final args = _classic(outer: '162.159.192.1:2408').toCoreArguments();

      expect(args, containsAllInOrder(['--wiw-outer', '162.159.192.1:2408']));
      expect(args, isNot(contains('--wiw-inner')));
      expect(args, isNot(contains('--wiw-scan')));
    });

    test('naming neither hop asks the core to scan for both', () {
      final args = _classic().toCoreArguments();

      expect(args, contains('--wiw-scan'));
      expect(args, isNot(contains('--wiw-outer')));
      expect(args, isNot(contains('--wiw-inner')));
    });

    test('the masque endpoint never becomes a classic gool hop', () {
      final args = _classic(endpoint: '162.159.198.1:443').toCoreArguments();

      expect(args, isNot(contains('--peer')));
      expect(args, contains('--wiw-scan'));
    });

    test('the wireguard peer is not sent alongside the gool hops', () {
      final args = TunnelSettings(
        protocol: CoreProtocol.goolClassic,
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
        _classic(
          outer: '162.159.192.1:2408',
          inner: '162.159.192.1:894',
        ).wiwHopsCollide,
        isTrue,
      );
      expect(
        _classic(
          outer: '162.159.192.1:2408',
          inner: '188.114.96.1:894',
        ).wiwHopsCollide,
        isFalse,
      );
      expect(_classic(outer: '162.159.192.1:2408').wiwHopsCollide, isFalse);
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

    test('the payload carries the trimmed hops on classic gool', () {
      final payload = _classic(
        outer: '  162.159.192.1:2408 ',
        inner: ' 188.114.96.1:894  ',
      ).toPlatformPayload();

      expect(payload['wiwOuter'], '162.159.192.1:2408');
      expect(payload['wiwInner'], '188.114.96.1:894');
    });
  });
  group('gool over masque', () {
    test('gool asks the core for wireguard carried inside masque', () {
      final args = const TunnelSettings(
        protocol: CoreProtocol.gool,
      ).toCoreArguments();

      expect(args, contains('--gool'));
      expect(args, isNot(contains('--gool-classic')));
      expect(args, isNot(contains('--wiw-scan')));
      expect(args, isNot(contains('--keepalive')));
      expect(args, isNot(contains('--no-profile-retry')));
    });

    test('the masque endpoint is the gateway gool scans past', () {
      final args = const TunnelSettings(
        protocol: CoreProtocol.gool,
        endpoint: ' 162.159.198.1:443 ',
      ).toCoreArguments();

      expect(_valueAfter(args, '--peer'), '162.159.198.1:443');
    });

    test('the classic hops stay out of gool over masque', () {
      const settings = TunnelSettings(
        protocol: CoreProtocol.gool,
        wiwOuter: '162.159.192.1:2408',
        wiwInner: '188.114.96.1:894',
      );
      final args = settings.toCoreArguments();

      expect(args, isNot(contains('--wiw-outer')));
      expect(args, isNot(contains('--wiw-inner')));
      expect(settings.toPlatformPayload()['wiwOuter'], '');
      expect(settings.toPlatformPayload()['wiwInner'], '');
    });

    test('the wireguard hop inside the tunnel is named only when given', () {
      expect(
        const TunnelSettings(
          protocol: CoreProtocol.gool,
        ).toCoreArguments(),
        isNot(contains('--gool-peer')),
      );

      final args = const TunnelSettings(
        protocol: CoreProtocol.gool,
        goolPeer: '  162.159.192.1:2408 ',
      ).toCoreArguments();
      expect(_valueAfter(args, '--gool-peer'), '162.159.192.1:2408');
    });

    test('the wireguard hop of gool never reaches another protocol', () {
      for (final protocol in <CoreProtocol>[
        CoreProtocol.masque,
        CoreProtocol.wireguard,
        CoreProtocol.goolClassic,
        CoreProtocol.mim,
      ]) {
        final args = TunnelSettings(
          protocol: protocol,
          goolPeer: '162.159.192.1:2408',
        ).toCoreArguments();
        expect(args, isNot(contains('--gool-peer')), reason: protocol.wire);
      }
    });

    test('gool rides the masque carrier that was picked', () {
      const h3 = TunnelSettings(protocol: CoreProtocol.gool);
      expect(h3.isMasque, isTrue);
      expect(h3.usesHttp2, isFalse);
      expect(h3.toCoreArguments(), isNot(contains('--h2')));

      const h2 = TunnelSettings(
        protocol: CoreProtocol.gool,
        transport: MasqueTransport.http2,
        h2Endpoint: '162.159.198.2:443',
      );
      expect(h2.usesHttp2, isTrue);
      final args = h2.toCoreArguments();
      expect(args, contains('--h2'));
      expect(_valueAfter(args, '--h2-peer'), '162.159.198.2:443');
    });

    test('gool is no wireguard scan of its own', () {
      const settings = TunnelSettings(
        protocol: CoreProtocol.gool,
        wgEndpoint: '162.159.192.1:2408',
      );
      expect(settings.usesWireGuard, isFalse);
      expect(settings.toCoreArguments(), isNot(contains('--wg-peer')));
    });

    test('a carrier around the tunnel keeps gool and drops what needs udp', () {
      for (final around in const <TunnelSettings>[
        TunnelSettings(tor: CarrierMode.reverse),
        TunnelSettings(psiphon: CarrierMode.reverse),
      ]) {
        final reason = around.modeLabel;
        final gool = around.copyWith(protocol: CoreProtocol.gool);
        expect(gool.effectiveProtocol, CoreProtocol.gool, reason: reason);
        expect(gool.usesHttp2, isTrue, reason: reason);
        expect(gool.toCoreArguments(), contains('--gool'), reason: reason);
        expect(gool.toCoreArguments(), contains('--h2'), reason: reason);

        final classic = around.copyWith(protocol: CoreProtocol.goolClassic);
        expect(classic.effectiveProtocol, CoreProtocol.masque, reason: reason);
        expect(classic.protocolRunsAsMasque, isTrue, reason: reason);
        expect(
          classic.toCoreArguments(),
          isNot(contains('--gool-classic')),
          reason: reason,
        );
      }
    });

    test('only wireguard and classic gool need udp to reach warp', () {
      expect(TunnelSettings.needsUdpToWarp(CoreProtocol.wireguard), isTrue);
      expect(TunnelSettings.needsUdpToWarp(CoreProtocol.goolClassic), isTrue);
      expect(TunnelSettings.needsUdpToWarp(CoreProtocol.gool), isFalse);
      expect(TunnelSettings.needsUdpToWarp(CoreProtocol.masque), isFalse);
      expect(TunnelSettings.needsUdpToWarp(CoreProtocol.mim), isFalse);
    });

    test('both gools keep their own wire names', () {
      expect(CoreProtocol.fromWire('gool'), CoreProtocol.gool);
      expect(CoreProtocol.fromWire('gool-classic'), CoreProtocol.goolClassic);
      expect(CoreProtocol.gool.wire, 'gool');
      expect(CoreProtocol.goolClassic.wire, 'gool-classic');
    });
  });
}
