import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/tunnel_settings.dart';
import '../../data/services/core_jobs.dart';
import '../../l10n/generated/app_localizations.dart';
import '../providers/app_providers.dart';
import '../providers/tunnel_providers.dart';
import '../widgets/core_job_sheet.dart';
import '../widgets/developer_note.dart';
import '../widgets/pickers.dart';
import '../widgets/screen_header.dart';
import '../widgets/settings_list.dart';
import 'advanced_screen.dart';
import 'psiphon_screen.dart';
import 'split_tunnel_screen.dart';
import 'zero_trust_screen.dart';

String carrierTitle(L10n l10n, CarrierMode value, {required bool tor}) =>
    switch (value) {
      CarrierMode.off => l10n.placeOff,
      CarrierMode.chain => tor ? l10n.placeTorChain : l10n.placePsiphonChain,
      CarrierMode.reverse =>
        tor ? l10n.placeTorReverse : l10n.placePsiphonReverse,
      CarrierMode.only => tor ? l10n.placeTorOnly : l10n.placePsiphonOnly,
    };

String carrierDesc(L10n l10n, CarrierMode value, {required bool tor}) =>
    switch (value) {
      CarrierMode.off => tor ? l10n.placeTorOffDesc : l10n.placePsiphonOffDesc,
      CarrierMode.chain => tor ? l10n.coreTorChainDesc : l10n.coreChainDesc,
      CarrierMode.reverse =>
        tor ? l10n.coreTorReverseDesc : l10n.corePsiphonReverseDesc,
      CarrierMode.only => tor ? l10n.coreTorDesc : l10n.corePsiphonDesc,
    };

String reverseCarrierName(L10n l10n, TunnelSettings settings) =>
    settings.torReverse ? l10n.coreTor : l10n.corePsiphon;

Future<void> pickCarrier({
  required BuildContext context,
  required L10n l10n,
  required TunnelSettingsController controller,
  required TunnelSettings settings,
  required bool tor,
}) {
  final other = tor ? settings.psiphon : settings.tor;
  final otherName = tor ? l10n.corePsiphon : l10n.coreTor;

  return showChoiceSheet<CarrierMode>(
    context: context,
    title: tor ? l10n.coreTor : l10n.corePsiphon,
    selected: tor ? settings.tor : settings.psiphon,
    options: CarrierMode.values.map((value) {
      final fits = tor
          ? TunnelSettings.carriersFit(other, value)
          : TunnelSettings.carriersFit(value, other);
      final desc = carrierDesc(l10n, value, tor: tor);
      return PickerOption<CarrierMode>(
        value: value,
        title: carrierTitle(l10n, value, tor: tor),
        subtitle: fits ? desc : '$desc\n${l10n.placeTurnsOff(otherName)}',
      );
    }).toList(),
    onSelected: (value) =>
        controller.update((s) => tor ? s.withTor(value) : s.withPsiphon(value)),
  );
}

String ipTitle(L10n l10n, IpVersion value) => switch (value) {
  IpVersion.v4 => l10n.ipV4,
  IpVersion.v6 => l10n.ipV6,
  IpVersion.dual => l10n.ipDual,
};

String ipDesc(L10n l10n, IpVersion value) => switch (value) {
  IpVersion.v4 => l10n.ipV4Desc,
  IpVersion.v6 => l10n.ipV6Desc,
  IpVersion.dual => l10n.ipDualDesc,
};

Future<void> editWiwHop({
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
    validator: (raw) {
      final value = raw.trim();
      if (value.isEmpty) return null;
      if (!TunnelSettings.isValidEndpoint(value)) {
        return l10n.wiwInvalidEndpoint;
      }
      final next = outer
          ? settings.copyWith(wiwOuter: value)
          : settings.copyWith(wiwInner: value);
      return next.wiwHopsCollide ? l10n.wiwSameEdge : null;
    },
    onSaved: (raw) => controller.update(
      (s) => outer
          ? s.copyWith(wiwOuter: raw.trim())
          : s.copyWith(wiwInner: raw.trim()),
    ),
  );
}

