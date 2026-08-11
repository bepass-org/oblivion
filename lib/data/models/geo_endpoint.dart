enum WarpStatus {
  unknown('unknown'),
  off('off'),
  on('on'),
  plus('plus');

  const WarpStatus(this.wire);

  final String wire;

  static WarpStatus fromWire(String? value) => values.firstWhere(
        (entry) => entry.wire == value?.trim().toLowerCase(),
        orElse: () => WarpStatus.unknown,
      );

  bool get isProtected => this == WarpStatus.on || this == WarpStatus.plus;
}

class GeoEndpoint {
  const GeoEndpoint({
    required this.ip,
    required this.countryCode,
    this.country,
    this.city,
    this.isp,
    this.colo,
    this.warp = WarpStatus.unknown,
  });

  final String ip;
  final String countryCode;
  final String? country;
  final String? city;
  final String? isp;
  final String? colo;
  final WarpStatus warp;

  GeoEndpoint mergeIsp(GeoEndpoint? other) {
    if (other == null) return this;
    return GeoEndpoint(
      ip: ip,
      countryCode: countryCode.isEmpty ? other.countryCode : countryCode,
      country: country ?? other.country,
      city: city ?? other.city,
      isp: isp ?? other.isp,
      colo: colo,
      warp: warp,
    );
  }

  String get flagEmoji {
    if (countryCode.length != 2) return '';
    final upper = countryCode.toUpperCase();
    const base = 0x1F1E6;
    final first = base + (upper.codeUnitAt(0) - 0x41);
    final second = base + (upper.codeUnitAt(1) - 0x41);
    return String.fromCharCodes([first, second]);
  }

  static GeoEndpoint? fromLookup(Map<String, dynamic> json) {
    final ip = _text(json['query']) ?? _text(json['ip']);
    if (ip == null || ip.isEmpty) return null;

    final rawCountry = _text(json['country']);
    final code = _text(json['countryCode']) ??
        _text(json['country_code']) ??
        (rawCountry != null && rawCountry.length == 2 ? rawCountry : null);

    final name = _text(json['country_name']) ??
        (rawCountry != null && rawCountry.length > 2 ? rawCountry : null);

    final connection = json['connection'];
    final asn = json['asn'];

    final isp = _text(json['isp']) ??
        _text(json['org']) ??
        (connection is Map
            ? _text(connection['isp']) ?? _text(connection['org'])
            : null) ??
        (asn is Map ? _text(asn['name']) ?? _text(asn['org']) : null);

    return GeoEndpoint(
      ip: ip,
      countryCode: (code ?? '').toUpperCase(),
      country: name,
      city: _text(json['city']),
      isp: _cleanIsp(isp),
    );
  }

  static String? _text(Object? value) {
    if (value is String) {
      final trimmed = value.trim();
      return trimmed.isEmpty ? null : trimmed;
    }
    return null;
  }

  static String? _cleanIsp(String? value) {
    if (value == null) return null;
    final match = RegExp(r'^AS\d+\s+(.*)$').firstMatch(value);
    return match == null ? value : match.group(1);
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'ip': ip,
        'countryCode': countryCode,
        'country': country,
        'city': city,
        'isp': isp,
        'colo': colo,
        'warp': warp.wire,
      };

  factory GeoEndpoint.fromJson(Map<String, dynamic> json) => GeoEndpoint(
        ip: json['ip'] as String,
        countryCode: json['countryCode'] as String,
        country: json['country'] as String?,
        city: json['city'] as String?,
        isp: json['isp'] as String?,
        colo: json['colo'] as String?,
        warp: WarpStatus.fromWire(json['warp'] as String?),
      );
}
