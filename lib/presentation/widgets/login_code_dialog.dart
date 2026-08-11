import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/generated/app_localizations.dart';
import '../providers/tunnel_providers.dart';

bool _dialogOpen = false;

Future<void> showLoginCodeDialog(BuildContext context) async {
  if (_dialogOpen) return;
  _dialogOpen = true;
  try {
    await showCupertinoDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _LoginCodeDialog(),
    );
  } finally {
    _dialogOpen = false;
  }
}

class _LoginCodeDialog extends ConsumerStatefulWidget {
  const _LoginCodeDialog();

  @override
  ConsumerState<_LoginCodeDialog> createState() => _LoginCodeDialogState();
}

class _LoginCodeDialogState extends ConsumerState<_LoginCodeDialog> {
  final TextEditingController _controller = TextEditingController();
  bool _sending = false;
  String? _error;
  int _seenAttempt = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final code = _controller.text.trim();
    if (code.isEmpty || _sending) return;

    setState(() {
      _sending = true;
      _error = null;
    });

    final reached = await ref.read(loginCodeProvider.notifier).submit(code);
    if (!mounted) return;

    if (reached) {
      setState(() => _sending = false);
      return;
    }

    setState(() {
      _sending = false;
      _error = L10n.of(context).zeroTrustCodeLost;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final request = ref.watch(loginCodeProvider);

    if (request == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).maybePop();
      });
    } else if (request.attempt != _seenAttempt) {
      _seenAttempt = request.attempt;
      _controller.clear();
      _sending = false;
      _error = null;
    }

    final body = switch (request) {
      null => l10n.zeroTrustCodeTitle,
      LoginCodeRequest(isRetry: true) => l10n.zeroTrustCodeRetry,
      LoginCodeRequest(email: final email) => l10n.zeroTrustCodeBody(email),
    };

    return CupertinoAlertDialog(
      title: Text(l10n.zeroTrustCodeTitle),
      content: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Column(
          children: <Widget>[
            Text(body, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            CupertinoTextField(
              controller: _controller,
              autofocus: true,
              enabled: !_sending,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              placeholder: l10n.zeroTrustCodePlaceholder,
              onSubmitted: (_) => _send(),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    color: CupertinoColors.systemRed,
                  ),
                ),
              ),
          ],
        ),
      ),
      actions: <Widget>[
        CupertinoDialogAction(
          onPressed: _sending
              ? null
              : () {
                  ref.read(loginCodeProvider.notifier).dismiss();
                  Navigator.of(context).pop();
                },
          isDestructiveAction: true,
          child: Text(l10n.cancel),
        ),
        CupertinoDialogAction(
          onPressed: _sending ? null : _send,
          isDefaultAction: true,
          child: Text(l10n.zeroTrustCodeSend),
        ),
      ],
    );
  }
}