List<Widget> endpointRows({
  required BuildContext context,
  required L10n l10n,
  required TunnelSettingsController controller,
  required TunnelSettings settings,
}) {
  if (settings.usesGoolClassic) {
    return <Widget>[
      for (final outer in <bool>[true, false])
        SettingsRow(
          title: outer ? l10n.wiwOuter : l10n.wiwInner,
          subtitle: outer ? l10n.wiwOuterDesc : l10n.wiwInnerDesc,
          value: switch (outer
              ? settings.wiwOuterPeer
              : settings.wiwInnerPeer) {
            '' => l10n.wiwScanned,
            final hop => hop,
          },
          onTap: () => editWiwHop(
            context: context,
            l10n: l10n,
            controller: controller,
            settings: settings,
            outer: outer,
          ),
        ),
    ];
  }

  final endpointTitle = settings.usesMim
      ? l10n.wiwOuter
      : settings.usesGool
      ? l10n.masqueServer
      : l10n.endpoint;

  return <Widget>[
    SettingsRow(
      title: endpointTitle,
      subtitle: settings.scannerBypassed
          ? l10n.scannerOff
          : l10n.endpointManualHint,
      value: settings.endpoint.isEmpty ? l10n.endpointAuto : settings.endpoint,
      onTap: () => showTextEditorSheet(
        context: context,
        title: endpointTitle,
        description: l10n.endpointDesc,
        initial: settings.endpoint,
        placeholder: '162.159.198.1:443',
        cancelLabel: l10n.cancel,
        saveLabel: l10n.save,
        validator: (v) {
          if (v.trim().isEmpty) return null;
          if (!TunnelSettings.isValidEndpoint(v)) {
            return l10n.wiwInvalidEndpoint;
          }
          return settings.usesMim &&
                  settings.copyWith(endpoint: v.trim()).mimHopsCollide
              ? l10n.wiwSameEdge
              : null;
        },
        onSaved: (v) =>
            controller.update((s) => s.copyWith(endpoint: v.trim())),
      ),
    ),
    if (settings.usesMim)
      SettingsRow(
        title: l10n.wiwInner,
        subtitle: l10n.mimInnerDesc,
        value: settings.mimInnerValue.isEmpty
            ? l10n.endpointAuto
            : settings.mimInnerValue,
        onTap: () => showTextEditorSheet(
          context: context,
          title: l10n.wiwInner,
          description: '${l10n.mimInnerDesc}\n\n${l10n.wiwHint}',
          initial: settings.mimInner,
          placeholder: '162.159.198.2:443',
          cancelLabel: l10n.cancel,
          saveLabel: l10n.save,
          validator: (v) {
            if (v.trim().isEmpty) return null;
            if (!TunnelSettings.isValidEndpoint(v)) {
              return l10n.wiwInvalidEndpoint;
            }
            return settings.copyWith(mimInner: v).mimHopsCollide
                ? l10n.wiwSameEdge
                : null;
          },
          onSaved: (v) =>
              controller.update((s) => s.copyWith(mimInner: v.trim())),
        ),
      ),
    if (settings.usesGool)
      SettingsRow(
        title: l10n.goolPeer,
        subtitle: l10n.goolPeerDesc,
        value: settings.goolPeerValue.isEmpty
            ? l10n.endpointAuto
            : settings.goolPeerValue,
        onTap: () => showTextEditorSheet(
          context: context,
          title: l10n.goolPeer,
          description: l10n.goolPeerDesc,
          initial: settings.goolPeer,
          placeholder: '162.159.192.1:2408',
          cancelLabel: l10n.cancel,
          saveLabel: l10n.save,
          validator: (v) =>
              v.trim().isEmpty || TunnelSettings.isValidEndpoint(v)
              ? null
              : l10n.wiwInvalidEndpoint,
          onSaved: (v) =>
              controller.update((s) => s.copyWith(goolPeer: v.trim())),
        ),
      ),
  ];
}

String torRelaysTitle(L10n l10n, TorRelays value) => switch (value) {
  TorRelays.auto => l10n.torRelaysAuto,
  TorRelays.only => l10n.torRelaysOnly,
  TorRelays.off => l10n.torRelaysOff,
};

String torBridgesTitle(L10n l10n, TorBridges value) => switch (value) {
  TorBridges.auto => l10n.torBridgesAuto,
  TorBridges.first => l10n.torBridgesFirst,
  TorBridges.never => l10n.torBridgesNever,
  TorBridges.own => l10n.torBridgesOwn,
};

