import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/geo_endpoint.dart';
import '../../data/models/tunnel_settings.dart';
import '../../data/models/tunnel_status.dart';
import '../../data/services/geo_service.dart';
import '../../data/services/settings_store.dart';
import '../../data/services/tunnel_channel.dart';
import 'app_providers.dart';

class TunnelSettingsController extends StateNotifier<TunnelSettings> {
  TunnelSettingsController(this._store) : super(_store.readTunnelSettings());

  final SettingsStore _store;

  Future<void> update(TunnelSettings Function(TunnelSettings) transform) async {
    state = transform(state);
    await _store.writeTunnelSettings(state);
  }

  Future<void> reset() async {
    await _store.resetTunnelSettings();
    state = _store.readTunnelSettings();
  }

  Future<void> toggleBypassedApp(String packageName) async {
    final next = state.bypassedApps.toSet();
    if (!next.remove(packageName)) next.add(packageName);
    await update((s) => s.copyWith(bypassedApps: next));
  }
}

final tunnelSettingsProvider =
    StateNotifierProvider<TunnelSettingsController, TunnelSettings>((ref) {
  return TunnelSettingsController(ref.watch(settingsStoreProvider));
});

class GeoSnapshot {
  const GeoSnapshot({
    this.origin,
    this.exit,
    this.loadingExit = false,
    this.refreshing = false,
  });

  final GeoEndpoint? origin;
  final GeoEndpoint? exit;
  final bool loadingExit;
  final bool refreshing;

  GeoEndpoint? get active => exit ?? origin;

  GeoSnapshot copyWith({
    GeoEndpoint? origin,
    GeoEndpoint? exit,
    bool? loadingExit,
    bool? refreshing,
    bool clearExit = false,
  }) {
    return GeoSnapshot(
      origin: origin ?? this.origin,
      exit: clearExit ? null : (exit ?? this.exit),
      loadingExit: loadingExit ?? this.loadingExit,
      refreshing: refreshing ?? this.refreshing,
    );
  }
}

class GeoController extends StateNotifier<GeoSnapshot> {
  GeoController(this._geo) : super(const GeoSnapshot()) {
    refreshOrigin();
  }

  final GeoService _geo;
  int _generation = 0;

  static const int _exitAttempts = 3;
  static const Duration _exitRetryDelay = Duration(seconds: 5);

  Future<void> refreshOrigin() async {
    final endpoint = await _geo.lookupDirect();
    if (!mounted || endpoint == null) return;
    state = state.copyWith(origin: endpoint);
  }

  Future<void> resolveExit(int httpProxyPort) async {
    final generation = ++_generation;
    state = state.copyWith(loadingExit: true, clearExit: true);

    for (var attempt = 0; attempt < _exitAttempts; attempt++) {
      final endpoint = await _geo.lookupThroughProxy(httpProxyPort);
      if (!mounted || generation != _generation) return;

      if (endpoint != null) {
        state = GeoSnapshot(
          origin: state.origin,
          exit: endpoint,
          loadingExit: false,
        );
        return;
      }

      if (attempt == _exitAttempts - 1) break;
      await Future<void>.delayed(_exitRetryDelay);
      if (!mounted || generation != _generation) return;
    }

    state = GeoSnapshot(origin: state.origin, loadingExit: false);
  }

  Future<void> refreshAll({
    required int httpProxyPort,
    required bool tunnelActive,
  }) async {
    if (state.refreshing) return;
    state = state.copyWith(refreshing: true);

    await refreshOrigin();
    if (tunnelActive) {
      await resolveExit(httpProxyPort);
    }

    if (!mounted) return;
    state = state.copyWith(refreshing: false);
  }

  void clearExit() {
    _generation++;
    state = state.copyWith(loadingExit: false, clearExit: true);
  }
}

final geoProvider = StateNotifierProvider<GeoController, GeoSnapshot>((ref) {
  return GeoController(ref.watch(geoServiceProvider));
});

