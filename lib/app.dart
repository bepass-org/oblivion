import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/platform/desktop_shell.dart';
import 'core/theme/app_theme.dart';
import 'data/services/desktop_tunnel_backend.dart';
import 'l10n/generated/app_localizations.dart';
import 'presentation/providers/app_providers.dart';
import 'presentation/providers/tunnel_providers.dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/screens/splash_screen.dart';

class OblivionApp extends ConsumerWidget {
  const OblivionApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(appPreferencesProvider);
    final locale = prefs.locale;

    final platformBrightness = MediaQuery.platformBrightnessOf(context);
    final brightness = switch (prefs.themeMode) {
      ThemeMode.dark => Brightness.dark,
      ThemeMode.light => Brightness.light,
      ThemeMode.system => platformBrightness,
    };

    return CupertinoApp(
      title: 'Oblivion',
      debugShowCheckedModeBanner: false,
      locale: locale,
      supportedLocales: L10n.supportedLocales,
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        L10n.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      theme: AppTheme.build(brightness),
      home: const _Entry(),
    );
  }
}

class _Entry extends ConsumerStatefulWidget {
  const _Entry();

  @override
  ConsumerState<_Entry> createState() => _EntryState();
}

class _EntryState extends ConsumerState<_Entry> {
  bool _splashDone = false;
  String? _trayLocale;

  void _syncTray(L10n l10n, Locale locale) {
    if (!DesktopShell.isSupported) return;
    final tag = locale.toLanguageTag();
    if (_trayLocale == tag) return;
    _trayLocale = tag;

    DesktopShell.instance.attachTray(
      labels: DesktopShellLabels(
        show: l10n.trayShow,
        hide: l10n.trayHide,
        quit: l10n.trayQuit,
        stageIdle: l10n.trayStageIdle,
        stageBusy: l10n.trayStageBusy,
        stageActive: l10n.trayStageActive,
      ),
      onQuit: () async {
        await ref.read(tunnelProvider.notifier).disconnect();
        DesktopTunnelBackend.current?.shutdown();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (DesktopShell.isSupported) {
      _syncTray(L10n.of(context), Localizations.localeOf(context));
      ref.listen(tunnelProvider, (previous, next) {
        if (previous?.stage != next.stage) {
          DesktopShell.instance.syncStage(next.stage);
        }
      });
    }

    if (_splashDone) return const HomeScreen();

    return SplashScreen(onDone: () => setState(() => _splashDone = true));
  }
}