String protocolTitle(L10n l10n, CoreProtocol value) => switch (value) {
  CoreProtocol.masque => l10n.protocolMasque,
  CoreProtocol.wireguard => l10n.protocolWireGuard,
  CoreProtocol.gool => l10n.protocolGool,
  CoreProtocol.goolClassic => l10n.protocolGoolClassic,
  CoreProtocol.mim => l10n.protocolMim,
};

String protocolShortTitle(L10n l10n, CoreProtocol value) => switch (value) {
  CoreProtocol.gool => l10n.protocolGoolShort,
  CoreProtocol.goolClassic => l10n.protocolGoolClassicShort,
  _ => protocolTitle(l10n, value),
};

String protocolDesc(L10n l10n, CoreProtocol value) => switch (value) {
  CoreProtocol.masque => l10n.protocolMasqueDesc,
  CoreProtocol.wireguard => l10n.protocolWireGuardDesc,
  CoreProtocol.gool => l10n.protocolGoolDesc,
  CoreProtocol.goolClassic => l10n.protocolGoolClassicDesc,
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
  ObfuscationProfile.auto => l10n.obfuscationAuto,
  ObfuscationProfile.off => l10n.obfuscationOff,
  ObfuscationProfile.light => l10n.obfuscationLight,
  ObfuscationProfile.firewall => l10n.obfuscationFirewall,
  ObfuscationProfile.balanced => l10n.obfuscationBalanced,
  ObfuscationProfile.gfw => l10n.obfuscationGfw,
  ObfuscationProfile.aggressive => l10n.obfuscationAggressive,
};