class TunnelController extends StateNotifier<TunnelStatus> {
  TunnelController(this._ref, this._channel) : super(TunnelStatus.initial) {
    _subscription = _channel.statusStream.listen(_onStatus);
    _syncInitialStatus();
  }

  final Ref _ref;
  final TunnelChannel _channel;
  StreamSubscription<TunnelStatus>? _subscription;
  Timer? _ticker;
  bool _connecting = false;

  Future<void> _syncInitialStatus() async {
    try {
      _onStatus(await _channel.currentStatus());
    } catch (_) {
    }
  }

  void _onStatus(TunnelStatus status) {
    final previous = state;
    state = status;

    if (status.stage == TunnelStage.connected &&
        previous.stage != TunnelStage.connected) {
      _startTicker();
      final port = _ref.read(tunnelSettingsProvider).httpProxyPort;
      _ref.read(geoProvider.notifier).resolveExit(port);
    }

    if (status.stage != TunnelStage.connected &&
        previous.stage == TunnelStage.connected) {
      _stopTicker();
      _ref.read(geoProvider.notifier).clearExit();
    }

    if (status.stage.isIdle) {
      _stopTicker();
      _ref.read(geoProvider.notifier).clearExit();
    }
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      state = state.copyWith();
    });
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
  }

  Future<bool> connect() async {
    if (_connecting) return false;
    _connecting = true;

    try {
      final settings = _ref.read(tunnelSettingsProvider);

      if (!settings.proxyOnly) {
        final granted = await _channel.prepare();
        if (!granted) return false;
      }

      state = state.copyWith(stage: TunnelStage.connecting);
      await _channel.connect(settings);

      unawaited(_channel.requestNotifications());
      return true;
    } finally {
      _connecting = false;
    }
  }

  Future<void> disconnect() async {
    state = state.copyWith(stage: TunnelStage.disconnecting);
    await _channel.disconnect();
  }

  Future<bool> toggle() async {
    if (state.stage.isActive || state.stage.isBusy) {
      await disconnect();
      return true;
    }
    return connect();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _stopTicker();
    super.dispose();
  }
}

final tunnelProvider =
    StateNotifierProvider<TunnelController, TunnelStatus>((ref) {
  return TunnelController(ref, ref.watch(tunnelChannelProvider));
});

final tunnelLogsProvider = StreamProvider<String>((ref) {
  return ref.watch(tunnelChannelProvider).logStream;
});

class LoginCodeRequest {
  const LoginCodeRequest({required this.email, required this.attempt});

  final String email;
  final int attempt;

  bool get isRetry => attempt > 1;
}

class LoginCodeController extends StateNotifier<LoginCodeRequest?> {
  LoginCodeController(this._channel) : super(null) {
    _subscription = _channel.logStream.listen(_onLine);
  }

  static final RegExp _marker =
      RegExp(r'login-code-needed\s+attempt=(\d+)\s+email=(\S+)');

  final TunnelChannel _channel;
  StreamSubscription<String>? _subscription;

  void _onLine(String line) {
    final match = _marker.firstMatch(line);
    if (match == null) return;

    state = LoginCodeRequest(
      email: match.group(2) ?? '',
      attempt: int.tryParse(match.group(1) ?? '') ?? 1,
    );
  }

  Future<bool> submit(String code) async {
    final accepted = await _channel.submitLoginCode(code);
    if (accepted && mounted) state = null;
    return accepted;
  }

  void dismiss() {
    if (mounted) state = null;
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

final loginCodeProvider =
    StateNotifierProvider<LoginCodeController, LoginCodeRequest?>((ref) {
  return LoginCodeController(ref.watch(tunnelChannelProvider));
});

final tunnelCapabilityProvider = FutureProvider<TunnelCapability>((ref) {
  return ref.watch(tunnelChannelProvider).capability();
});
