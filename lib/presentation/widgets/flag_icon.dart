import 'package:flutter/cupertino.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/theme/app_theme.dart';

class FlagIcon extends StatelessWidget {
  const FlagIcon({super.key, required this.countryCode, this.size = 26});

  final String countryCode;
  final double size;

  static const Set<String> _available = <String>{
    'at', 'au', 'az', 'be', 'ca', 'ch', 'cz', 'de', 'dk', 'ee',
    'es', 'fi', 'fr', 'gb', 'hr', 'hu', 'in', 'ir', 'it', 'jp',
    'lv', 'nl', 'no', 'pl', 'pt', 'ro', 'rs', 'se', 'sg', 'sk',
    'tr', 'us',
  };

  static String assetFor(String countryCode) {
    final code = countryCode.trim().toLowerCase();
    return _available.contains(code)
        ? 'assets/flags/$code.svg'
        : 'assets/flags/xx.svg';
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return SizedBox(
      width: size,
      height: size * 0.72,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: SvgPicture.asset(
          assetFor(countryCode),
          fit: BoxFit.cover,
          placeholderBuilder: (_) => ColoredBox(color: palette.cardPressed),
        ),
      ),
    );
  }
}
