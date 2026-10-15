import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/mtu_plan.dart';
import '../../data/models/tunnel_settings.dart';
import '../../l10n/generated/app_localizations.dart';
import '../providers/tunnel_providers.dart';
import '../widgets/mtu_optimizer_sheet.dart';
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

  String _ipDesc(L10n l10n, IpVersion value) => switch (value) {
    IpVersion.v4 => l10n.ipV4Desc,
    IpVersion.v6 => l10n.ipV6Desc,
    IpVersion.dual => l10n.ipDualDesc,
  };

  String _logTitle(L10n l10n, CoreLogLevel value) => switch (value) {
    CoreLogLevel.error => l10n.logLevelError,
    CoreLogLevel.warn => l10n.logLevelWarn,
    CoreLogLevel.info => l10n.logLevelInfo,
    CoreLogLevel.debug => l10n.logLevelDebug,
    CoreLogLevel.trace => l10n.logLevelTrace,
  };

  String _logDesc(L10n l10n, CoreLogLevel value) => switch (value) {
    CoreLogLevel.error => l10n.logLevelErrorDesc,
    CoreLogLevel.warn => l10n.logLevelWarnDesc,
    CoreLogLevel.info => l10n.logLevelInfoDesc,
    CoreLogLevel.debug => l10n.logLevelDebugDesc,
    CoreLogLevel.trace => l10n.logLevelTraceDesc,
  };

  String _perfTitle(L10n l10n, PerfProfile value) => switch (value) {
    PerfProfile.auto => l10n.perfAuto,
    PerfProfile.low => l10n.perfLow,
    PerfProfile.medium => l10n.perfMedium,
    PerfProfile.high => l10n.perfHigh,
  };

  String _perfDesc(L10n l10n, PerfProfile value) => switch (value) {
    PerfProfile.auto => l10n.perfAutoDesc,
    PerfProfile.low => l10n.perfLowDesc,
    PerfProfile.medium => l10n.perfMediumDesc,
    PerfProfile.high => l10n.perfHighDesc,
  };

  String _ruleSummary(L10n l10n, String raw) {
    final count = TunnelSettings.routeRules(raw).length;
    return count == 0 ? l10n.ruleNone : '$count';
  }

  String? _outOfRange(L10n l10n, String raw, int low, int high) {
    final parsed = int.tryParse(raw.trim());
    if (parsed != null && parsed >= low && parsed <= high) return null;
    return l10n.mtuRangeRefusal('$low', '$high');
  }

  String? _badPort(L10n l10n, String raw, int low, int high) {
    final parsed = int.tryParse(raw.trim());
    if (parsed != null && parsed >= low && parsed <= high) return null;
    return l10n.portRangeRefusal('$low', '$high');
  }

  String? _badSeconds(L10n l10n, String raw, int low, int high) {
    final parsed = int.tryParse(raw.trim());
    if (parsed != null && parsed >= low && parsed <= high) return null;
    return l10n.secondsRangeRefusal('$low', '$high');
  }

  List<String> _resolvers(String raw) => raw
      .split(RegExp(r'[,\s]+'))
      .map((part) => part.trim())
      .where(isIpAddress)
      .toList();

  bool _measurementBypassesTunnel() => Platform.isAndroid;

  Future<void> _optimiseMtu({
    required BuildContext context,
    required L10n l10n,
    required TunnelSettingsController controller,
    required TunnelSettings settings,
    required bool tunnelBusy,
  }) async {
    if (tunnelBusy && !_measurementBypassesTunnel()) {
      await showNoticeDialog(
        context: context,
        title: l10n.mtuOptimizeTitle,
        message: l10n.mtuOptimizeBusy,
        dismissLabel: l10n.confirm,
      );
      return;
    }

    final plan = await showMtuOptimizerSheet(
      context: context,
      settings: settings,
    );
    if (plan == null) return;

    await controller.update(
      (s) => s.copyWith(
        tunnelMtu: plan.tunnelMtu,
        coreMtu: plan.coreMtu,
        pathMtu: plan.pathMtu,
      ),
    );
  }

  Future<void> _editHop({
    required BuildContext context,
    required L10n l10n,
    required TunnelSettingsController controller,
    required TunnelSettings settings,
    required bool outer,
  }) {
    final title = outer ? l10n.wiwOuter : l10n.wiwInner;

    return showTextEditorSheet(
      context: context,
      title: title,
      description:
          '${outer ? l10n.wiwOuterDesc : l10n.wiwInnerDesc}\n\n'
          '${l10n.wiwHint}',
      initial: outer ? settings.wiwOuter : settings.wiwInner,
      placeholder: outer ? '162.159.192.1:2408' : '188.114.96.1:2408',
      cancelLabel: l10n.cancel,
      saveLabel: l10n.save,
      onSaved: (raw) async {
        final value = raw.trim();

        String? refusal;
        if (value.isNotEmpty && !TunnelSettings.isValidEndpoint(value)) {
          refusal = l10n.wiwInvalidEndpoint;
        } else {
          final next = outer
              ? settings.copyWith(wiwOuter: value)
              : settings.copyWith(wiwInner: value);
          if (next.wiwHopsCollide) refusal = l10n.wiwSameEdge;
        }

        if (refusal != null) {
          if (!context.mounted) return;
          await showNoticeDialog(
            context: context,
            title: title,
            message: refusal,
            dismissLabel: l10n.confirm,
          );
          return;
        }

        await controller.update(
          (s) =>
              outer ? s.copyWith(wiwOuter: value) : s.copyWith(wiwInner: value),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = L10n.of(context);
    final palette = context.palette;

    final settings = ref.watch(tunnelSettingsProvider);
    final controller = ref.read(tunnelSettingsProvider.notifier);
    final aether = settings.usesAether;

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
                        onSaved: (v) => controller.update(
                          (s) => s.copyWith(routeDirect: v),
                        ),
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
                        validator: (v) => _badPort(l10n, v, 1024, 65535),
                        onSaved: (v) => controller.update(
                          (s) => s.copyWith(socksPort: int.parse(v.trim())),
                        ),
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
                        onChanged: (v) => controller.update(
                          (s) => s.copyWith(overrideDns: v),
                        ),
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
                        validator: (v) =>
                            _resolvers(v).isEmpty ? l10n.dnsRefusal : null,
                        onSaved: (v) {
                          final parts = _resolvers(v);
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
                      enabled:
                          settings.usesWireGuard && !settings.usesGoolClassic,
                      onTap: () => showTextEditorSheet(
                        context: context,
                        title: l10n.wgEndpoint,
                        description: l10n.wgEndpointDesc,
                        initial: settings.wgEndpoint,
                        placeholder: '162.159.192.1:2408',
                        cancelLabel: l10n.cancel,
                        saveLabel: l10n.save,
                        onSaved: (v) => controller.update(
                          (s) => s.copyWith(wgEndpoint: v.trim()),
                        ),
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
                        onSaved: (v) => controller.update(
                          (s) => s.copyWith(h2Endpoint: v.trim()),
                        ),
                      ),
                    ),
                    SettingsRow(
                      title: l10n.apiAddress,
                      value: settings.apiAddress.trim().isEmpty
                          ? l10n.endpointAuto
                          : settings.apiAddress.trim(),
                      enabled: aether,
                      onTap: () => showTextEditorSheet(
                        context: context,
                        title: l10n.apiAddress,
                        description: l10n.apiAddressDesc,
                        initial: settings.apiAddress,
                        placeholder: '188.114.97.6',
                        cancelLabel: l10n.cancel,
                        saveLabel: l10n.save,
                        validator: (v) =>
                            v.trim().isEmpty || TunnelSettings.isApiAddress(v)
                            ? null
                            : l10n.apiAddressRefusal,
                        onSaved: (v) => controller.update(
                          (s) => s.copyWith(apiAddress: v.trim()),
                        ),
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
                                subtitle: _ipDesc(l10n, v),
                              ),
                            )
                            .toList(),
                        onSelected: (v) =>
                            controller.update((s) => s.copyWith(ipVersion: v)),
                      ),
                    ),
                  ],
                ),

                if (aether && settings.usesGoolClassic)
                  SettingsGroup(
                    header: l10n.wiwSection,
                    children: <Widget>[
                      SettingsRow(
                        title: l10n.wiwOuter,
                        subtitle: l10n.wiwOuterDesc,
                        value: settings.wiwOuterPeer.isEmpty
                            ? l10n.wiwScanned
                            : settings.wiwOuterPeer,
                        onTap: () => _editHop(
                          context: context,
                          l10n: l10n,
                          controller: controller,
                          settings: settings,
                          outer: true,
                        ),
                      ),
                      SettingsRow(
                        title: l10n.wiwInner,
                        subtitle: l10n.wiwInnerDesc,
                        value: settings.wiwInnerPeer.isEmpty
                            ? l10n.wiwScanned
                            : settings.wiwInnerPeer,
                        onTap: () => _editHop(
                          context: context,
                          l10n: l10n,
                          controller: controller,
                          settings: settings,
                          outer: false,
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
                      enabled: aether,
                      trailing: AppSwitch(
                        value: settings.usesEch,
                        onChanged: aether
                            ? (v) => controller.update(
                                (s) => s.copyWith(
                                  echMode: v ? EchMode.auto : EchMode.off,
                                ),
                              )
                            : null,
                      ),
                    ),
                    SettingsRow(
                      title: l10n.echDns,
                      value: settings.echDns.trim().isEmpty
                          ? l10n.endpointAuto
                          : settings.echDns.trim(),
                      enabled: aether && settings.usesEch,
                      onTap: () => showTextEditorSheet(
                        context: context,
                        title: l10n.echDns,
                        description: l10n.echDnsDesc,
                        initial: settings.echDns,
                        placeholder: 'udp://1.1.1.1',
                        cancelLabel: l10n.cancel,
                        saveLabel: l10n.save,
                        validator: (v) =>
                            v.trim().isEmpty || TunnelSettings.isEchResolver(v)
                            ? null
                            : l10n.echDnsRefusal,
                        onSaved: (v) => controller.update(
                          (s) => s.copyWith(echDns: v.trim()),
                        ),
                      ),
                    ),
                    SettingsRow(
                      title: l10n.echDomain,
                      value: settings.echDomain.trim().isEmpty
                          ? l10n.endpointAuto
                          : settings.echDomain.trim(),
                      enabled: aether && settings.usesEch,
                      onTap: () => showTextEditorSheet(
                        context: context,
                        title: l10n.echDomain,
                        description: l10n.echDomainDesc,
                        initial: settings.echDomain,
                        placeholder: 'cloudflare-ech.com',
                        cancelLabel: l10n.cancel,
                        saveLabel: l10n.save,
                        validator: (v) =>
                            v.trim().isEmpty ||
                                TunnelSettings.isDomainName(v.trim())
                            ? null
                            : l10n.domainRefusal,
                        onSaved: (v) => controller.update(
                          (s) => s.copyWith(echDomain: v.trim()),
                        ),
                      ),
                    ),
                    SettingsRow(
                      title: l10n.fragment,
                      subtitle: l10n.fragmentDesc,
                      enabled: aether,
                      trailing: AppSwitch(
                        value: settings.fragment,
                        onChanged: aether
                            ? (v) => controller.update(
                                (s) => s.copyWith(fragment: v),
                              )
                            : null,
                      ),
                    ),
                    SettingsRow(
                      title: l10n.fragmentSize,
                      subtitle: l10n.rangeHint,
                      value: settings.fragmentSize,
                      enabled: aether && settings.fragment,
                      onTap: () => showTextEditorSheet(
                        context: context,
                        title: l10n.fragmentSize,
                        description: l10n.rangeHint,
                        initial: settings.fragmentSize,
                        cancelLabel: l10n.cancel,
                        saveLabel: l10n.save,
                        validator: (v) => TunnelSettings.isValidRange(v)
                            ? null
                            : l10n.rangeHint,
                        onSaved: (v) => controller.update(
                          (s) => s.copyWith(fragmentSize: v.trim()),
                        ),
                      ),
                    ),
                    SettingsRow(
                      title: l10n.fragmentDelay,
                      subtitle: l10n.rangeHint,
                      value: settings.fragmentDelay,
                      enabled: aether && settings.fragment,
                      onTap: () => showTextEditorSheet(
                        context: context,
                        title: l10n.fragmentDelay,
                        description: l10n.rangeHint,
                        initial: settings.fragmentDelay,
                        cancelLabel: l10n.cancel,
                        saveLabel: l10n.save,
                        validator: (v) => TunnelSettings.isValidRange(v)
                            ? null
                            : l10n.rangeHint,
                        onSaved: (v) => controller.update(
                          (s) => s.copyWith(fragmentDelay: v.trim()),
                        ),
                      ),
                    ),
                    SettingsRow(
                      title: l10n.tlsGroups,
                      subtitle: l10n.tlsGroupsDesc,
                      value: settings.tlsGroups.isEmpty
                          ? l10n.endpointAuto
                          : settings.tlsGroups,
                      enabled: aether,
                      onTap: () => showTextEditorSheet(
                        context: context,
                        title: l10n.tlsGroups,
                        description: l10n.tlsGroupsDesc,
                        initial: settings.tlsGroups,
                        placeholder: 'P-256:X25519:P-384',
                        cancelLabel: l10n.cancel,
                        saveLabel: l10n.save,
                        onSaved: (v) => controller.update(
                          (s) => s.copyWith(tlsGroups: v.trim()),
                        ),
                      ),
                    ),
                    SettingsRow(
                      title: l10n.tlsCiphers,
                      value: settings.tlsCiphers.trim().isEmpty
                          ? l10n.endpointAuto
                          : settings.tlsCiphers.trim(),
                      enabled: aether,
                      onTap: () => showTextEditorSheet(
                        context: context,
                        title: l10n.tlsCiphers,
                        description: l10n.tlsCiphersDesc,
                        initial: settings.tlsCiphers,
                        placeholder:
                            'ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256',
                        cancelLabel: l10n.cancel,
                        saveLabel: l10n.save,
                        validator: (v) =>
                            v.trim().isEmpty || TunnelSettings.isCipherList(v)
                            ? null
                            : l10n.tlsCiphersRefusal,
                        onSaved: (v) => controller.update(
                          (s) => s.copyWith(tlsCiphers: v.trim()),
                        ),
                      ),
                    ),
                    SettingsRow(
                      title: l10n.grease,
                      subtitle: l10n.greaseDesc,
                      enabled: aether,
                      trailing: AppSwitch(
                        value: settings.grease,
                        onChanged: aether
                            ? (v) => controller.update(
                                (s) => s.copyWith(grease: v),
                              )
                            : null,
                      ),
                    ),
                  ],
                ),

                SettingsGroup(
                  header: l10n.sectionReliability,
                  children: <Widget>[
                    if (settings.usesAether)
                      SettingsRow(
                        title: l10n.fastFirstConnect,
                        subtitle: l10n.fastFirstConnectDesc,
                        trailing: AppSwitch(
                          value: settings.fastFirstConnect,
                          onChanged: (v) => controller.update(
                            (s) => s.copyWith(fastFirstConnect: v),
                          ),
                        ),
                      ),
                    SettingsRow(
                      title: l10n.quickReconnect,
                      subtitle: l10n.quickReconnectDesc,
                      trailing: AppSwitch(
                        value: settings.quickReconnect,
                        onChanged: (v) => controller.update(
                          (s) => s.copyWith(quickReconnect: v),
                        ),
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
                        validator: (v) => _badSeconds(l10n, v, 1, 120),
                        onSaved: (v) => controller.update(
                          (s) =>
                              s.copyWith(validateSeconds: int.parse(v.trim())),
                        ),
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
                        validator: (v) => _badSeconds(l10n, v, 1, 60),
                        onSaved: (v) => controller.update(
                          (s) =>
                              s.copyWith(reconnectSeconds: int.parse(v.trim())),
                        ),
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
                        validator: (v) => _badSeconds(l10n, v, 1, 120),
                        onSaved: (v) => controller.update(
                          (s) => s.copyWith(wgKeepalive: int.parse(v.trim())),
                        ),
                      ),
                    ),
                    SettingsRow(
                      title: l10n.wgProfileRetry,
                      subtitle: l10n.wgProfileRetryDesc,
                      enabled: settings.usesWireGuard,
                      trailing: AppSwitch(
                        value: settings.wgProfileRetry,
                        onChanged: settings.usesWireGuard
                            ? (v) => controller.update(
                                (s) => s.copyWith(wgProfileRetry: v),
                              )
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
                      subtitle: settings.pathMtu > 0
                          ? l10n.tunnelMtuMeasured('${settings.pathMtu}')
                          : l10n.tunnelMtuDesc,
                      value: '${settings.tunnelMtu}',
                      onTap: () => showTextEditorSheet(
                        context: context,
                        title: l10n.tunnelMtu,
                        description:
                            '${l10n.tunnelMtuDesc}\n${l10n.settingsNeedReconnect}',
                        initial: '${settings.tunnelMtu}',
                        digitsOnly: true,
                        cancelLabel: l10n.cancel,
                        saveLabel: l10n.save,
                        validator: (v) =>
                            _outOfRange(l10n, v, kTunnelMtuMin, kTunnelMtuMax),
                        onSaved: (v) => controller.update(
                          (s) => s.copyWith(
                            tunnelMtu: int.parse(v.trim()),
                            coreMtu: 0,
                          ),
                        ),
                      ),
                    ),
                    SettingsRow(
                      title: l10n.mtuOptimize,
                      subtitle: l10n.mtuOptimizeDesc,
                      onTap: () => _optimiseMtu(
                        context: context,
                        l10n: l10n,
                        controller: controller,
                        settings: settings,
                        tunnelBusy: !ref.read(tunnelProvider).stage.isIdle,
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
                                subtitle: _logDesc(l10n, v),
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
                                subtitle: _perfDesc(l10n, v),
                              ),
                            )
                            .toList(),
                        onSelected: (v) => controller.update(
                          (s) => s.copyWith(perfProfile: v),
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
