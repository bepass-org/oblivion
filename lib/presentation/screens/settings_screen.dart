import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/tunnel_settings.dart';
import '../../l10n/generated/app_localizations.dart';
import '../providers/app_providers.dart';
import '../providers/tunnel_providers.dart';
import '../widgets/developer_note.dart';
import '../widgets/pickers.dart';
import '../widgets/screen_header.dart';
import '../widgets/settings_list.dart';
import 'advanced_screen.dart';
import 'psiphon_screen.dart';
import 'split_tunnel_screen.dart';
import 'zero_trust_screen.dart';

String coreTitle(L10n l10n, CoreEngine value) => switch (value) {
  CoreEngine.aether => l10n.coreAether,
  CoreEngine.psiphon => l10n.corePsiphon,
  CoreEngine.chain => l10n.coreChain,
  CoreEngine.psiphonReverse => l10n.corePsiphonReverse,
  CoreEngine.tor => l10n.coreTor,
  CoreEngine.torChain => l10n.coreTorChain,
  CoreEngine.torReverse => l10n.coreTorReverse,
};

String coreDesc(L10n l10n, CoreEngine value) => switch (value) {
  CoreEngine.aether => l10n.coreAetherDesc,
  CoreEngine.psiphon => l10n.corePsiphonDesc,
  CoreEngine.chain => l10n.coreChainDesc,
  CoreEngine.psiphonReverse => l10n.corePsiphonReverseDesc,
  CoreEngine.tor => l10n.coreTorDesc,
  CoreEngine.torChain => l10n.coreTorChainDesc,
  CoreEngine.torReverse => l10n.coreTorReverseDesc,
};

String chainedEngineName(L10n l10n, TunnelSettings settings) =>
    settings.usesTor ? l10n.coreTor : l10n.corePsiphon;

String torRelaysTitle(L10n l10n, TorRelays value) => switch (value) {
  TorRelays.auto => l10n.torRelaysAuto,
  TorRelays.only => l10n.torRelaysOnly,
  TorRelays.off => l10n.torRelaysOff,
};

String protocolTitle(L10n l10n, CoreProtocol value) => switch (value) {
  CoreProtocol.masque => l10n.protocolMasque,
  CoreProtocol.wireguard => l10n.protocolWireGuard,
  CoreProtocol.gool => l10n.protocolGool,
  CoreProtocol.mim => l10n.protocolMim,
};

String protocolDesc(L10n l10n, CoreProtocol value) => switch (value) {
  CoreProtocol.masque => l10n.protocolMasqueDesc,
  CoreProtocol.wireguard => l10n.protocolWireGuardDesc,
  CoreProtocol.gool => l10n.protocolGoolDesc,
  CoreProtocol.mim => l10n.protocolMimDesc,
};

String scanTitle(L10n l10n, ScanMode value) => switch (value) {
  ScanMode.turbo => l10n.scanTurbo,
  ScanMode.balanced => l10n.scanBalanced,
  ScanMode.thorough => l10n.scanThorough,
  ScanMode.verified => l10n.scanVerified,
  ScanMode.ironclad => l10n.scanIronclad,
};

String scanDesc(L10n l10n, ScanMode value) => switch (value) {
  ScanMode.turbo => l10n.scanTurboDesc,
  ScanMode.balanced => l10n.scanBalancedDesc,
  ScanMode.thorough => l10n.scanThoroughDesc,
  ScanMode.verified => l10n.scanVerifiedDesc,
  ScanMode.ironclad => l10n.scanIroncladDesc,
};

String obfuscationTitle(L10n l10n, ObfuscationProfile value) => switch (value) {
  ObfuscationProfile.off => l10n.obfuscationOff,
  ObfuscationProfile.light => l10n.obfuscationLight,
  ObfuscationProfile.firewall => l10n.obfuscationFirewall,
  ObfuscationProfile.balanced => l10n.obfuscationBalanced,
  ObfuscationProfile.gfw => l10n.obfuscationGfw,
  ObfuscationProfile.aggressive => l10n.obfuscationAggressive,
};

String obfuscationDesc(L10n l10n, ObfuscationProfile value) => switch (value) {
  ObfuscationProfile.off => l10n.obfuscationOffDesc,
  ObfuscationProfile.light => l10n.obfuscationLightDesc,
  ObfuscationProfile.firewall => l10n.obfuscationFirewallDesc,
  ObfuscationProfile.balanced => l10n.obfuscationBalancedDesc,
  ObfuscationProfile.gfw => l10n.obfuscationGfwDesc,
  ObfuscationProfile.aggressive => l10n.obfuscationAggressiveDesc,
};

