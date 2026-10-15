import 'tunnel_settings.dart';

const int kTunnelMtuMin = 1280;
const int kTunnelMtuMax = 9000;
const int kCoreMtuMin = 576;
const int kCoreMtuMax = 1500;

enum MtuCarrier { datagram, stream }

class MtuProfile {
  const MtuProfile({
    required this.label,
    required this.carrier,
    required this.overheadV4,
    required this.overheadV6,
    required this.ceiling,
    required this.coreTunable,
    this.alignment = 1,
    this.handshakeFloor = 0,
  });

  final String label;
  final MtuCarrier carrier;
  final int overheadV4;
  final int overheadV6;
  final int ceiling;
  final bool coreTunable;
  final int alignment;
  final int handshakeFloor;

  static const MtuProfile masqueH3 = MtuProfile(
    label: 'MASQUE · HTTP/3',
    carrier: MtuCarrier.datagram,
    overheadV4: 72,
    overheadV6: 92,
    ceiling: 1280,
    coreTunable: true,
    handshakeFloor: 1228,
  );

  static const MtuProfile masqueH2 = MtuProfile(
    label: 'MASQUE · HTTP/2',
    carrier: MtuCarrier.stream,
    overheadV4: 72,
    overheadV6: 92,
    ceiling: 1500,
    coreTunable: true,
  );

  static const MtuProfile wireguard = MtuProfile(
    label: 'WireGuard',
    carrier: MtuCarrier.datagram,
    overheadV4: 60,
    overheadV6: 80,
    ceiling: 1280,
    coreTunable: false,
    alignment: 16,
  );

  static const MtuProfile goolH3 = MtuProfile(
    label: 'WireGuard in MASQUE · HTTP/3',
    carrier: MtuCarrier.datagram,
    overheadV4: 132,
    overheadV6: 152,
    ceiling: 1200,
    coreTunable: false,
    alignment: 16,
    handshakeFloor: 1228,
  );

  static const MtuProfile goolH2 = MtuProfile(
    label: 'WireGuard in MASQUE · HTTP/2',
    carrier: MtuCarrier.stream,
    overheadV4: 132,
    overheadV6: 152,
    ceiling: 1200,
    coreTunable: false,
    alignment: 16,
  );

  static const MtuProfile goolClassic = MtuProfile(
    label: 'WireGuard in WireGuard',
    carrier: MtuCarrier.datagram,
    overheadV4: 120,
    overheadV6: 160,
    ceiling: 1200,
    coreTunable: false,
    alignment: 16,
  );

  static MtuProfile of(TunnelSettings settings) {
    if (settings.usesGoolClassic) return goolClassic;
    if (settings.usesGool) return settings.usesHttp2 ? goolH2 : goolH3;
    if (settings.usesWireGuard) return wireguard;
    if (settings.usesHttp2) return masqueH2;
    return masqueH3;
  }

  int overheadFor(IpVersion version) =>
      version == IpVersion.v4 ? overheadV4 : overheadV6;
}

class MtuPlan {
  const MtuPlan({
    required this.profile,
    required this.pathMtu,
    required this.overhead,
    required this.innerMtu,
    required this.tunnelMtu,
    required this.coreMtu,
  });

  final MtuProfile profile;
  final int pathMtu;
  final int overhead;
  final int innerMtu;
  final int tunnelMtu;
  final int coreMtu;

  bool get measured => pathMtu > 0;

  bool get pathLimited =>
      measured &&
      profile.carrier == MtuCarrier.datagram &&
      pathMtu - overhead < profile.ceiling;

  bool get belowFloor => innerMtu < kTunnelMtuMin;

  bool get handshakeAtRisk =>
      measured && profile.handshakeFloor > 0 && pathMtu < profile.handshakeFloor;

  int get outerPacket => innerMtu + overhead;

  static MtuPlan resolve({
    required TunnelSettings settings,
    required int pathMtu,
  }) {
    final profile = MtuProfile.of(settings);
    final overhead = profile.overheadFor(settings.ipVersion);

    var inner = profile.ceiling;
    if (pathMtu > 0 && profile.carrier == MtuCarrier.datagram) {
      final fits = _alignDown(pathMtu - overhead, profile.alignment);
      if (fits < inner) inner = fits;
    }
    if (inner < kCoreMtuMin) inner = kCoreMtuMin;

    return MtuPlan(
      profile: profile,
      pathMtu: pathMtu,
      overhead: overhead,
      innerMtu: inner,
      tunnelMtu: inner.clamp(kTunnelMtuMin, kTunnelMtuMax),
      coreMtu: profile.coreTunable ? inner.clamp(kCoreMtuMin, kCoreMtuMax) : 0,
    );
  }
}

int _alignDown(int value, int alignment) {
  if (alignment <= 1) return value;
  return value - (value % alignment);
}
