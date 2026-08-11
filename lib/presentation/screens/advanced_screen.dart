import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/tunnel_settings.dart';
import '../../l10n/generated/app_localizations.dart';
import '../providers/tunnel_providers.dart';
import '../widgets/pickers.dart';
import '../widgets/screen_header.dart';
import '../widgets/settings_list.dart';
import 'settings_screen.dart';

class AdvancedScreen extends ConsumerWidget {
  const AdvancedScreen({super.key});

  String _ipTitle(L10n l10n, IpVersion value) => switch (value) {
        IpVersion.v4 => l10n.ipV4,
        IpVersion.v6 => l10n.ipV6,
        IpVersion.dual => l10n.ipDual,
      };

  String _logTitle(L10n l10n, CoreLogLevel value) => switch (value) {
        CoreLogLevel.error => l10n.logLevelError,
        CoreLogLevel.warn => l10n.logLevelWarn,
        CoreLogLevel.info => l10n.logLevelInfo,
        CoreLogLevel.debug => l10n.logLevelDebug,
        CoreLogLevel.trace => l10n.logLevelTrace,
      };

  String _perfTitle(L10n l10n, PerfProfile value) => switch (value) {
        PerfProfile.auto => l10n.perfAuto,
        PerfProfile.low => l10n.perfLow,
        PerfProfile.medium => l10n.perfMedium,
        PerfProfile.high => l10n.perfHigh,
      };