String routingTitle(L10n l10n, RoutingMode value) => switch (value) {
  RoutingMode.socksOnly => l10n.routingSocks,
  RoutingMode.systemProxy => l10n.routingSystem,
  RoutingMode.fullTunnel => l10n.tunnelModeActive,
};

bool get isMobilePlatform => Platform.isAndroid || Platform.isIOS;

String routingDesc(L10n l10n, RoutingMode value) => switch (value) {
  RoutingMode.socksOnly => l10n.routingSocksDesc,
  RoutingMode.systemProxy => l10n.routingSystemDesc,
  RoutingMode.fullTunnel =>
    isMobilePlatform ? l10n.routingTunnelDescMobile : l10n.routingTunnelDesc,
};

bool isIpAddress(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return false;
  return InternetAddress.tryParse(trimmed) != null;
}

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = L10n.of(context);
    final palette = context.palette;

    final settings = ref.watch(tunnelSettingsProvider);
    final controller = ref.read(tunnelSettingsProvider.notifier);
    final prefs = ref.watch(appPreferencesProvider);
    final prefsController = ref.read(appPreferencesProvider.notifier);

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
                ScreenHeader(title: l10n.settings),
                SettingsGroup(
                  children: <Widget>[
                    SettingsRow(
                      title: l10n.devNote,
                      subtitle: l10n.devNoteDesc,
                      onTap: () => showDeveloperNote(context),
                    ),
                  ],
                ),
                SettingsGroup(
                  children: <Widget>[
                    SettingsRow(
                      title: l10n.coreEngine,
                      subtitle: coreDesc(l10n, settings.core),
                      value: coreTitle(l10n, settings.core),
                      onTap: () => showChoiceSheet<CoreEngine>(
                        context: context,
                        title: l10n.coreEngine,
                        selected: settings.core,
                        options: CoreEngine.values
                            .map(
                              (v) => PickerOption<CoreEngine>(
                                value: v,
                                title: coreTitle(l10n, v),
                                subtitle: coreDesc(l10n, v),
                              ),
                            )
                            .toList(),
                        onSelected: (v) =>
                            controller.update((s) => s.copyWith(core: v)),
                      ),
                    ),
                    if (settings.carriesInside)
                      SettingsRow(
                        title: l10n.chainOrder,
                        subtitle: l10n.chainOrderDesc(
                          protocolTitle(l10n, settings.effectiveProtocol),
                          chainedEngineName(l10n, settings),
                        ),
                        value:
                            '${settings.aetherSocksPort} → '
                            '${settings.socksPort}',
                      ),
                    if (settings.dialsThrough)
                      SettingsRow(
                        title: l10n.chainOrder,
                        subtitle: l10n.chainOrderReverseDesc(
                          chainedEngineName(l10n, settings),
                        ),
                      ),
                    if (settings.usesPsiphon)
                      SettingsRow(
                        title: l10n.psiphonSettings,
                        subtitle: psiphonModeDesc(l10n, settings.psiphonMode),
                        value: psiphonModeTitle(l10n, settings.psiphonMode),
                        onTap: () => Navigator.of(context).push(
                          CupertinoPageRoute<void>(
                            builder: (_) => const PsiphonScreen(),
                          ),
                        ),
                      ),
                    if (settings.usesTor)
                      SettingsRow(
                        title: l10n.torRelaysTitle,
                        subtitle: l10n.torRelaysDesc,
                        value: torRelaysTitle(l10n, settings.torRelays),
                        onTap: () => showChoiceSheet<TorRelays>(
                          context: context,
                          title: l10n.torRelaysTitle,
                          selected: settings.torRelays,
                          options: TorRelays.values
                              .map(
                                (v) => PickerOption<TorRelays>(
                                  value: v,
                                  title: torRelaysTitle(l10n, v),
                                ),
                              )
                              .toList(),
                          onSelected: (v) => controller.update(
                            (s) => s.copyWith(torRelays: v),
                          ),
                        ),
                      ),
                  ],
                ),
                if (settings.usesAether)
                  SettingsGroup(
                    header: l10n.aetherOnlySection,
                    children: <Widget>[
                      SettingsRow(
                        title: l10n.protocol,
                        subtitle:
                            settings.dialsThrough &&
                                settings.effectiveProtocol != settings.protocol
                            ? l10n.protocolThroughCarrier(
                                chainedEngineName(l10n, settings),
                              )
                            : protocolDesc(l10n, settings.effectiveProtocol),
                        value: protocolTitle(l10n, settings.effectiveProtocol),
                        onTap: () => showChoiceSheet<CoreProtocol>(
                          context: context,
                          title: l10n.protocol,
                          selected: settings.effectiveProtocol,
                          options: CoreProtocol.values
                              .where(
                                (v) =>
                                    !settings.dialsThrough ||
                                    v == CoreProtocol.masque ||
                                    v == CoreProtocol.mim,
                              )
                              .map(
                                (v) => PickerOption<CoreProtocol>(
                                  value: v,
                                  title: protocolTitle(l10n, v),
                                  subtitle: protocolDesc(l10n, v),
                                ),
                              )
                              .toList(),
                          onSelected: (v) =>
                              controller.update((s) => s.copyWith(protocol: v)),
                        ),
                      ),
                      SettingsRow(
                        title: l10n.transport,
                        value: settings.usesHttp2 ? 'HTTP/2' : 'HTTP/3',
                        enabled: settings.isMasque && !settings.dialsThrough,
                        onTap: () => showChoiceSheet<MasqueTransport>(
                          context: context,
                          title: l10n.transport,
                          selected: settings.transport,
                          options: <PickerOption<MasqueTransport>>[
                            PickerOption(
                              value: MasqueTransport.http3,
                              title: l10n.transportH3,
                              subtitle: l10n.transportH3Desc,
                            ),
                            PickerOption(
                              value: MasqueTransport.http2,
                              title: l10n.transportH2,
                              subtitle: l10n.transportH2Desc,
                            ),
                          ],
                          onSelected: (v) => controller.update(
                            (s) => s.copyWith(transport: v),
                          ),
                        ),
                      ),
                      SettingsRow(
                        title: l10n.scanMode,
                        subtitle: scanDesc(l10n, settings.scanMode),
                        value: scanTitle(l10n, settings.scanMode),
                        onTap: () => showChoiceSheet<ScanMode>(
                          context: context,
                          title: l10n.scanMode,
                          selected: settings.scanMode,
                          options: ScanMode.values
                              .map(
                                (v) => PickerOption<ScanMode>(
                                  value: v,
                                  title: scanTitle(l10n, v),
                                  subtitle: scanDesc(l10n, v),
                                ),
                              )
                              .toList(),
                          onSelected: (v) =>
                              controller.update((s) => s.copyWith(scanMode: v)),
                        ),
                      ),
                      SettingsRow(
                        title: l10n.obfuscation,
                        value: obfuscationTitle(l10n, settings.obfuscation),
                        onTap: () => showChoiceSheet<ObfuscationProfile>(
                          context: context,
                          title: l10n.obfuscation,
                          selected: settings.obfuscation,
                          options: ObfuscationProfile.values
                              .map(
                                (v) => PickerOption<ObfuscationProfile>(
                                  value: v,
                                  title: obfuscationTitle(l10n, v),
                                  subtitle: obfuscationDesc(l10n, v),
                                ),
                              )
                              .toList(),
                          onSelected: (v) => controller.update(
                            (s) => s.copyWith(obfuscation: v),
                          ),
                        ),
                      ),
                      if (settings.usesGool)
                        SettingsRow(
                          title: l10n.wiwSection,
                          subtitle: l10n.wiwSectionDesc,
                          value: settings.wiwPinned
                              ? l10n.wiwManual
                              : l10n.wiwScanned,
                          onTap: () => Navigator.of(context).push(
                            CupertinoPageRoute<void>(
                              builder: (_) => const AdvancedScreen(),
                            ),
                          ),
                        ),
                      SettingsRow(
                        title: l10n.endpoint,
                        subtitle: settings.usesGool
                            ? l10n.endpointIgnoredOnGool
                            : (settings.scannerBypassed
                                  ? l10n.scannerOff
                                  : l10n.endpointManualHint),
                        enabled: !settings.usesGool,
                        value: settings.endpoint.isEmpty
                            ? l10n.endpointAuto
                            : settings.endpoint,
                        onTap: () => showTextEditorSheet(
                          context: context,
                          title: l10n.endpoint,
                          description: l10n.endpointDesc,
                          initial: settings.endpoint,
                          placeholder: '162.159.198.1:443',
                          cancelLabel: l10n.cancel,
                          saveLabel: l10n.save,
                          onSaved: (v) => controller.update(
                            (s) => s.copyWith(endpoint: v.trim()),
                          ),
                        ),
                      ),
                      SettingsRow(
                        title: l10n.exitLocTitle,
                        subtitle: l10n.exitLocDesc,
                        value: settings.exitLoc.isEmpty
                            ? l10n.endpointAuto
                            : settings.exitLoc,
                        onTap: () => showTextEditorSheet(
                          context: context,
                          title: l10n.exitLocTitle,
                          description: l10n.exitLocDesc,
                          initial: settings.exitLoc,
                          placeholder: l10n.exitLocHint,
                          cancelLabel: l10n.cancel,
                          saveLabel: l10n.save,
                          onSaved: (v) => controller.update(
                            (s) => s.copyWith(exitLoc: v.trim()),
                          ),
                        ),
                      ),
                    ],
                  ),
                SettingsGroup(
                  children: <Widget>[
                    SettingsRow(
                      title: l10n.routingMode,
                      subtitle: routingDesc(l10n, settings.routingMode),
                      value: routingTitle(l10n, settings.routingMode),
                      onTap: () => showChoiceSheet<RoutingMode>(
                        context: context,
                        title: l10n.routingMode,
                        selected: settings.routingMode,
                        options: RoutingMode.values
                            .where(
                              (v) =>
                                  !isMobilePlatform ||
                                  v != RoutingMode.systemProxy,
                            )
                            .map(
                              (v) => PickerOption<RoutingMode>(
                                value: v,
                                title: routingTitle(l10n, v),
                                subtitle: routingDesc(l10n, v),
                              ),
                            )
                            .toList(),
                        onSelected: (v) => controller.update(
                          (s) => s.copyWith(routingMode: v),
                        ),
                      ),
                    ),
                    if (Platform.isAndroid)
                      SettingsRow(
                        title: l10n.splitTunnel,
                        subtitle: l10n.splitTunnelDesc,
                        value: settings.splitTunnelActive
                            ? '${splitModeTitle(l10n, settings.splitTunnelMode)}'
                                  ' · ${settings.bypassedApps.length}'
                            : l10n.splitTunnelDisabled,
                        onTap: () => Navigator.of(context).push(
                          CupertinoPageRoute<void>(
                            builder: (_) => const SplitTunnelScreen(),
                          ),
                        ),
                      ),
                  ],
                ),
                SettingsGroup(
                  header: l10n.sectionApp,
                  children: <Widget>[
                    SettingsRow(
                      title: l10n.language,
                      value: prefs.localeCode == 'fa' ? 'فارسی' : 'English',
                      onTap: () => showChoiceSheet<String>(
                        context: context,
                        title: l10n.language,
                        selected: prefs.localeCode,
                        options: const <PickerOption<String>>[
                          PickerOption(value: 'fa', title: 'فارسی'),
                          PickerOption(value: 'en', title: 'English'),
                        ],
                        onSelected: prefsController.setLocale,
                      ),
                    ),
                    SettingsRow(
                      title: l10n.theme,
                      value: switch (prefs.themeMode) {
                        ThemeMode.dark => l10n.themeDark,
                        ThemeMode.light => l10n.themeLight,
                        ThemeMode.system => l10n.themeSystem,
                      },
                      onTap: () => showChoiceSheet<ThemeMode>(
                        context: context,
                        title: l10n.theme,
                        selected: prefs.themeMode,
                        options: <PickerOption<ThemeMode>>[
                          PickerOption(
                            value: ThemeMode.dark,
                            title: l10n.themeDark,
                          ),
                          PickerOption(
                            value: ThemeMode.light,
                            title: l10n.themeLight,
                          ),
                          PickerOption(
                            value: ThemeMode.system,
                            title: l10n.themeSystem,
                          ),
                        ],
                        onSelected: prefsController.setThemeMode,
                      ),
                    ),
                    if (settings.usesAether)
                      SettingsRow(
                        title: l10n.zeroTrust,
                        subtitle: l10n.zeroTrustDesc,
                        value: settings.usesZeroTrust
                            ? settings.teamName
                            : l10n.zeroTrustOff,
                        onTap: () => Navigator.of(context).push(
                          CupertinoPageRoute<void>(
                            builder: (_) => const ZeroTrustScreen(),
                          ),
                        ),
                      ),
                    SettingsRow(
                      title: l10n.sectionAdvanced,
                      subtitle: l10n.advancedDesc,
                      onTap: () => Navigator.of(context).push(
                        CupertinoPageRoute<void>(
                          builder: (_) => const AdvancedScreen(),
                        ),
                      ),
                    ),
                    SettingsRow(
                      title: l10n.resetSettings,
                      subtitle: l10n.resetSettingsDesc,
                      destructive: true,
                      onTap: () async {
                        final confirmed = await showConfirmDialog(
                          context: context,
                          title: l10n.resetConfirmTitle,
                          message: l10n.resetConfirmBody,
                          confirmLabel: l10n.confirm,
                          cancelLabel: l10n.cancel,
                        );
                        if (confirmed) await controller.reset();
                      },
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
