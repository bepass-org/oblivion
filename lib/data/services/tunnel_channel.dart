import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/tunnel_settings.dart';
import '../models/tunnel_status.dart';
import 'desktop_tunnel_backend.dart';

class InstalledApp {
  const InstalledApp({
    required this.packageName,
    required this.label,
    required this.isSystem,
    this.icon,
  });

  final String packageName;
  final String label;
  final bool isSystem;
  final Uint8List? icon;

  factory InstalledApp.fromMap(Map<dynamic, dynamic> map) => InstalledApp(
        packageName: map['packageName'] as String,
        label: (map['label'] as String?) ?? map['packageName'] as String,
        isSystem: (map['isSystem'] as bool?) ?? false,
        icon: map['icon'] as Uint8List?,
      );
}

class TunnelChannel {
  TunnelChannel._();

  static final TunnelChannel instance = TunnelChannel._();

  static const MethodChannel _methods =
      MethodChannel('org.bepass.oblivion/tunnel');
  static const EventChannel _statusEvents =
      EventChannel('org.bepass.oblivion/tunnel_status');
  static const EventChannel _logEvents =
      EventChannel('org.bepass.oblivion/tunnel_logs');

  Stream<TunnelStatus>? _statusStream;
  Stream<String>? _logStream;
  Future<DesktopTunnelBackend?>? _desktop;

  static bool get _usesNativeChannels {
    if (kIsWeb) return false;
    return Platform.isAndroid || Platform.isIOS;
  }

  Future<DesktopTunnelBackend?> _desktopBackend() {
    if (_usesNativeChannels) return Future<DesktopTunnelBackend?>.value();
    return _desktop ??= DesktopTunnelBackend.open();
  }

  Stream<TunnelStatus> get statusStream {
    return _statusStream ??= _buildStatusStream().asBroadcastStream();
  }

  Stream<TunnelStatus> _buildStatusStream() {
    if (_usesNativeChannels) {
      return _statusEvents
          .receiveBroadcastStream()
          .where((event) => event is Map)
          .map((event) => TunnelStatus.fromMap(event as Map));
    }

    return Stream<TunnelStatus>.multi((controller) async {
      final backend = await _desktopBackend();
      if (backend == null) {
        await controller.close();
        return;
      }
      final subscription = backend.statusStream.listen(
        controller.add,
        onError: controller.addError,
      );
      controller.onCancel = subscription.cancel;
    });
  }

  Stream<String> get logStream {
    return _logStream ??= _buildLogStream().asBroadcastStream();
  }

  Stream<String> _buildLogStream() {
    if (_usesNativeChannels) {
      return _logEvents
          .receiveBroadcastStream()
          .where((event) => event is String)
          .cast<String>();
    }

    return Stream<String>.multi((controller) async {
      final backend = await _desktopBackend();
      if (backend == null) {
        await controller.close();
        return;
      }
      final subscription = backend.logStream.listen(
        controller.add,
        onError: controller.addError,
      );
      controller.onCancel = subscription.cancel;
    });
  }

  Future<bool> prepare() async {
    if (!_usesNativeChannels) {
      final backend = await _desktopBackend();
      return backend?.prepare() ?? false;
    }
    final granted = await _methods.invokeMethod<bool>('prepare');
    return granted ?? false;
  }

  Future<void> connect(TunnelSettings settings) async {
    if (!_usesNativeChannels) {
      final backend = await _desktopBackend();
      return backend?.connect(settings);
    }
    return _methods.invokeMethod<void>('connect', <String, dynamic>{
      'settings': settings.toPlatformPayload(),
      'arguments': settings.toCoreArguments(),
    });
  }

  Future<void> disconnect() async {
    if (!_usesNativeChannels) {
      final backend = await _desktopBackend();
      return backend?.disconnect();
    }
    return _methods.invokeMethod<void>('disconnect');
  }

  Future<TunnelStatus> currentStatus() async {
    if (!_usesNativeChannels) {
      final backend = await _desktopBackend();
      return backend?.currentStatus() ?? TunnelStatus.initial;
    }
    final raw = await _methods.invokeMethod<Map<dynamic, dynamic>>('status');
    if (raw == null) return TunnelStatus.initial;
    return TunnelStatus.fromMap(raw);
  }

  Future<String> readLogs() async {
    if (!_usesNativeChannels) {
      final backend = await _desktopBackend();
      return backend?.readLogs() ?? '';
    }
    final logs = await _methods.invokeMethod<String>('readLogs');
    return logs ?? '';
  }

  Future<void> clearLogs() async {
    if (!_usesNativeChannels) {
      final backend = await _desktopBackend();
      return backend?.clearLogs();
    }
    return _methods.invokeMethod<void>('clearLogs');
  }

  Future<String> coreVersion() async {
    if (!_usesNativeChannels) {
      final backend = await _desktopBackend();
      return backend?.coreVersion() ?? 'unavailable';
    }
    final version = await _methods.invokeMethod<String>('coreVersion');
    return version ?? 'unknown';
  }

  Future<TunnelCapability> capability() async {
    if (!_usesNativeChannels) {
      final backend = await _desktopBackend();
      if (backend == null) {
        return const TunnelCapability(embedded: false, privileged: false);
      }
      return TunnelCapability(
        embedded: backend.tunnelDeviceAvailable,
        privileged: backend.isPrivileged,
      );
    }
    return const TunnelCapability(embedded: true, privileged: true);
  }

  Future<bool> submitLoginCode(String code) async {
    final trimmed = code.trim();
    if (trimmed.isEmpty) return false;

    if (!_usesNativeChannels) {
      final backend = await _desktopBackend();
      return backend?.submitLoginCode(trimmed) ?? false;
    }

    final accepted = await _methods.invokeMethod<bool>(
      'submitLoginCode',
      <String, dynamic>{'code': trimmed},
    );
    return accepted ?? false;
  }

  Future<bool> requestNotifications() async {
    if (!_usesNativeChannels) return true;
    final granted =
        await _methods.invokeMethod<bool>('requestNotifications');
    return granted ?? false;
  }

  Future<List<InstalledApp>> installedApps({bool includeSystem = false}) async {
    if (!_usesNativeChannels) return const <InstalledApp>[];

    final raw = await _methods.invokeListMethod<Map<dynamic, dynamic>>(
      'installedApps',
      <String, dynamic>{'includeSystem': includeSystem},
    );
    if (raw == null) return const <InstalledApp>[];
    return raw.map(InstalledApp.fromMap).toList();
  }
}
