import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/widgets.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

import '../../data/models/tunnel_status.dart';

enum ShellIcon { idle, busy, active }

class DesktopShellLabels {
  const DesktopShellLabels({
    required this.show,
    required this.hide,
    required this.quit,
    required this.stageIdle,
    required this.stageBusy,
    required this.stageActive,
  });

  final String show;
  final String hide;
  final String quit;
  final String stageIdle;
  final String stageBusy;
  final String stageActive;
}

class DesktopShell with TrayListener, WindowListener {
  DesktopShell._();

  static final DesktopShell instance = DesktopShell._();

  static const Size windowSize = Size(440, 700);
  static const Size minimumSize = Size(380, 520);
  static const double minimumHeight = 520;

  static bool get isSupported =>
      !kIsWeb && (Platform.isLinux || Platform.isWindows || Platform.isMacOS);

  bool _windowReady = false;
  bool _trayReady = false;
  ShellIcon _icon = ShellIcon.idle;
  DesktopShellLabels? _labels;
  Future<void> Function()? _onQuit;

  Future<void> prepareWindow() async {
    if (!isSupported || _windowReady) return;

    await windowManager.ensureInitialized();

    var height = windowSize.height;
    try {
      final display = await screenRetriever.getPrimaryDisplay();
      final available = display.visibleSize ?? display.size;
      if (available.height > minimumHeight) {
        height = height.clamp(minimumHeight, available.height - 40);
      }
    } catch (_) {
      height = windowSize.height;
    }

    final initial = Size(windowSize.width, height);

    final options = WindowOptions(
      size: initial,
      minimumSize: minimumSize,
      center: true,
      title: 'Oblivion',
      titleBarStyle: TitleBarStyle.normal,
    );

    await windowManager.waitUntilReadyToShow(options, () async {
      await windowManager.setMinimumSize(minimumSize);
      await windowManager.setSize(initial);
      await windowManager.center();
      await windowManager.setPreventClose(true);
      await windowManager.show();
      await windowManager.focus();
    });

    windowManager.addListener(this);
    _windowReady = true;
  }

  Future<void> attachTray({
    required DesktopShellLabels labels,
    required Future<void> Function() onQuit,
  }) async {
    if (!isSupported) return;

    _labels = labels;
    _onQuit = onQuit;

    if (!_trayReady) {
      trayManager.addListener(this);
      _trayReady = true;
    }

    await _applyIcon(_icon, force: true);
    await _rebuildMenu();
  }

  Future<void> syncStage(TunnelStage stage) async {
    if (!isSupported || !_trayReady) return;

    final next = switch (stage) {
      TunnelStage.connected => ShellIcon.active,
      TunnelStage.connecting ||
      TunnelStage.validating ||
      TunnelStage.disconnecting =>
        ShellIcon.busy,
      TunnelStage.disconnected || TunnelStage.failed => ShellIcon.idle,
    };

    if (next == _icon) return;
    _icon = next;
    await _applyIcon(next);
    await _rebuildMenu();
  }

  Future<void> _applyIcon(ShellIcon icon, {bool force = false}) async {
    final name = icon.name;
    final path = Platform.isWindows
        ? 'assets/tray/$name.ico'
        : 'assets/tray/$name.png';

    try {
      await trayManager.setIcon(path);
      final labels = _labels;
      if (labels != null) {
        await trayManager.setToolTip('Oblivion · ${_stageLabel(labels, icon)}');
      }
    } catch (_) {
      if (force) _trayReady = false;
    }
  }

  String _stageLabel(DesktopShellLabels labels, ShellIcon icon) =>
      switch (icon) {
        ShellIcon.idle => labels.stageIdle,
        ShellIcon.busy => labels.stageBusy,
        ShellIcon.active => labels.stageActive,
      };

  Future<void> _rebuildMenu() async {
    final labels = _labels;
    if (labels == null) return;

    final menu = Menu(
      items: <MenuItem>[
        MenuItem(
          key: 'state',
          label: _stageLabel(labels, _icon),
          disabled: true,
        ),
        MenuItem.separator(),
        MenuItem(key: 'show', label: labels.show),
        MenuItem(key: 'hide', label: labels.hide),
        MenuItem.separator(),
        MenuItem(key: 'quit', label: labels.quit),
      ],
    );

    try {
      await trayManager.setContextMenu(menu);
    } catch (_) {
      return;
    }
  }

  Future<void> revealWindow() async {
    if (!isSupported) return;
    await windowManager.show();
    await windowManager.focus();
  }

  Future<void> hideWindow() async {
    if (!isSupported) return;
    await windowManager.hide();
  }

  Future<void> quit() async {
    final handler = _onQuit;
    if (handler != null) await handler();

    if (_trayReady) {
      trayManager.removeListener(this);
      await trayManager.destroy();
      _trayReady = false;
    }

    if (_windowReady) {
      windowManager.removeListener(this);
      await windowManager.setPreventClose(false);
      await windowManager.destroy();
    }
  }

  @override
  void onTrayIconMouseDown() {
    revealWindow();
  }

  @override
  void onTrayIconRightMouseDown() {
    trayManager.popUpContextMenu();
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    switch (menuItem.key) {
      case 'show':
        revealWindow();
      case 'hide':
        hideWindow();
      case 'quit':
        quit();
    }
  }

  @override
  void onWindowClose() {
    hideWindow();
  }
}
