import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/platform/desktop_shell.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/geo_endpoint.dart';
import '../../data/models/tunnel_status.dart';
import '../../l10n/generated/app_localizations.dart';
import '../providers/tunnel_providers.dart';
import '../widgets/connect_switch.dart';
import '../widgets/flag_icon.dart';
import '../widgets/login_code_dialog.dart';
import '../widgets/screen_header.dart';
import 'about_screen.dart';
import 'logs_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  String _stateLabel(L10n l10n, TunnelStage stage) => switch (stage) {
        TunnelStage.disconnected => l10n.stateDisconnected,
        TunnelStage.connecting => l10n.stateConnecting,
        TunnelStage.validating => l10n.stateValidating,
        TunnelStage.connected => l10n.stateConnected,
        TunnelStage.disconnecting => l10n.stateDisconnecting,
        TunnelStage.failed => l10n.stateFailed,
      };

  Future<void> _connect(BuildContext context, WidgetRef ref) async {
    final granted = await ref.read(tunnelProvider.notifier).connect();
    if (granted || !context.mounted) return;

    final l10n = L10n.of(context);
    await showCupertinoDialog<void>(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: Text(l10n.vpnPermissionNeeded),
        content: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(l10n.vpnPermissionDenied),
        ),
        actions: <Widget>[
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );
  }

  void _open(BuildContext context, Widget page) {
    Navigator.of(context).push(
      CupertinoPageRoute<void>(builder: (_) => page),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final l10n = L10n.of(context);

    final status = ref.watch(tunnelProvider);
    final settings = ref.watch(tunnelSettingsProvider);
    final geo = ref.watch(geoProvider);

    ref.listen<LoginCodeRequest?>(loginCodeProvider, (previous, next) {
      if (next != null) showLoginCodeDialog(context);
    });

    final degraded = DesktopShell.isSupported &&
        status.stage.isActive &&
        settings.tunnelMode &&
        !status.tunnelDeviceUp;

    return CupertinoPageScaffold(
      backgroundColor: palette.canvas,
      child: SafeArea(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(8, 4, 8, 0),
              child: Row(
                children: <Widget>[
                  IconButtonPlain(
                    icon: CupertinoIcons.info_circle,
                    onTap: () => _open(context, const AboutScreen()),
                  ),
                  const Spacer(),
                  IconButtonPlain(
                    icon: CupertinoIcons.doc_text,
                    onTap: () => _open(context, const LogsScreen()),
                  ),
                  IconButtonPlain(
                    icon: CupertinoIcons.settings,
                    onTap: () => _open(context, const SettingsScreen()),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        l10n.appName.toUpperCase(),
                        textDirection: TextDirection.ltr,
                        style: AppText.wordmark(palette.label),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        l10n.appTagline,
                        textAlign: TextAlign.center,
                        style: AppText.state(palette.primary),
                      ),
                      const SizedBox(height: 44),
                      ConnectSwitch(
                        stage: status.stage,
                        onConnect: () => _connect(context, ref),
                        onDisconnect: () =>
                            ref.read(tunnelProvider.notifier).disconnect(),
                      ),
                      const SizedBox(height: 26),
                      Text(
                        _stateLabel(l10n, status.stage),
                        style: AppText.state(
                          status.stage == TunnelStage.failed
                              ? palette.danger
                              : palette.labelSecondary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 44,
                        child: _Detail(status: status, geo: geo),
                      ),
                      if (degraded)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 6,
                          ),
                          child: Column(
                            children: <Widget>[
                              Text(
                                l10n.tunnelDegraded,
                                textAlign: TextAlign.center,
                                style: AppText.caption(palette.danger),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                l10n.tunnelDegradedHint,
                                textAlign: TextAlign.center,
                                style: AppText.caption(palette.labelSecondary),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail({required this.status, required this.geo});

  final TunnelStatus status;
  final GeoSnapshot geo;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final l10n = L10n.of(context);

    if (!status.stage.isActive) {
      if (status.stage.isBusy) {
        return const Center(child: CupertinoActivityIndicator(radius: 9));
      }
      return const SizedBox.shrink();
    }

    final exit = geo.exit;
    if (exit == null) {
      return Center(
        child: Text(
          l10n.detectingLocation,
          style: AppText.caption(palette.labelSecondary),
        ),
      );
    }

    final place = <String>[
      if (exit.country != null && exit.country!.isNotEmpty)
        exit.country!
      else if (exit.countryCode.isNotEmpty)
        exit.countryCode,
      if (exit.colo != null && exit.colo!.isNotEmpty) exit.colo!,
    ].join('  ·  ');

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (exit.countryCode.isNotEmpty) ...<Widget>[
              FlagIcon(countryCode: exit.countryCode),
              const SizedBox(width: 8),
            ],
            Text(
              exit.ip,
              textDirection: TextDirection.ltr,
              style: AppText.rowTitle(palette.label),
            ),
            const SizedBox(width: 8),
            _WarpBadge(status: exit.warp),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          <String>[
            if (place.isNotEmpty) place,
            if (exit.isp != null && exit.isp!.isNotEmpty) exit.isp!,
          ].join('  ·  '),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppText.caption(palette.labelSecondary),
        ),
      ],
    );
  }
}

class _WarpBadge extends StatelessWidget {
  const _WarpBadge({required this.status});

  final WarpStatus status;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    if (status == WarpStatus.unknown) return const SizedBox.shrink();

    final (label, tone) = switch (status) {
      WarpStatus.plus => ('WARP+', palette.primary),
      WarpStatus.on => ('WARP', palette.primary),
      _ => ('WARP OFF', palette.danger),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        label,
        textDirection: TextDirection.ltr,
        style: AppText.caption(tone).copyWith(
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