String obfuscationDesc(L10n l10n, ObfuscationProfile value) => switch (value) {
  ObfuscationProfile.auto => l10n.obfuscationAutoDesc,
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

Future<void> pickMasqueServerName({
  required BuildContext context,
  required L10n l10n,
  required TunnelSettingsController controller,
  required TunnelSettings settings,
}) {
  final current = settings.masqueServerName;
  final custom = settings.masqueSniCustom;

  return showChoiceSheet<String>(
    context: context,
    title: l10n.masqueSni,
    message: l10n.masqueSniDesc,
    selected: custom ? '' : current,
    reportReselect: true,
    options: <PickerOption<String>>[
      PickerOption(
        value: TunnelSettings.defaultMasqueSni,
        title: TunnelSettings.defaultMasqueSni,
        subtitle: l10n.masqueSniDefaultDesc,
      ),
      PickerOption(
        value: TunnelSettings.warpMasqueSni,
        title: TunnelSettings.warpMasqueSni,
        subtitle: l10n.masqueSniWarpDesc,
      ),
      PickerOption(
        value: '',
        title: l10n.masqueSniCustom,
        subtitle: custom ? current : l10n.masqueSniCustomDesc,
      ),
    ],
    onSelected: (value) {
      if (value.isNotEmpty) {
        controller.update(
          (s) => s.copyWith(
            masqueSni: value == TunnelSettings.defaultMasqueSni ? '' : value,
          ),
        );
        return;
      }
      showTextEditorSheet(
        context: context,
        title: l10n.masqueSniCustom,
        description: l10n.masqueSniCustomDesc,
        initial: custom ? current : '',
        placeholder: 'www.example.com',
        cancelLabel: l10n.cancel,
        saveLabel: l10n.save,
        validator: (v) =>
            TunnelSettings.isServerName(v) ? null : l10n.serverNameRefusal,
        onSaved: (v) =>
            controller.update((s) => s.copyWith(masqueSni: v.trim())),
      );
    },
  );
}

bool isIpAddress(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return false;
  return InternetAddress.tryParse(trimmed) != null;
}

String keyKindTitle(L10n l10n, WarpKeyKind value) => switch (value) {
  WarpKeyKind.all => l10n.keyKindAll,
  WarpKeyKind.masque => l10n.protocolMasque,
  WarpKeyKind.wireguard => l10n.protocolWireGuard,
  WarpKeyKind.gool => l10n.protocolGool,
  WarpKeyKind.goolClassic => l10n.protocolGoolClassic,
  WarpKeyKind.mim => l10n.protocolMim,
};

Future<void> findGateway(BuildContext context, WidgetRef ref, L10n l10n) async {
  final settings = ref.read(tunnelSettingsProvider);
  final jobs = ref.read(coreJobsProvider);
  final result = await showCoreJobSheet<GatewayScan>(
    context: context,
    title: l10n.findGateway,
    message: l10n.findGatewayRunning,
    cancelLabel: l10n.cancel,
    start: (onLine, cancel) =>
        jobs.findGateway(settings, onLine: onLine, cancel: cancel),
  );
  if (result == null || result.cancelled) return;

  final found = result.value;
  if (found != null) {
    await ref
        .read(tunnelSettingsProvider.notifier)
        .update((s) => s.withFoundGateway(found));
  }
  if (!context.mounted) return;
  await showNoticeDialog(
    context: context,
    title: l10n.findGateway,
    message: found != null
        ? l10n.gatewayFound(found.toString())
        : l10n.gatewayNotFound(readableCoreLine(result.problem ?? '')),
    dismissLabel: l10n.confirm,
  );
}

Future<void> renewKeys(BuildContext context, WidgetRef ref, L10n l10n) async {
  final settings = ref.read(tunnelSettingsProvider);
  WarpKeyKind? chosen;
  await showChoiceSheet<WarpKeyKind>(
    context: context,
    title: l10n.renewKeys,
    message: l10n.renewKeysWhich,
    selected: WarpKeyKind.of(settings.effectiveProtocol),
    reportReselect: true,
    options: WarpKeyKind.values
        .map(
          (value) => PickerOption<WarpKeyKind>(
            value: value,
            title: keyKindTitle(l10n, value),
          ),
        )
        .toList(),
    onSelected: (value) => chosen = value,
  );
  final kind = chosen;
  if (kind == null || !context.mounted) return;

  final jobs = ref.read(coreJobsProvider);
  final result = await showCoreJobSheet<List<String>>(
    context: context,
    title: l10n.renewKeys,
    message: l10n.renewKeysRunning,
    cancelLabel: l10n.cancel,
    start: (onLine, cancel) =>
        jobs.renewKeys(settings, kind, onLine: onLine, cancel: cancel),
  );
  if (result == null || result.cancelled || !context.mounted) return;
  await showNoticeDialog(
    context: context,
    title: l10n.renewKeys,
    message: result.succeeded
        ? l10n.keysRenewed
        : l10n.keysNotRenewed(readableCoreLine(result.problem ?? '')),
    dismissLabel: l10n.confirm,
  );
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
    final tunnelIdle = ref.watch(tunnelProvider).stage.isIdle;

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
                if (settings.usesAether)
                  SettingsGroup(
                    header: l10n.sectionWarp,
                    children: <Widget>[
                      SettingsRow(
                        title: l10n.protocol,
                        subtitle: settings.protocolRunsAsMasque
                            ? l10n.protocolRunsAsMasque(
                                reverseCarrierName(l10n, settings),
                              )
                            : protocolDesc(l10n, settings.protocol),
                        destructive: settings.protocolRunsAsMasque,
                        value: protocolShortTitle(l10n, settings.protocol),
                        onTap: () => showChoiceSheet<CoreProtocol>(
                          context: context,
                          title: l10n.protocol,
                          selected: settings.protocol,
                          options: CoreProtocol.values
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
                      if (settings.isMasque)
                        SettingsRow(
                          title: l10n.transport,
                          value: settings.usesHttp2 ? 'HTTP/2' : 'HTTP/3',
                          enabled: !settings.dialsThrough,
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
                      if (settings.isMasque)
                        SettingsRow(
                          title: l10n.masqueSni,
                          subtitle: l10n.masqueSniDesc,
                          value: settings.masqueServerName,
                          onTap: () => pickMasqueServerName(
                            context: context,
                            l10n: l10n,
                            controller: controller,
                            settings: settings,
                          ),
                        ),
                      ...endpointRows(
                        context: context,
                        l10n: l10n,
                        controller: controller,
                        settings: settings,
                      ),
                      if (CoreJobs.supported && settings.canFindGateway)
                        SettingsRow(
                          title: l10n.findGateway,
                          subtitle: tunnelIdle
                              ? l10n.findGatewayDesc
                              : l10n.jobsNeedDisconnect,
                          enabled: tunnelIdle,
                          onTap: tunnelIdle
                              ? () => findGateway(context, ref, l10n)
                              : null,
                        ),
                      SettingsRow(
                        title: l10n.ipVersion,
                        subtitle: ipDesc(l10n, settings.ipVersion),
                        value: ipTitle(l10n, settings.ipVersion),
                        onTap: () => showChoiceSheet<IpVersion>(
                          context: context,
                          title: l10n.ipVersion,
                          selected: settings.ipVersion,
                          options: IpVersion.values
                              .map(
                                (v) => PickerOption<IpVersion>(
                                  value: v,
                                  title: ipTitle(l10n, v),
                                  subtitle: ipDesc(l10n, v),
                                ),
                              )
                              .toList(),
                          onSelected: (v) => controller.update(
                            (s) => s.copyWith(ipVersion: v),
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
                          validator: (v) => TunnelSettings.isExitRule(v)
                              ? null
                              : l10n.exitLocRefusal,
                          onSaved: (v) => controller.update(
                            (s) => s.copyWith(
                              exitLoc: TunnelSettings.normalizeExitRule(v),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                SettingsGroup(
                  children: <Widget>[
                    SettingsRow(
                      title: l10n.corePsiphon,
                      subtitle: carrierDesc(l10n, settings.psiphon, tor: false),
                      value: carrierTitle(l10n, settings.psiphon, tor: false),
                      onTap: () => pickCarrier(
                        context: context,
                        l10n: l10n,
                        controller: controller,
                        settings: settings,
                        tor: false,
                      ),
                    ),
                    if (settings.usesPsiphon)
                      SettingsRow(
                        title: l10n.psiphonDetails,
                        subtitle: psiphonModeDesc(l10n, settings.psiphonMode),
                        value: psiphonModeTitle(l10n, settings.psiphonMode),
                        onTap: () => Navigator.of(context).push(
                          CupertinoPageRoute<void>(
                            builder: (_) => const PsiphonScreen(),
                          ),
                        ),
                      ),
                  ],
                ),
                SettingsGroup(
                  children: <Widget>[
                    SettingsRow(
                      title: l10n.coreTor,
                      subtitle: carrierDesc(l10n, settings.tor, tor: true),
                      value: carrierTitle(l10n, settings.tor, tor: true),
                      onTap: () => pickCarrier(
                        context: context,
                        l10n: l10n,
                        controller: controller,
                        settings: settings,
                        tor: true,
                      ),
                    ),
                    if (settings.usesTor)
                      SettingsRow(
                        title: l10n.torBridges,
                        subtitle: l10n.torBridgesDesc,
                        value: torBridgesTitle(l10n, settings.torBridges),
                        onTap: () => showChoiceSheet<TorBridges>(
                          context: context,
                          title: l10n.torBridges,
                          selected: settings.torBridges,
                          options: TorBridges.values
                              .map(
                                (v) => PickerOption<TorBridges>(
                                  value: v,
                                  title: torBridgesTitle(l10n, v),
                                ),
                              )
                              .toList(),
                          onSelected: (v) => controller.update(
                            (s) => s.copyWith(torBridges: v),
                          ),
                        ),
                      ),
                    if (settings.usesTor &&
                        (settings.torBridges == TorBridges.auto ||
                            settings.torBridges == TorBridges.first))
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
                    if (settings.usesTor &&
                        settings.torBridges == TorBridges.own)
                      SettingsRow(
                        title: l10n.torBridgeLines,
                        subtitle: settings.torBridgesMissing
                            ? l10n.torBridgeLinesRefusal
                            : null,
                        destructive: settings.torBridgesMissing,
                        value: '${settings.torBridgeLineList.length}',
                        onTap: () => showTextEditorSheet(
                          context: context,
                          title: l10n.torBridgeLines,
                          description: l10n.torBridgeLinesDesc,
                          initial: settings.torBridgeLines,
                          placeholder:
                              'obfs4 1.2.3.4:443 FINGERPRINT cert=... iat-mode=0',
                          multiline: true,
                          cancelLabel: l10n.cancel,
                          saveLabel: l10n.save,
                          validator: (v) =>
                              TunnelSettings.bridgeLines(v).isEmpty
                              ? l10n.torBridgeLinesRefusal
                              : null,
                          onSaved: (v) => controller.update(
                            (s) => s.copyWith(torBridgeLines: v.trim()),
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
                    if (CoreJobs.supported &&
                        settings.usesAether &&
                        settings.canRenewKeys)
                      SettingsRow(
                        title: l10n.renewKeys,
                        subtitle: tunnelIdle
                            ? l10n.renewKeysDesc
                            : l10n.jobsNeedDisconnect,
                        enabled: tunnelIdle,
                        onTap: tunnelIdle
                            ? () => renewKeys(context, ref, l10n)
                            : null,
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
