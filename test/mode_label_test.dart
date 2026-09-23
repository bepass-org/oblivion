import 'package:flutter_test/flutter_test.dart';
import 'package:oblivion/data/models/tunnel_settings.dart';

void main() {
  group('mode label', () {
    test('a plain masque tunnel names its carrier', () {
      expect(const TunnelSettings().modeLabel, 'MASQUE H3');
      expect(
        const TunnelSettings(transport: MasqueTransport.http2).modeLabel,
        'MASQUE H2',
      );
    });

    test('every protocol has a name of its own', () {
      expect(
        const TunnelSettings(protocol: CoreProtocol.gool).modeLabel,
        'GOOL',
      );
      expect(
        const TunnelSettings(protocol: CoreProtocol.wireguard).modeLabel,
        'WARP',
      );
      expect(
        const TunnelSettings(protocol: CoreProtocol.mim).modeLabel,
        'MIM H3',
      );
    });

    test('psiphon on its own replaces the carrier', () {
      expect(
        const TunnelSettings(core: CoreEngine.psiphon).modeLabel,
        'PSIPHON',
      );
    });

    test('a chain names both halves in the order traffic takes them', () {
      expect(
        const TunnelSettings(core: CoreEngine.chain).modeLabel,
        'MASQUE H3 + PSIPHON',
      );
    });

    test('tor is shown on whichever side it sits', () {
      expect(
        const TunnelSettings(core: CoreEngine.torChain).modeLabel,
        'MASQUE H3 + TOR',
      );
      expect(
        const TunnelSettings(core: CoreEngine.torReverse).modeLabel,
        'TOR + MASQUE H2',
      );
      expect(const TunnelSettings(core: CoreEngine.tor).modeLabel, 'TOR');
    });

    test('psiphon is shown on whichever side it sits', () {
      expect(
        const TunnelSettings(core: CoreEngine.psiphonReverse).modeLabel,
        'PSIPHON + MASQUE H2',
      );
    });

    test('a scan mode saved under the old name still reads', () {
      expect(ScanMode.fromWire('stealth'), ScanMode.verified);
      expect(ScanMode.fromWire('verified'), ScanMode.verified);
    });
  });
}
