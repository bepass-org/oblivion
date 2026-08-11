import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/tunnel_settings.dart';
import '../../data/services/tunnel_channel.dart';
import '../../l10n/generated/app_localizations.dart';
import '../providers/app_providers.dart';
import '../providers/tunnel_providers.dart';
import '../widgets/screen_header.dart';
import '../widgets/settings_list.dart';

final _showSystemAppsProvider = StateProvider<bool>((ref) => false);

final _installedAppsProvider = FutureProvider<List<InstalledApp>>((ref) async {
  final includeSystem = ref.watch(_showSystemAppsProvider);
  try {
    final apps = await ref
        .watch(tunnelChannelProvider)
        .installedApps(includeSystem: includeSystem);
    apps.sort((a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()));
    return apps;
  } catch (_) {
    return const <InstalledApp>[];
  }
});

class SplitTunnelScreen extends ConsumerStatefulWidget {
  const SplitTunnelScreen({super.key});

  @override
  ConsumerState<SplitTunnelScreen> createState() => _SplitTunnelScreenState();
}

class _SplitTunnelScreenState extends ConsumerState<SplitTunnelScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final palette = context.palette;

    final settings = ref.watch(tunnelSettingsProvider);
    final controller = ref.read(tunnelSettingsProvider.notifier);
    final showSystem = ref.watch(_showSystemAppsProvider);
    final apps = ref.watch(_installedAppsProvider);

    final enabled = settings.splitTunnelMode == SplitTunnelMode.bypassSelected;

    return CupertinoPageScaffold(
      backgroundColor: palette.canvas,
      child: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              children: <Widget>[
                ScreenHeader(title: l10n.splitTunnel),
                SettingsGroup(
                  children: <Widget>[
                    SettingsRow(
                      title: l10n.splitTunnelBlacklist,
                      subtitle: enabled
                          ? l10n.splitBypassCount(
                              '${settings.bypassedApps.length}',
                            )
                          : l10n.splitTunnelDisabledDesc,
                      trailing: AppSwitch(
                        value: enabled,
                        onChanged: (value) => controller.update(
                          (s) => s.copyWith(
                            splitTunnelMode: value
                                ? SplitTunnelMode.bypassSelected
                                : SplitTunnelMode.disabled,
                          ),
                        ),
                      ),
                    ),
                    SettingsRow(
                      title: l10n.showSystemApps,
                      enabled: enabled,
                      trailing: AppSwitch(
                        value: showSystem,
                        onChanged: enabled
                            ? (value) => ref
                                .read(_showSystemAppsProvider.notifier)
                                .state = value
                            : null,
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: CupertinoTextField(
                    enabled: enabled,
                    placeholder: l10n.searchApps,
                    prefix: Padding(
                      padding: const EdgeInsetsDirectional.only(start: 10),
                      child: Icon(
                        CupertinoIcons.search,
                        size: 17,
                        color: palette.labelSecondary,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 11,
                    ),
                    style: AppText.rowTitle(palette.label),
                    placeholderStyle:
                        AppText.rowTitle(palette.labelSecondary),
                    decoration: BoxDecoration(
                      color: palette.card,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: palette.separator),
                    ),
                    onChanged: (value) =>
                        setState(() => _query = value.toLowerCase()),
                  ),
                ),
                Expanded(
                  child: apps.when(
                    loading: () => const Center(
                      child: CupertinoActivityIndicator(radius: 10),
                    ),
                    error: (_, _) => Center(
                      child: Text(
                        l10n.logsEmpty,
                        style: AppText.caption(palette.labelSecondary),
                      ),
                    ),
                    data: (list) {
                      final visible = _query.isEmpty
                          ? list
                          : list
                              .where(
                                (app) =>
                                    app.label.toLowerCase().contains(_query) ||
                                    app.packageName
                                        .toLowerCase()
                                        .contains(_query),
                              )
                              .toList();

                      if (visible.isEmpty) {
                        return Center(
                          child: Text(
                            l10n.logsFilterEmpty,
                            style: AppText.caption(palette.labelSecondary),
                          ),
                        );
                      }

                      return ListView.separated(
                        itemCount: visible.length,
                        separatorBuilder: (_, _) => Padding(
                          padding: const EdgeInsetsDirectional.only(start: 16),
                          child: Container(
                            height: 1,
                            color: palette.separator,
                          ),
                        ),
                        itemBuilder: (context, index) {
                          final app = visible[index];
                          final bypassed =
                              settings.bypassedApps.contains(app.packageName);

                          return _AppRow(
                            app: app,
                            enabled: enabled,
                            bypassed: bypassed,
                            onChanged: (value) {
                              final next =
                                  settings.bypassedApps.toSet();
                              if (value) {
                                next.add(app.packageName);
                              } else {
                                next.remove(app.packageName);
                              }
                              controller.update(
                                (s) => s.copyWith(bypassedApps: next),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AppRow extends StatelessWidget {
  const _AppRow({
    required this.app,
    required this.enabled,
    required this.bypassed,
    required this.onChanged,
  });

  final InstalledApp app;
  final bool enabled;
  final bool bypassed;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      color: palette.card,
      padding: const EdgeInsetsDirectional.fromSTEB(16, 10, 16, 10),
      child: Row(
        children: <Widget>[
          _AppIcon(bytes: app.icon),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  app.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.rowTitle(
                    enabled ? palette.label : palette.labelSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  app.packageName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textDirection: TextDirection.ltr,
                  style: AppText.caption(palette.labelSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          AppSwitch(
            value: bypassed,
            onChanged: enabled ? onChanged : null,
          ),
        ],
      ),
    );
  }
}

class _AppIcon extends StatelessWidget {
  const _AppIcon({required this.bytes});

  final Uint8List? bytes;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final data = bytes;

    return SizedBox(
      width: 34,
      height: 34,
      child: data == null || data.isEmpty
          ? DecoratedBox(
              decoration: BoxDecoration(
                color: palette.cardPressed,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                CupertinoIcons.app,
                size: 17,
                color: palette.labelSecondary,
              ),
            )
          : ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.memory(data, fit: BoxFit.cover),
            ),
    );
  }
}
