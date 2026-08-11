import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../l10n/generated/app_localizations.dart';
import '../providers/tunnel_providers.dart';
import '../widgets/pickers.dart';
import '../widgets/screen_header.dart';
import '../widgets/settings_list.dart';

class ZeroTrustScreen extends ConsumerWidget {
  const ZeroTrustScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = L10n.of(context);
    final palette = context.palette;

    final settings = ref.watch(tunnelSettingsProvider);
    final controller = ref.read(tunnelSettingsProvider.notifier);

    final status = !settings.usesZeroTrust
        ? l10n.zeroTrustOff
        : (settings.zeroTrustReady
            ? l10n.zeroTrustReady
            : l10n.zeroTrustNeedsToken);

    return CupertinoPageScaffold(
      backgroundColor: palette.canvas,
      child: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: const EdgeInsets.only(bottom: 32),
              children: <Widget>[
                ScreenHeader(title: l10n.zeroTrust),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                  child: Text(
                    l10n.zeroTrustDesc,
                    style: AppText.caption(palette.labelSecondary),
                  ),
                ),
                SettingsGroup(
                  children: <Widget>[
                    SettingsRow(
                      title: l10n.zeroTrustTeam,
                      subtitle: l10n.zeroTrustTeamDesc,
                      value: settings.teamName.isEmpty
                          ? l10n.zeroTrustOff
                          : settings.teamName,
                      onTap: () => showTextEditorSheet(
                        context: context,
                        title: l10n.zeroTrustTeam,
                        description: l10n.zeroTrustTeamDesc,
                        initial: settings.team,
                        placeholder: 'my-team',
                        cancelLabel: l10n.cancel,
                        saveLabel: l10n.save,
                        onSaved: (v) =>
                            controller.update((s) => s.copyWith(team: v.trim())),
                      ),
                    ),
                    SettingsRow(
                      title: l10n.tunnelDeviceState,
                      value: status,
                    ),
                  ],
                ),
                SettingsGroup(
                  header: l10n.zeroTrustSignIn,
                  children: <Widget>[
                    SettingsRow(
                      title: l10n.zeroTrustEmail,
                      subtitle: l10n.zeroTrustEmailDesc,
                      value: settings.accessEmail.trim().isEmpty
                          ? l10n.ruleNone
                          : settings.accessEmail.trim(),
                      enabled: settings.usesZeroTrust,
                      onTap: () => showTextEditorSheet(
                        context: context,
                        title: l10n.zeroTrustEmail,
                        description: l10n.zeroTrustEmailDesc,
                        initial: settings.accessEmail,
                        placeholder: 'me@example.com',
                        cancelLabel: l10n.cancel,
                        saveLabel: l10n.save,
                        onSaved: (v) => controller
                            .update((s) => s.copyWith(accessEmail: v.trim())),
                      ),
                    ),
                  ],
                ),
                SettingsGroup(
                  header: l10n.zeroTrustToken,
                  children: <Widget>[
                    SettingsRow(
                      title: l10n.zeroTrustToken,
                      subtitle: l10n.zeroTrustTokenDesc,
                      value: settings.hasAccessToken
                          ? l10n.zeroTrustSet
                          : l10n.ruleNone,
                      enabled: settings.usesZeroTrust,
                      onTap: () => showTextEditorSheet(
                        context: context,
                        title: l10n.zeroTrustToken,
                        description: l10n.zeroTrustTokenDesc,
                        initial: settings.accessToken,
                        multiline: true,
                        cancelLabel: l10n.cancel,
                        saveLabel: l10n.save,
                        onSaved: (v) => controller
                            .update((s) => s.copyWith(accessToken: v.trim())),
                      ),
                    ),
                  ],
                ),
                SettingsGroup(
                  header: l10n.zeroTrustServiceToken,
                  children: <Widget>[
                    SettingsRow(
                      title: l10n.zeroTrustClientId,
                      value: settings.accessId.trim().isEmpty
                          ? l10n.ruleNone
                          : l10n.zeroTrustSet,
                      enabled: settings.usesZeroTrust,
                      onTap: () => showTextEditorSheet(
                        context: context,
                        title: l10n.zeroTrustClientId,
                        initial: settings.accessId,
                        cancelLabel: l10n.cancel,
                        saveLabel: l10n.save,
                        onSaved: (v) => controller
                            .update((s) => s.copyWith(accessId: v.trim())),
                      ),
                    ),
                    SettingsRow(
                      title: l10n.zeroTrustClientSecret,
                      value: settings.accessSecret.trim().isEmpty
                          ? l10n.ruleNone
                          : l10n.zeroTrustSet,
                      enabled: settings.usesZeroTrust,
                      onTap: () => showTextEditorSheet(
                        context: context,
                        title: l10n.zeroTrustClientSecret,
                        initial: settings.accessSecret,
                        cancelLabel: l10n.cancel,
                        saveLabel: l10n.save,
                        onSaved: (v) => controller
                            .update((s) => s.copyWith(accessSecret: v.trim())),
                      ),
                    ),
                  ],
                ),
                SettingsGroup(
                  children: <Widget>[
                    SettingsRow(
                      title: l10n.zeroTrustGateway,
                      subtitle: l10n.zeroTrustGatewayDesc,
                      enabled: settings.usesZeroTrust,
                      trailing: AppSwitch(
                        value: settings.gatewayProxy,
                        onChanged: settings.usesZeroTrust
                            ? (v) => controller
                                .update((s) => s.copyWith(gatewayProxy: v))
                            : null,
                      ),
                    ),
                    SettingsRow(
                      title: l10n.zeroTrustClear,
                      destructive: true,
                      enabled: settings.usesZeroTrust,
                      onTap: () => controller.update(
                        (s) => s.copyWith(
                          team: '',
                          accessToken: '',
                          accessId: '',
                          accessSecret: '',
                          accessEmail: '',
                          gatewayProxy: false,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
