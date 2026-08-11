import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/geo_service.dart';
import '../../data/services/settings_store.dart';
import '../../data/services/tunnel_channel.dart';

final settingsStoreProvider = Provider<SettingsStore>((ref) {
  throw UnimplementedError('SettingsStore must be overridden at startup');
});

final tunnelChannelProvider = Provider<TunnelChannel>(
  (ref) => TunnelChannel.instance,
);

final geoServiceProvider = Provider<GeoService>((ref) {
  final service = GeoService();
  ref.onDispose(service.dispose);
  return service;
});

class AppPreferencesController extends StateNotifier<AppPreferences> {
  AppPreferencesController(this._store) : super(_store.readAppPreferences());

  final SettingsStore _store;

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    await _store.writeAppPreferences(state);
  }

  Future<void> setLocale(String code) async {
    state = state.copyWith(localeCode: code);
    await _store.writeAppPreferences(state);
  }

  Future<void> markIntroSeen() async {
    if (state.introSeen) return;
    state = state.copyWith(introSeen: true);
    await _store.writeAppPreferences(state);
  }
}

final appPreferencesProvider =
    StateNotifierProvider<AppPreferencesController, AppPreferences>((ref) {
  return AppPreferencesController(ref.watch(settingsStoreProvider));
});

final coreVersionProvider = FutureProvider<String>((ref) async {
  try {
    return await ref.watch(tunnelChannelProvider).coreVersion();
  } catch (_) {
    return 'unavailable';
  }
});
