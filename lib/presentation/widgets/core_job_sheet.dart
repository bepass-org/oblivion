import 'dart:async';

import 'package:flutter/cupertino.dart';

import '../../core/theme/app_theme.dart';
import '../../data/services/core_jobs.dart';

typedef CoreJobStart<T extends Object> =
    Future<CoreJobResult<T>> Function(
      ValueChanged<String> onLine,
      CoreJobCancel cancel,
    );

Future<CoreJobResult<T>?> showCoreJobSheet<T extends Object>({
  required BuildContext context,
  required String title,
  required String message,
  required String cancelLabel,
  required CoreJobStart<T> start,
}) {
  return showCupertinoModalPopup<CoreJobResult<T>>(
    context: context,
    barrierDismissible: false,
    builder: (_) => CoreJobSheet<T>(
      title: title,
      message: message,
      cancelLabel: cancelLabel,
      start: start,
    ),
  );
}

String readableCoreLine(String line) =>
    line.replaceFirst(RegExp(r'^(\[[^\]]*\]\s*)+'), '').trim();

class CoreJobSheet<T extends Object> extends StatefulWidget {
  const CoreJobSheet({
    super.key,
    required this.title,
    required this.message,
    required this.cancelLabel,
    required this.start,
  });

  final String title;
  final String message;
  final String cancelLabel;
  final CoreJobStart<T> start;

  @override
  State<CoreJobSheet<T>> createState() => _CoreJobSheetState<T>();
}

class _CoreJobSheetState<T extends Object> extends State<CoreJobSheet<T>> {
  final CoreJobCancel _cancel = CoreJobCancel();
  String _latest = '';

  @override
  void initState() {
    super.initState();
    unawaited(_run());
  }

  Future<void> _run() async {
    final result = await widget.start(_onLine, _cancel);
    if (!mounted) return;
    Navigator.of(context).pop(result);
  }

  void _onLine(String line) {
    final readable = readableCoreLine(line);
    if (!mounted || readable.isEmpty) return;
    setState(() => _latest = readable);
  }

  @override
  void dispose() {
    _cancel.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return PopScope(
      canPop: false,
      child: Container(
        decoration: BoxDecoration(
          color: palette.canvas,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(widget.title, style: AppText.title(palette.label)),
                const SizedBox(height: 6),
                Text(
                  widget.message,
                  style: AppText.caption(palette.labelSecondary),
                ),
                const SizedBox(height: 18),
                const CupertinoActivityIndicator(radius: 12),
                const SizedBox(height: 14),
                SizedBox(
                  height: 54,
                  child: Text(
                    _latest,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.ltr,
                    style: AppText.mono(palette.labelSecondary),
                  ),
                ),
                const SizedBox(height: 12),
                CupertinoButton(
                  color: palette.cardPressed,
                  borderRadius: BorderRadius.circular(10),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  onPressed: _cancel.isCancelled ? null : _stop,
                  child: Text(
                    widget.cancelLabel,
                    style: AppText.rowTitle(palette.danger),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _stop() {
    setState(_cancel.cancel);
  }
}
