enum TunnelStage {
  disconnected,
  connecting,
  validating,
  connected,
  disconnecting,
  failed;

  bool get isBusy => this == connecting || this == validating || this == disconnecting;

  bool get isActive => this == connected;

  bool get isIdle => this == disconnected || this == failed;

  static TunnelStage fromName(String? value) => values.firstWhere(
        (e) => e.name == value,
        orElse: () => TunnelStage.disconnected,
      );
}

class TunnelStats {
  const TunnelStats({
    this.txPackets = 0,
    this.txBytes = 0,
    this.rxPackets = 0,
    this.rxBytes = 0,
  });

  final int txPackets;
  final int txBytes;
  final int rxPackets;
  final int rxBytes;

  static const TunnelStats empty = TunnelStats();

  factory TunnelStats.fromMap(Map<dynamic, dynamic> map) {
    int read(String key) => (map[key] as num?)?.toInt() ?? 0;
    return TunnelStats(
      txPackets: read('txPackets'),
      txBytes: read('txBytes'),
      rxPackets: read('rxPackets'),
      rxBytes: read('rxBytes'),
    );
  }
}

class TunnelStatus {
  const TunnelStatus({
    this.stage = TunnelStage.disconnected,
    this.stats = TunnelStats.empty,
    this.gateway,
    this.connectedAt,
    this.message,
    this.tunnelMode = false,
    this.tunnelDeviceUp = false,
  });

  final TunnelStage stage;
  final TunnelStats stats;
  final String? gateway;
  final DateTime? connectedAt;
  final String? message;
  final bool tunnelMode;
  final bool tunnelDeviceUp;

  static const TunnelStatus initial = TunnelStatus();

  Duration get uptime {
    final start = connectedAt;
    if (start == null || stage != TunnelStage.connected) return Duration.zero;
    return DateTime.now().difference(start);
  }

  factory TunnelStatus.fromMap(Map<dynamic, dynamic> map) {
    final startedMs = (map['connectedAt'] as num?)?.toInt();
    return TunnelStatus(
      stage: TunnelStage.fromName(map['stage'] as String?),
      stats: map['stats'] is Map
          ? TunnelStats.fromMap(map['stats'] as Map)
          : TunnelStats.empty,
      gateway: map['gateway'] as String?,
      connectedAt: startedMs == null || startedMs == 0
          ? null
          : DateTime.fromMillisecondsSinceEpoch(startedMs),
      message: map['message'] as String?,
      tunnelMode: map['tunnelMode'] as bool? ?? false,
      tunnelDeviceUp: map['tunnelDeviceUp'] as bool? ?? false,
    );
  }

  TunnelStatus copyWith({
    TunnelStage? stage,
    TunnelStats? stats,
    String? gateway,
    DateTime? connectedAt,
    String? message,
    bool? tunnelMode,
    bool? tunnelDeviceUp,
  }) {
    return TunnelStatus(
      stage: stage ?? this.stage,
      stats: stats ?? this.stats,
      gateway: gateway ?? this.gateway,
      connectedAt: connectedAt ?? this.connectedAt,
      message: message ?? this.message,
      tunnelMode: tunnelMode ?? this.tunnelMode,
      tunnelDeviceUp: tunnelDeviceUp ?? this.tunnelDeviceUp,
    );
  }
}

class TunnelCapability {
  const TunnelCapability({
    required this.embedded,
    required this.privileged,
  });

  final bool embedded;
  final bool privileged;

  bool get ready => embedded && privileged;

  static const TunnelCapability unknown =
      TunnelCapability(embedded: false, privileged: false);
}
