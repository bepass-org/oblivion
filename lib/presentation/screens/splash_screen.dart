import 'dart:async';

import 'package:flutter/cupertino.dart';

import '../../core/theme/app_theme.dart';
import '../../l10n/generated/app_localizations.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(seconds: 3), widget.onDone);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final l10n = L10n.of(context);

    return CupertinoPageScaffold(
      backgroundColor: palette.canvas,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onDone,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Stack(
              children: <Widget>[
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 380),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 96),
                          child: Image.asset(
                            'assets/images/segaro.png',
                            width: double.infinity,
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          l10n.appName.toUpperCase(),
                          textDirection: TextDirection.ltr,
                          style: AppText.wordmark(palette.primary),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          l10n.introMeaning,
                          textAlign: TextAlign.center,
                          style: AppText.state(palette.label),
                        ),
                        const SizedBox(height: 26),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                            ClipOval(
                              child: Image.asset(
                                'assets/images/yousef.png',
                                width: 62,
                                height: 62,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                l10n.introCredit,
                                style: AppText.caption(palette.label),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 22),
                        Container(
                          height: 1,
                          width: 46,
                          color: palette.separator,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.memorialTitle,
                          textAlign: TextAlign.center,
                          style: AppText.rowTitle(palette.label),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          l10n.memorialBody,
                          textAlign: TextAlign.center,
                          style: AppText.caption(palette.labelSecondary),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.memorialVow,
                          textAlign: TextAlign.center,
                          style: AppText.state(palette.primary),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 14,
                  child: Text(
                    l10n.introSlogan,
                    textAlign: TextAlign.center,
                    style: AppText.rowTitle(palette.primary),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
