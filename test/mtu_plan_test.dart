import 'package:flutter_test/flutter_test.dart';
import 'package:oblivion/data/models/mtu_plan.dart';
import 'package:oblivion/data/models/tunnel_settings.dart';

MtuPlan _plan(TunnelSettings settings, int pathMtu) =>
    MtuPlan.resolve(settings: settings, pathMtu: pathMtu);

void main() {
  group('mtu plan', () {
    test('a clean ethernet path keeps the masque packet size the core ships', () {
      final plan = _plan(const TunnelSettings(), 1500);

      expect(plan.profile, MtuProfile.masqueH3);
      expect(plan.overhead, 72);
      expect(plan.innerMtu, 1280);
      expect(plan.tunnelMtu, 1280);
      expect(plan.coreMtu, 1280);
      expect(plan.pathLimited, isFalse);
    });

    test('a path with room to spare is capped by the core, not the path', () {
      final plan = _plan(const TunnelSettings(), 1400);

      expect(plan.innerMtu, 1280);
      expect(plan.pathLimited, isFalse);
      expect(plan.outerPacket, lessThanOrEqualTo(1400));
    });

    test('a narrow path pulls the packet size down to what fits', () {
      final plan = _plan(const TunnelSettings(), 1340);

      expect(plan.innerMtu, 1268);
      expect(plan.coreMtu, 1268);
      expect(plan.pathLimited, isTrue);
      expect(plan.outerPacket, lessThanOrEqualTo(1340));
    });

    test('a path too small for the tun floor still tells the core to shrink', () {
      final plan = _plan(const TunnelSettings(), 1300);

      expect(plan.innerMtu, 1228);
      expect(plan.coreMtu, 1228);
      expect(plan.tunnelMtu, kTunnelMtuMin);
      expect(plan.belowFloor, isTrue);
    });

    test('a path that cannot carry the quic handshake is called out', () {
      expect(_plan(const TunnelSettings(), 1400).handshakeAtRisk, isFalse);
      expect(_plan(const TunnelSettings(), 1200).handshakeAtRisk, isTrue);
    });

    test('ipv6 pays twenty more bytes per packet', () {
      final v4 = _plan(const TunnelSettings(), 1340);
      final v6 = _plan(const TunnelSettings(ipVersion: IpVersion.v6), 1340);

      expect(v6.overhead - v4.overhead, 20);
      expect(v6.innerMtu, lessThan(v4.innerMtu));
    });

    test('http2 rides a tcp stream, so the path does not cap the packet', () {
      final plan = _plan(
        const TunnelSettings(transport: MasqueTransport.http2),
        1360,
      );

      expect(plan.profile, MtuProfile.masqueH2);
      expect(plan.innerMtu, 1500);
      expect(plan.tunnelMtu, 1500);
      expect(plan.pathLimited, isFalse);
    });

    test('wireguard rounds down to the padding boundary', () {
      final plan = _plan(
        const TunnelSettings(protocol: CoreProtocol.wireguard),
        1300,
      );

      expect(plan.overhead, 60);
      expect(plan.innerMtu, 1232);
      expect(plan.innerMtu % 16, 0);
      expect(plan.coreMtu, 0);
    });

    test('two wireguard hops pay for both', () {
      final plan = _plan(
        const TunnelSettings(protocol: CoreProtocol.goolClassic),
        1500,
      );

      expect(plan.profile, MtuProfile.goolClassic);
      expect(plan.overhead, 120);
      expect(plan.innerMtu, 1200);
      expect(plan.coreMtu, 0);
    });

    test('gool pays for wireguard and for the masque carrier around it', () {
      final roomy = _plan(const TunnelSettings(protocol: CoreProtocol.gool), 1500);

      expect(roomy.profile, MtuProfile.goolH3);
      expect(roomy.overhead, 132);
      expect(roomy.innerMtu, 1200);
      expect(roomy.coreMtu, 0);
      expect(roomy.pathLimited, isFalse);

      final narrow = _plan(
        const TunnelSettings(protocol: CoreProtocol.gool),
        1300,
      );
      expect(narrow.innerMtu, 1168);
      expect(narrow.innerMtu % 16, 0);
      expect(narrow.pathLimited, isTrue);
      expect(narrow.outerPacket, lessThanOrEqualTo(1300));
      expect(narrow.coreMtu, 0);
    });

    test('gool over http2 rides a stream, and over quic needs its handshake', () {
      final stream = _plan(
        const TunnelSettings(
          protocol: CoreProtocol.gool,
          transport: MasqueTransport.http2,
        ),
        1300,
      );
      expect(stream.profile, MtuProfile.goolH2);
      expect(stream.innerMtu, 1200);
      expect(stream.pathLimited, isFalse);

      expect(
        _plan(const TunnelSettings(protocol: CoreProtocol.gool), 1200)
            .handshakeAtRisk,
        isTrue,
      );
    });

    test('without a measurement the plan stays on the shipped defaults', () {
      final plan = _plan(const TunnelSettings(), 0);

      expect(plan.measured, isFalse);
      expect(plan.innerMtu, 1280);
      expect(plan.pathLimited, isFalse);
    });

    test('a hopeless path never proposes a packet the core would refuse', () {
      final plan = _plan(const TunnelSettings(), 300);

      expect(plan.coreMtu, greaterThanOrEqualTo(kCoreMtuMin));
      expect(plan.tunnelMtu, kTunnelMtuMin);
    });
  });
}
