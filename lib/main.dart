import 'dart:ui' show AppExitResponse;

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/platform/desktop_shell.dart';
import 'data/services/desktop_tunnel_backend.dart';
import 'data/services/settings_store.dart';
import 'presentation/providers/app_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Color(0x00000000),
      systemNavigationBarColor: Color(0x00000000),
    ),
  );

  await DesktopShell.instance.prepareWindow();

  final store = await SettingsStore.open();

  _installShutdownGuard();

  runApp(
    ProviderScope(
      overrides: <Override>[settingsStoreProvider.overrideWithValue(store)],
      child: const OblivionApp(),
    ),
  );
}

void _installShutdownGuard() {
  AppLifecycleListener(
    onExitRequested: () async {
      DesktopTunnelBackend.current?.shutdown();
      return AppExitResponse.exit;
    },
    onDetach: () => DesktopTunnelBackend.current?.shutdown(),
  );
}
