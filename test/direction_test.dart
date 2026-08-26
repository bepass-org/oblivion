import 'package:flutter/cupertino.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oblivion/l10n/generated/app_localizations.dart';

Widget _app({required Locale locale, required Widget child}) {
  return CupertinoApp(
    locale: locale,
    supportedLocales: L10n.supportedLocales,
    localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
      L10n.delegate,
      GlobalCupertinoLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
    ],
    home: child,
  );
}

void main() {
  testWidgets('persian resolves to a right to left layout', (tester) async {
    late TextDirection direction;
    late Locale resolved;

    await tester.pumpWidget(
      _app(
        locale: const Locale('fa'),
        child: Builder(
          builder: (context) {
            direction = Directionality.of(context);
            resolved = Localizations.localeOf(context);
            return const SizedBox();
          },
        ),
      ),
    );

    expect(resolved.languageCode, 'fa');
    expect(direction, TextDirection.rtl);
  });

  testWidgets('english resolves to a left to right layout', (tester) async {
    late TextDirection direction;

    await tester.pumpWidget(
      _app(
        locale: const Locale('en'),
        child: Builder(
          builder: (context) {
            direction = Directionality.of(context);
            return const SizedBox();
          },
        ),
      ),
    );

    expect(direction, TextDirection.ltr);
  });

  testWidgets('a row of icons mirrors when the locale is persian',
      (tester) async {
    Future<List<double>> centres(Locale locale) async {
      await tester.pumpWidget(
        _app(
          locale: locale,
          child: Row(
            children: const <Widget>[
              Icon(CupertinoIcons.info_circle, key: Key('info')),
              Spacer(),
              Icon(CupertinoIcons.doc_text, key: Key('logs')),
              Icon(CupertinoIcons.settings, key: Key('settings')),
            ],
          ),
        ),
      );
      return <double>[
        tester.getCenter(find.byKey(const Key('info'))).dx,
        tester.getCenter(find.byKey(const Key('logs'))).dx,
        tester.getCenter(find.byKey(const Key('settings'))).dx,
      ];
    }

    final ltr = await centres(const Locale('en'));
    expect(ltr[0], lessThan(ltr[1]), reason: 'info sits before logs in english');
    expect(ltr[1], lessThan(ltr[2]));

    final rtl = await centres(const Locale('fa'));
    expect(rtl[0], greaterThan(rtl[1]),
        reason: 'info should sit on the right in persian');
    expect(rtl[1], greaterThan(rtl[2]),
        reason: 'logs and settings should move to the left in persian');
  });

  testWidgets('persian text in the l10n bundle is actually persian',
      (tester) async {
    late L10n l10n;

    await tester.pumpWidget(
      _app(
        locale: const Locale('fa'),
        child: Builder(
          builder: (context) {
            l10n = L10n.of(context);
            return const SizedBox();
          },
        ),
      ),
    );

    expect(l10n.settings, isNot('Settings'));
    expect(
      l10n.settings.codeUnits.any((unit) => unit >= 0x0600 && unit <= 0x06FF),
      isTrue,
      reason: 'the persian bundle should be loaded, not the english fallback',
    );
  });
}
