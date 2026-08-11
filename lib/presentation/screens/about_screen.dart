import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/app_info.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/generated/app_localizations.dart';
import '../providers/app_providers.dart';
import '../widgets/screen_header.dart';
import '../widgets/settings_list.dart';

class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  static const String _appRepo = 'https://github.com/bepass-org/oblivion';
  static const String _coreRepo = 'https://github.com/CluvexStudio/Aether';

  Future<void> _open(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = L10n.of(context);
    final palette = context.palette;
    final coreVersion = ref.watch(coreVersionProvider);

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
                ScreenHeader(title: l10n.about),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                  child: Column(
                    children: <Widget>[
                      Text(
                        l10n.appDisplayName,
                        style: AppText.brand(palette.label),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.appTagline,
                        textAlign: TextAlign.center,
                        style: AppText.state(palette.primary),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.aboutBody,
                        textAlign: TextAlign.center,
                        style: AppText.caption(palette.labelSecondary),
                      ),
                    ],
                  ),
                ),
                SettingsGroup(
                  children: <Widget>[
                    SettingsRow(
                      title: l10n.aboutVersion,
                      value: kAppVersion,
                    ),
                    SettingsRow(
                      title: l10n.aboutCore,
                      value: coreVersion.maybeWhen(
                        data: (version) => version,
                        orElse: () => '—',
                      ),
                    ),
                    SettingsRow(
                      title: l10n.aboutApp,
                      value: 'bepass-org/oblivion',
                      trailing: _LinkIcon(),
                      onTap: () => _open(_appRepo),
                    ),
                    SettingsRow(
                      title: l10n.aboutCoreRepo,
                      value: 'CluvexStudio/Aether',
                      trailing: _LinkIcon(),
                      onTap: () => _open(_coreRepo),
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

class _LinkIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Icon(
        CupertinoIcons.arrow_up_right_square,
        size: 17,
        color: context.palette.primary,
      );
}
