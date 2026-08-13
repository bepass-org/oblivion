import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../l10n/generated/app_localizations.dart';
import '../providers/app_providers.dart';
import '../providers/tunnel_providers.dart';
import '../widgets/screen_header.dart';

class LogsScreen extends ConsumerStatefulWidget {
  const LogsScreen({super.key});

  @override
  ConsumerState<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends ConsumerState<LogsScreen> {
  static const int _maxLines = 600;

  final List<String> _lines = <String>[];
  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadRetained();
  }

  Future<void> _loadRetained() async {
    final retained = await ref.read(tunnelChannelProvider).readLogs();
    if (!mounted || retained.trim().isEmpty) return;

    setState(() {
      for (final line in retained.split('\n')) {
        _append(line);
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _append(String line) {
    final trimmed = line.trimRight();
    if (trimmed.isEmpty) return;

    _lines.add(trimmed);
    if (_lines.length > _maxLines) {
      _lines.removeRange(0, _lines.length - _maxLines);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.jumpTo(_scroll.position.maxScrollExtent);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final palette = context.palette;

    ref.listen<AsyncValue<String>>(tunnelLogsProvider, (previous, next) {
      final line = next.valueOrNull;
      if (line == null) return;
      setState(() => _append(line));
    });

    final body = _lines.isEmpty
        ? Center(
            child: Text(
              l10n.logsEmpty,
              style: AppText.caption(palette.labelSecondary),
            ),
          )
        : SingleChildScrollView(
            controller: _scroll,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(
              _lines.join('\n'),
              textDirection: TextDirection.ltr,
              style: AppText.mono(palette.label),
            ),
          );

    return CupertinoPageScaffold(
      backgroundColor: palette.canvas,
      child: SafeArea(
        child: Column(
          children: <Widget>[
            ScreenHeader(
              title: l10n.logs,
              action: _lines.isEmpty
                  ? null
                  : IconButtonPlain(
                      icon: CupertinoIcons.trash,
                      onTap: () => setState(_lines.clear),
                    ),
            ),
            Expanded(child: body),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: SizedBox(
                width: double.infinity,
                child: CupertinoButton(
                  color: palette.primary,
                  borderRadius: BorderRadius.circular(10),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  onPressed: _lines.isEmpty
                      ? null
                      : () async {
                          await Clipboard.setData(
                            ClipboardData(text: _lines.join('\n')),
                          );
                          if (!context.mounted) return;
                          _toast(context, l10n.logsCopied);
                        },
                  child: Text(
                    l10n.copyLogs,
                    style: AppText.rowTitle(const Color(0xFFFFFFFF)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _toast(BuildContext context, String message) {
    showCupertinoDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        Future<void>.delayed(const Duration(milliseconds: 900), () {
          if (dialogContext.mounted) Navigator.of(dialogContext).pop();
        });
        return CupertinoAlertDialog(content: Text(message));
      },
    );
  }
}
