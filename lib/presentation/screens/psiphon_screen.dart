import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/tunnel_settings.dart';
import '../../l10n/generated/app_localizations.dart';
import '../providers/tunnel_providers.dart';
import '../widgets/flag_icon.dart';
import '../widgets/pickers.dart';
import '../widgets/screen_header.dart';
import '../widgets/settings_list.dart';

String psiphonModeTitle(L10n l10n, PsiphonMode value) => switch (value) {
  PsiphonMode.auto => l10n.psiphonModeAuto,
  PsiphonMode.cdn => l10n.psiphonModeCdn,
  PsiphonMode.conduit => l10n.psiphonModeConduit,
  PsiphonMode.direct => l10n.psiphonModeDirect,
};

String psiphonModeDesc(L10n l10n, PsiphonMode value) => switch (value) {
  PsiphonMode.auto => l10n.psiphonModeAutoDesc,
  PsiphonMode.cdn => l10n.psiphonModeCdnDesc,
  PsiphonMode.conduit => l10n.psiphonModeConduitDesc,
  PsiphonMode.direct => l10n.psiphonModeDirectDesc,
};

String conduitPeersTitle(L10n l10n, ConduitPeers value) => switch (value) {
  ConduitPeers.auto => l10n.psiphonConduitPeersAuto,
  ConduitPeers.private => l10n.psiphonConduitPeersPrivate,
  ConduitPeers.public => l10n.psiphonConduitPeersPublic,
};

String conduitPeersDesc(L10n l10n, ConduitPeers value) => switch (value) {
  ConduitPeers.auto => l10n.psiphonConduitPeersAutoDesc,
  ConduitPeers.private => l10n.psiphonConduitPeersPrivateDesc,
  ConduitPeers.public => l10n.psiphonConduitPeersPublicDesc,
};

class PsiphonScreen extends ConsumerWidget {
  const PsiphonScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = L10n.of(context);
    final palette = context.palette;
    final settings = ref.watch(tunnelSettingsProvider);
    final controller = ref.read(tunnelSettingsProvider.notifier);

    final country = settings.psiphonCountry.trim().toUpperCase();

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
                ScreenHeader(title: l10n.psiphonSettings),
                SettingsGroup(
                  children: <Widget>[
                    SettingsRow(
                      title: l10n.psiphonCountry,
                      subtitle: l10n.psiphonCountryDesc,
                      value: country.isEmpty
                          ? l10n.psiphonCountryAuto
                          : country,
                      trailing: country.isEmpty
                          ? null
                          : FlagIcon(countryCode: country),
                      onTap: () => showCountrySheet(
                        context: context,
                        title: l10n.psiphonCountry,
                        selected: country,
                        autoLabel: l10n.psiphonCountryAuto,
                        countryCodes: psiphonCountries,
                        onSelected: (value) => controller.update(
                          (s) => s.copyWith(psiphonCountry: value),
                        ),
                      ),
                    ),
                    SettingsRow(
                      title: l10n.psiphonMode,
                      subtitle: psiphonModeDesc(l10n, settings.psiphonMode),
                      value: psiphonModeTitle(l10n, settings.psiphonMode),
                      onTap: () => showChoiceSheet<PsiphonMode>(
                        context: context,
                        title: l10n.psiphonMode,
                        selected: settings.psiphonMode,
                        options: PsiphonMode.values
                            .map(
                              (value) => PickerOption<PsiphonMode>(
                                value: value,
                                title: psiphonModeTitle(l10n, value),
                                subtitle: psiphonModeDesc(l10n, value),
                              ),
                            )
                            .toList(),
                        onSelected: (value) => controller.update(
                          (s) => s.copyWith(psiphonMode: value),
                        ),
                      ),
                    ),
                  ],
                ),
                if (settings.psiphonUsesCdnFronting)
                  SettingsGroup(
                    header: l10n.psiphonCdnFronting,
                    children: <Widget>[
                      SettingsRow(
                        title: l10n.psiphonCdnIps,
                        subtitle: l10n.psiphonCdnIpsDesc,
                        value: describeList(settings.psiphonCdnIps),
                        onTap: () => showTextEditorSheet(
                          context: context,
                          title: l10n.psiphonCdnIps,
                          description: l10n.psiphonCdnIpsDesc,
                          initial: settings.psiphonCdnIps,
                          multiline: true,
                          placeholder: '23.215.0.206\n104.16.0.0/13',
                          cancelLabel: l10n.cancel,
                          saveLabel: l10n.save,
                          onSaved: (value) => controller.update(
                            (s) => s.copyWith(psiphonCdnIps: value.trim()),
                          ),
                        ),
                      ),
                      SettingsRow(
                        title: l10n.psiphonCdnSni,
                        subtitle: l10n.psiphonCdnSniDesc,
                        value: describeList(settings.psiphonCdnSni),
                        onTap: () => showTextEditorSheet(
                          context: context,
                          title: l10n.psiphonCdnSni,
                          description: l10n.psiphonCdnSniDesc,
                          initial: settings.psiphonCdnSni,
                          multiline: true,
                          placeholder: 'www.example.com',
                          cancelLabel: l10n.cancel,
                          saveLabel: l10n.save,
                          onSaved: (value) => controller.update(
                            (s) => s.copyWith(psiphonCdnSni: value.trim()),
                          ),
                        ),
                      ),
                    ],
                  ),
                if (settings.psiphonUsesConduit)
                  SettingsGroup(
                    header: l10n.psiphonModeConduit,
                    children: <Widget>[
                      SettingsRow(
                        title: l10n.psiphonConduitPeers,
                        subtitle: conduitPeersDesc(
                          l10n,
                          settings.psiphonConduitPeers,
                        ),
                        value: conduitPeersTitle(
                          l10n,
                          settings.psiphonConduitPeers,
                        ),
                        onTap: () => showChoiceSheet<ConduitPeers>(
                          context: context,
                          title: l10n.psiphonConduitPeers,
                          selected: settings.psiphonConduitPeers,
                          options: ConduitPeers.values
                              .map(
                                (value) => PickerOption<ConduitPeers>(
                                  value: value,
                                  title: conduitPeersTitle(l10n, value),
                                  subtitle: conduitPeersDesc(l10n, value),
                                ),
                              )
                              .toList(),
                          onSelected: (value) => controller.update(
                            (s) => s.copyWith(psiphonConduitPeers: value),
                          ),
                        ),
                      ),
                      SettingsRow(
                        title: l10n.psiphonRejectCensoredPeers,
                        subtitle: l10n.psiphonRejectCensoredPeersDesc,
                        trailing: AppSwitch(
                          value: settings.psiphonRejectCensoredPeers,
                          onChanged: (value) => controller.update(
                            (s) =>
                                s.copyWith(psiphonRejectCensoredPeers: value),
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

String describeList(String raw) {
  final entries = raw
      .split(RegExp(r'[\s,;]+'))
      .map((entry) => entry.trim())
      .where((entry) => entry.isNotEmpty)
      .toList();
  if (entries.isEmpty) return '—';
  if (entries.length == 1) return entries.first;
  return '${entries.first} +${entries.length - 1}';
}
