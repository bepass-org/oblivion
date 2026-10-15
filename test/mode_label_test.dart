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
        'GOOL H3',
      );
      expect(
        const TunnelSettings(
          protocol: CoreProtocol.gool,
          transport: MasqueTransport.http2,
        ).modeLabel,
        'GOOL H2',
      );
      expect(
        const TunnelSettings(protocol: CoreProtocol.goolClassic).modeLabel,
        'GOOL CLASSIC',
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
        const TunnelSettings(psiphon: CarrierMode.only).modeLabel,
        'PSIPHON',
      );
    });

    test('a chain names both halves in the order traffic takes them', () {
      expect(
        const TunnelSettings(psiphon: CarrierMode.chain).modeLabel,
        'MASQUE H3 + PSIPHON',
      );
    });

    test('tor is shown on whichever side it sits', () {
      expect(
        const TunnelSettings(tor: CarrierMode.chain).modeLabel,
        'MASQUE H3 + TOR',
      );
      expect(
        const TunnelSettings(tor: CarrierMode.reverse).modeLabel,
        'TOR + MASQUE H2',
      );
      expect(const TunnelSettings(tor: CarrierMode.only).modeLabel, 'TOR');
    });

    test('psiphon is shown on whichever side it sits', () {
      expect(
        const TunnelSettings(psiphon: CarrierMode.reverse).modeLabel,
        'PSIPHON + MASQUE H2',
      );
    });

    test('gool through a carrier keeps its name on http2', () {
      expect(
        const TunnelSettings(
          tor: CarrierMode.reverse,
          protocol: CoreProtocol.gool,
        ).modeLabel,
        'TOR + GOOL H2',
      );
      expect(
        const TunnelSettings(
          psiphon: CarrierMode.reverse,
          protocol: CoreProtocol.goolClassic,
        ).modeLabel,
        'PSIPHON + MASQUE H2',
      );
    });

    test('a scan mode saved under the old name still reads', () {
      expect(ScanMode.fromWire('stealth'), ScanMode.verified);
      expect(ScanMode.fromWire('verified'), ScanMode.verified);
    });
  });
}
