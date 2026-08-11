import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/tunnel_settings.dart';
import '../models/tunnel_status.dart';
import 'desktop_core_bindings.dart';

class DesktopTunnelBackend {
  DesktopTunnelBackend._(this._bindings);

  final DesktopCoreBindings _bindings;

  final StreamController<TunnelStatus> _statusController =
      StreamController<TunnelStatus>.broadcast();
  final StreamController<String> _logController =
      StreamController<String>.broadcast();

  Timer? _poller;
  String _lastStatusJson = '';
  String? _dataDir;

  static DesktopTunnelBackend? _instance;
  static Future<DesktopTunnelBackend?>? _opening;

  static DesktopTunnelBackend? get current => _instance;

  static Future<DesktopTunnelBackend?> open() {
    final existing = _instance;
    if (existing != null) {
      return Future<DesktopTunnelBackend?>.value(existing);
    }
    return _opening ??= _openOnce();
  }

  static Future<DesktopTunnelBackend?> _openOnce() async {
    final bindings = DesktopCoreBindings.open();
    if (bindings == null) {
      _opening = null;
      return null;
    }

    final backend = DesktopTunnelBackend._(bindings);
    await backend._registerCoreBinary();
    backend._startPolling();
    return _instance = backend;
  }

  void shutdown() {
    _poller?.cancel();
    _poller = null;
  }

  Future<void> _registerCoreBinary() async {
    final executableDir = File(Platform.resolvedExecutable).parent;
    final binaryName = Platform.isWindows ? 'aether.exe' : 'aether';

    final candidates = <String>[
      '${executableDir.path}${Platform.pathSeparator}$binaryName',
      '${executableDir.path}${Platform.pathSeparator}lib'
          '${Platform.pathSeparator}$binaryName',
    ];

    try {
      final support = await getApplicationSupportDirectory();
      candidates.add(
        '${support.path}${Platform.pathSeparator}$binaryName',
      );
    } catch (_) {
      candidates.add(binaryName);
    }

    for (final candidate in candidates) {
      if (File(candidate).existsSync()) {
        _bindings.setCorePath(candidate);
        return;
      }
    }

    _bindings.setCorePath(candidates.first);
  }

  void _startPolling() {
    _poller?.cancel();
    _poller = Timer.periodic(const Duration(milliseconds: 700), (_) {
      final statusJson = _bindings.statusJson();
      if (statusJson.isNotEmpty && statusJson != _lastStatusJson) {
        _lastStatusJson = statusJson;
        final decoded = jsonDecode(statusJson);
        if (decoded is Map) _statusController.add(TunnelStatus.fromMap(decoded));
      }

      final logs = _bindings.drainLogs();
      if (logs.isNotEmpty) _logController.add(logs);
    });
  }

  Stream<TunnelStatus> get statusStream => _statusController.stream;

  Stream<String> get logStream => _logController.stream;

  Future<bool> prepare() async => true;

  Future<String> _dataDirectory() async {
    final cached = _dataDir;
    if (cached != null) return cached;

    try {
      final support = await getApplicationSupportDirectory();
      final directory = Directory(
        '${support.path}${Platform.pathSeparator}core',
      );
      if (!directory.existsSync()) directory.createSync(recursive: true);
      return _dataDir = directory.path;
    } catch (_) {
      return _dataDir = Directory.systemTemp.path;
    }
  }

  Future<void> connect(TunnelSettings settings) async {
    final payload = jsonEncode(<String, dynamic>{
      'settings': <String, dynamic>{
        ...settings.toPlatformPayload(),
        'dataDir': await _dataDirectory(),
      },
      'arguments': settings.toCoreArguments(),
    });
    _bindings.connect(payload);
  }

  Future<void> disconnect() async => _bindings.disconnect();

  Future<bool> submitLoginCode(String code) async =>
      _bindings.submitLine(code);

  Future<TunnelStatus> currentStatus() async {
    final statusJson = _bindings.statusJson();
    if (statusJson.isEmpty) return TunnelStatus.initial;
    final decoded = jsonDecode(statusJson);
    if (decoded is! Map) return TunnelStatus.initial;
    return TunnelStatus.fromMap(decoded);
  }

  Future<String> readLogs() async => _bindings.readLogs();

  Future<void> clearLogs() async => _bindings.clearLogs();

  Future<String> coreVersion() async => _bindings.coreVersion();

  bool get tunnelDeviceAvailable => _bindings.tunnelDeviceAvailable;

  bool get isPrivileged => _bindings.isPrivileged;

  void dispose() {
    _poller?.cancel();
    _poller = null;
    _statusController.close();
    _logController.close();
  }
}
