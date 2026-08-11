import 'package:flutter/cupertino.dart';

const String kFontFamily = 'Vazirmatn';

class AppColors {
  const AppColors._();

  static const Color primary = Color(0xFFFFA200);
  static const Color danger = Color(0xFFE23B3D);
  static const Color subtitle = Color(0xFF7B8D9D);
}

@immutable
class AppPalette {
  const AppPalette({
    required this.canvas,
    required this.card,
    required this.cardPressed,
    required this.separator,
    required this.label,
    required this.labelSecondary,
    required this.track,
    required this.isDark,
  });

  final Color canvas;
  final Color card;
  final Color cardPressed;
  final Color separator;
  final Color label;
  final Color labelSecondary;
  final Color track;
  final bool isDark;

  Color get primary => AppColors.primary;

  Color get danger => AppColors.danger;

  static const AppPalette light = AppPalette(
    canvas: Color(0xFFFFFFFF),
    card: Color(0xFFFFFFFF),
    cardPressed: Color(0xFFF1F3F5),
    separator: Color(0xFFE2E5E9),
    label: Color(0xFF1C202C),
    labelSecondary: AppColors.subtitle,
    track: Color(0xFFD7D7D7),
    isDark: false,
  );

  static const AppPalette dark = AppPalette(
    canvas: Color(0xFF1C202C),
    card: Color(0xFF232834),
    cardPressed: Color(0xFF2C323F),
    separator: Color(0xFF383A45),
    label: Color(0xFFFFFFFF),
    labelSecondary: AppColors.subtitle,
    track: Color(0xFF383A45),
    isDark: true,
  );

  static AppPalette of(BuildContext context) {
    final brightness = CupertinoTheme.of(context).brightness ??
        MediaQuery.platformBrightnessOf(context);
    return brightness == Brightness.dark ? dark : light;
  }
}

extension PaletteContext on BuildContext {
  AppPalette get palette => AppPalette.of(this);
}

class AppText {
  const AppText._();

  static TextStyle wordmark(Color color) => TextStyle(
        fontFamily: kFontFamily,
        fontSize: 42,
        height: 1.1,
        fontWeight: FontWeight.w800,
        letterSpacing: 2,
        color: color,
      );

  static TextStyle brand(Color color) => TextStyle(
        fontFamily: kFontFamily,
        fontSize: 32,
        height: 1.2,
        fontWeight: FontWeight.w700,
        color: color,
      );

  static TextStyle title(Color color) => TextStyle(
        fontFamily: kFontFamily,
        fontSize: 26,
        height: 1.2,
        fontWeight: FontWeight.w700,
        color: color,
      );

  static TextStyle state(Color color) => TextStyle(
        fontFamily: kFontFamily,
        fontSize: 21,
        height: 1.3,
        fontWeight: FontWeight.w500,
        color: color,
      );

  static TextStyle rowTitle(Color color) => TextStyle(
        fontFamily: kFontFamily,
        fontSize: 16,
        height: 1.3,
        fontWeight: FontWeight.w500,
        color: color,
      );

  static TextStyle rowValue(Color color) => TextStyle(
        fontFamily: kFontFamily,
        fontSize: 15,
        height: 1.3,
        fontWeight: FontWeight.w400,
        color: color,
      );

  static TextStyle caption(Color color) => TextStyle(
        fontFamily: kFontFamily,
        fontSize: 13,
        height: 1.4,
        fontWeight: FontWeight.w400,
        color: color,
      );

  static TextStyle mono(Color color) => TextStyle(
        fontFamily: 'monospace',
        fontSize: 12,
        height: 1.5,
        color: color,
      );
}

class AppTheme {
  const AppTheme._();

  static CupertinoThemeData build(Brightness brightness) {
    final palette =
        brightness == Brightness.dark ? AppPalette.dark : AppPalette.light;

    return CupertinoThemeData(
      brightness: brightness,
      primaryColor: AppColors.primary,
      primaryContrastingColor: palette.canvas,
      scaffoldBackgroundColor: palette.canvas,
      barBackgroundColor: palette.canvas,
      applyThemeToAll: true,
      textTheme: CupertinoTextThemeData(
        primaryColor: AppColors.primary,
        textStyle: AppText.rowTitle(palette.label),
        actionTextStyle: AppText.rowTitle(AppColors.primary),
        tabLabelTextStyle: AppText.caption(palette.labelSecondary),
        navTitleTextStyle: AppText.rowTitle(palette.label),
        navLargeTitleTextStyle: AppText.title(palette.label),
        navActionTextStyle: AppText.rowTitle(AppColors.primary),
        pickerTextStyle: AppText.rowTitle(palette.label),
        dateTimePickerTextStyle: AppText.rowTitle(palette.label),
      ),
    );
  }
}