  String _ruleSummary(L10n l10n, String raw) {
    final count = TunnelSettings.routeRules(raw).length;
    return count == 0 ? l10n.ruleNone : '$count';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = L10n.of(context);
    final palette = context.palette;

    final settings = ref.watch(tunnelSettingsProvider);
    final controller = ref.read(tunnelSettingsProvider.notifier);

    final String capabilityLabel;
    if (isMobilePlatform) {
      capabilityLabel = '';
    } else {
      final capability = ref.watch(tunnelCapabilityProvider).value;
      if (capability == null) {
        capabilityLabel = '';
      } else if (!capability.embedded) {
        capabilityLabel = l10n.tunnelDeviceMissing;
      } else if (!capability.privileged) {
        capabilityLabel = l10n.tunnelNeedsPrivileges;
      } else {
        capabilityLabel = l10n.tunnelReady;
      }
    }

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
                ScreenHeader(title: l10n.sectionAdvanced),

                SettingsGroup(
                  header: l10n.sectionRules,
                  children: <Widget>[
                    SettingsRow(
                      title: l10n.ruleBlock,
                      subtitle: l10n.ruleBlockDesc,
                      value: _ruleSummary(l10n, settings.routeBlock),
                      onTap: () => showTextEditorSheet(
                        context: context,
                        title: l10n.ruleBlock,
                        description: l10n.ruleHint,
                        initial: settings.routeBlock,
                        placeholder: 'ads.example.com\nkeyword:tracker',
                        multiline: true,
                        cancelLabel: l10n.cancel,
                        saveLabel: l10n.save,
                        onSaved: (v) =>
                            controller.update((s) => s.copyWith(routeBlock: v)),
                      ),
                    ),
                    SettingsRow(
                      title: l10n.ruleDirect,
                      subtitle: l10n.ruleDirectDesc,
                      value: _ruleSummary(l10n, settings.routeDirect),
                      onTap: () => showTextEditorSheet(
                        context: context,
                        title: l10n.ruleDirect,
                        description: l10n.ruleHint,
                        initial: settings.routeDirect,
                        placeholder: 'private\nip:192.168.0.0/16',
                        multiline: true,
                        cancelLabel: l10n.cancel,
                        saveLabel: l10n.save,
                        onSaved: (v) => controller
                            .update((s) => s.copyWith(routeDirect: v)),
                      ),
                    ),
                  ],
                ),

                SettingsGroup(
                  header: l10n.sectionNetwork,
                  children: <Widget>[
                    SettingsRow(
                      title: l10n.socksPort,
                      subtitle: l10n.socksPortDesc,
                      value: '${settings.socksPort}',
                      onTap: () => showTextEditorSheet(
                        context: context,
                        title: l10n.socksPort,
                        description: l10n.socksPortDesc,
                        initial: '${settings.socksPort}',
                        digitsOnly: true,
                        cancelLabel: l10n.cancel,
                        saveLabel: l10n.save,
                        onSaved: (v) {
                          final port = int.tryParse(v.trim());
                          if (port == null || port < 1024 || port > 65535) {
                            return;
                          }
                          controller.update((s) => s.copyWith(socksPort: port));
                        },
                      ),
                    ),
                    SettingsRow(
                      title: l10n.allowLan,
                      subtitle: l10n.allowLanDesc,
                      trailing: AppSwitch(
                        value: settings.allowLan,
                        onChanged: (v) =>
                            controller.update((s) => s.copyWith(allowLan: v)),
                      ),
                    ),
                    SettingsRow(
                      title: l10n.dnsOverride,
                      subtitle: l10n.dnsOverrideDesc,
                      trailing: AppSwitch(
                        value: settings.overrideDns,
                        onChanged: (v) =>
                            controller.update((s) => s.copyWith(overrideDns: v)),
                      ),
                    ),
                    SettingsRow(
                      title: l10n.dnsServers,
                      value: '${settings.dnsPrimary}, ${settings.dnsSecondary}',
                      enabled: settings.overrideDns,
                      onTap: () => showTextEditorSheet(
                        context: context,
                        title: l10n.dnsServers,
                        description: l10n.dnsServersDesc,
                        initial:
                            '${settings.dnsPrimary}, ${settings.dnsSecondary}',
                        placeholder: '1.1.1.1, 1.0.0.1',
                        cancelLabel: l10n.cancel,
                        saveLabel: l10n.save,
                        onSaved: (v) {
                          final parts = v
                              .split(RegExp(r'[,\s]+'))
                              .map((part) => part.trim())
                              .where(isIpAddress)
                              .toList();
                          if (parts.isEmpty) return;
                          controller.update(
                            (s) => s.copyWith(
                              dnsPrimary: parts.first,
                              dnsSecondary: parts.length > 1 ? parts[1] : '',
                            ),
                          );
                        },
                      ),
                    ),
                    SettingsRow(
                      title: l10n.wgEndpoint,
                      value: settings.wgEndpoint.isEmpty
                          ? l10n.endpointAuto
                          : settings.wgEndpoint,
                      enabled: settings.usesWireGuard,
                      onTap: () => showTextEditorSheet(
                        context: context,
                        title: l10n.wgEndpoint,
                        description: l10n.wgEndpointDesc,
                        initial: settings.wgEndpoint,
                        placeholder: '162.159.192.1:2408',
                        cancelLabel: l10n.cancel,
                        saveLabel: l10n.save,
                        onSaved: (v) => controller
                            .update((s) => s.copyWith(wgEndpoint: v.trim())),
                      ),
                    ),
                    SettingsRow(
                      title: l10n.h2Endpoint,
                      value: settings.h2Endpoint.isEmpty
                          ? l10n.endpointAuto
                          : settings.h2Endpoint,
                      enabled: settings.usesHttp2,
                      onTap: () => showTextEditorSheet(
                        context: context,
                        title: l10n.h2Endpoint,
                        description: l10n.h2EndpointDesc,
                        initial: settings.h2Endpoint,
                        cancelLabel: l10n.cancel,
                        saveLabel: l10n.save,
                        onSaved: (v) => controller
                            .update((s) => s.copyWith(h2Endpoint: v.trim())),
                      ),
                    ),
                    SettingsRow(
                      title: l10n.ipVersion,
                      value: _ipTitle(l10n, settings.ipVersion),
                      onTap: () => showChoiceSheet<IpVersion>(
                        context: context,
                        title: l10n.ipVersion,
                        selected: settings.ipVersion,
                        options: IpVersion.values
                            .map(
                              (v) => PickerOption<IpVersion>(
                                value: v,
                                title: _ipTitle(l10n, v),
                              ),
                            )
                            .toList(),
                        onSelected: (v) =>
                            controller.update((s) => s.copyWith(ipVersion: v)),
                      ),
                    ),
                  ],
                ),

                SettingsGroup(
                  header: l10n.sectionTls,
                  children: <Widget>[
                    SettingsRow(
                      title: l10n.ech,
                      subtitle: l10n.echDesc,
                      enabled: settings.isMasque,
                      trailing: AppSwitch(
                        value: settings.echMode == EchMode.auto,
                        onChanged: settings.isMasque
                            ? (v) => controller.update(
                                  (s) => s.copyWith(
                                    echMode: v ? EchMode.auto : EchMode.off,
                                  ),
                                )
                            : null,
                      ),
                    ),
                    SettingsRow(
                      title: l10n.fragment,
                      subtitle: settings.usesHttp2
                          ? l10n.fragmentDesc
                          : l10n.fragmentNeedsHttp2,
                      enabled: settings.usesHttp2,
                      trailing: AppSwitch(
                        value: settings.fragment,
                        onChanged: settings.usesHttp2
                            ? (v) =>
                                controller.update((s) => s.copyWith(fragment: v))
                            : null,
                      ),
                    ),
                    SettingsRow(
                      title: l10n.fragmentSize,
                      subtitle: l10n.rangeHint,
                      value: settings.fragmentSize,
                      enabled: settings.usesHttp2 && settings.fragment,
                      onTap: () => showTextEditorSheet(
                        context: context,
                        title: l10n.fragmentSize,
                        description: l10n.rangeHint,
                        initial: settings.fragmentSize,
                        cancelLabel: l10n.cancel,
                        saveLabel: l10n.save,
                        onSaved: (v) {
                          if (!TunnelSettings.isValidRange(v)) return;
                          controller.update(
                            (s) => s.copyWith(fragmentSize: v.trim()),
                          );
                        },
                      ),
                    ),
                    SettingsRow(
                      title: l10n.fragmentDelay,
                      subtitle: l10n.rangeHint,
                      value: settings.fragmentDelay,
                      enabled: settings.usesHttp2 && settings.fragment,
                      onTap: () => showTextEditorSheet(
                        context: context,
                        title: l10n.fragmentDelay,
                        description: l10n.rangeHint,
                        initial: settings.fragmentDelay,
                        cancelLabel: l10n.cancel,
                        saveLabel: l10n.save,
                        onSaved: (v) {
                          if (!TunnelSettings.isValidRange(v)) return;
                          controller.update(
                            (s) => s.copyWith(fragmentDelay: v.trim()),
                          );
                        },
                      ),
                    ),
                    SettingsRow(
                      title: l10n.tlsGroups,
                      subtitle: l10n.tlsGroupsDesc,
                      value: settings.tlsGroups.isEmpty
                          ? l10n.endpointAuto
                          : settings.tlsGroups,
                      enabled: settings.isMasque,
                      onTap: () => showTextEditorSheet(
                        context: context,
                        title: l10n.tlsGroups,
                        description: l10n.tlsGroupsDesc,
                        initial: settings.tlsGroups,
                        placeholder: 'X25519:P-256',
                        cancelLabel: l10n.cancel,
                        saveLabel: l10n.save,
                        onSaved: (v) => controller
                            .update((s) => s.copyWith(tlsGroups: v.trim())),
                      ),
                    ),
                  ],
                ),

                SettingsGroup(
                  header: l10n.sectionReliability,
                  children: <Widget>[
                    SettingsRow(
                      title: l10n.quickReconnect,
                      subtitle: l10n.quickReconnectDesc,
                      trailing: AppSwitch(
                        value: settings.quickReconnect,
                        onChanged: (v) => controller
                            .update((s) => s.copyWith(quickReconnect: v)),
                      ),
                    ),
                    SettingsRow(
                      title: l10n.dataCheck,
                      subtitle: l10n.dataCheckDesc,
                      trailing: AppSwitch(
                        value: settings.dataCheck,
                        onChanged: (v) =>
                            controller.update((s) => s.copyWith(dataCheck: v)),
                      ),
                    ),
                    SettingsRow(
                      title: l10n.validateSeconds,
                      value: '${settings.validateSeconds}s',
                      onTap: () => showTextEditorSheet(
                        context: context,
                        title: l10n.validateSeconds,
                        description: l10n.validateSecondsDesc,
                        initial: '${settings.validateSeconds}',
                        digitsOnly: true,
                        cancelLabel: l10n.cancel,
                        saveLabel: l10n.save,
                        onSaved: (v) {
                          final secs = int.tryParse(v.trim());
                          if (secs == null || secs < 1 || secs > 120) return;
                          controller.update(
                            (s) => s.copyWith(validateSeconds: secs),
                          );
                        },
                      ),
                    ),
                    SettingsRow(
                      title: l10n.reconnectSeconds,
                      value: '${settings.reconnectSeconds}s',
                      onTap: () => showTextEditorSheet(
                        context: context,
                        title: l10n.reconnectSeconds,
                        description: l10n.reconnectSecondsDesc,
                        initial: '${settings.reconnectSeconds}',
                        digitsOnly: true,
                        cancelLabel: l10n.cancel,
                        saveLabel: l10n.save,
                        onSaved: (v) {
                          final secs = int.tryParse(v.trim());
                          if (secs == null || secs < 1 || secs > 60) return;
                          controller.update(
                            (s) => s.copyWith(reconnectSeconds: secs),
                          );
                        },
                      ),
                    ),
                    SettingsRow(
                      title: l10n.wgKeepalive,
                      value: '${settings.wgKeepalive}s',
                      enabled: settings.usesWireGuard,
                      onTap: () => showTextEditorSheet(
                        context: context,
                        title: l10n.wgKeepalive,
                        description: l10n.wgKeepaliveDesc,
                        initial: '${settings.wgKeepalive}',
                        digitsOnly: true,
                        cancelLabel: l10n.cancel,
                        saveLabel: l10n.save,
                        onSaved: (v) {
                          final secs = int.tryParse(v.trim());
                          if (secs == null || secs < 1 || secs > 120) return;
                          controller
                              .update((s) => s.copyWith(wgKeepalive: secs));
                        },
                      ),
                    ),
                    SettingsRow(
                      title: l10n.wgProfileRetry,
                      subtitle: l10n.wgProfileRetryDesc,
                      enabled: settings.usesWireGuard,
                      trailing: AppSwitch(
                        value: settings.wgProfileRetry,
                        onChanged: settings.usesWireGuard
                            ? (v) => controller
                                .update((s) => s.copyWith(wgProfileRetry: v))
                            : null,
                      ),
                    ),
                  ],
                ),

                SettingsGroup(
                  header: l10n.sectionDevice,
                  children: <Widget>[
                    if (!isMobilePlatform)
                      SettingsRow(
                        title: l10n.tunnelDeviceState,
                        value: capabilityLabel.isEmpty ? null : capabilityLabel,
                      ),
                    SettingsRow(
                      title: l10n.tunnelMtu,
                      subtitle: l10n.tunnelMtuDesc,
                      value: '${settings.tunnelMtu}',
                      onTap: () => showTextEditorSheet(
                        context: context,
                        title: l10n.tunnelMtu,
                        description: l10n.tunnelMtuDesc,
                        initial: '${settings.tunnelMtu}',
                        digitsOnly: true,
                        cancelLabel: l10n.cancel,
                        saveLabel: l10n.save,
                        onSaved: (v) {
                          final mtu = int.tryParse(v.trim());
                          if (mtu == null || mtu < 1280 || mtu > 9000) return;
                          controller.update((s) => s.copyWith(tunnelMtu: mtu));
                        },
                      ),
                    ),
                    SettingsRow(
                      title: l10n.logLevel,
                      value: _logTitle(l10n, settings.logLevel),
                      onTap: () => showChoiceSheet<CoreLogLevel>(
                        context: context,
                        title: l10n.logLevel,
                        selected: settings.logLevel,
                        options: CoreLogLevel.values
                            .map(
                              (v) => PickerOption<CoreLogLevel>(
                                value: v,
                                title: _logTitle(l10n, v),
                              ),
                            )
                            .toList(),
                        onSelected: (v) =>
                            controller.update((s) => s.copyWith(logLevel: v)),
                      ),
                    ),
                    SettingsRow(
                      title: l10n.perfProfile,
                      subtitle: l10n.perfProfileDesc,
                      value: _perfTitle(l10n, settings.perfProfile),
                      onTap: () => showChoiceSheet<PerfProfile>(
                        context: context,
                        title: l10n.perfProfile,
                        selected: settings.perfProfile,
                        options: PerfProfile.values
                            .map(
                              (v) => PickerOption<PerfProfile>(
                                value: v,
                                title: _perfTitle(l10n, v),
                              ),
                            )
                            .toList(),
                        onSelected: (v) => controller
                            .update((s) => s.copyWith(perfProfile: v)),
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
