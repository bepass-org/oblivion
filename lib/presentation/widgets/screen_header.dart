import 'package:flutter/cupertino.dart';

import '../../core/theme/app_theme.dart';

class ScreenHeader extends StatelessWidget {
  const ScreenHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
  });

  final String title;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final canPop = Navigator.of(context).canPop();

    return SizedBox(
      height: 56,
      child: Stack(
        children: <Widget>[
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(title, style: AppText.title(palette.label)),
                if (subtitle != null) ...<Widget>[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: AppText.caption(palette.labelSecondary),
                  ),
                ],
              ],
            ),
          ),
          if (canPop)
            PositionedDirectional(
              start: 4,
              top: 6,
              child: IconButtonPlain(
                icon: CupertinoIcons.back,
                onTap: () => Navigator.of(context).maybePop(),
              ),
            ),
          if (action != null)
            PositionedDirectional(end: 4, top: 6, child: action!),
        ],
      ),
    );
  }
}

class IconButtonPlain extends StatelessWidget {
  const IconButtonPlain({
    super.key,
    required this.icon,
    required this.onTap,
    this.color,
    this.size = 24,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 44,
        height: 44,
        child: Center(
          child: Icon(icon, size: size, color: color ?? palette.label),
        ),
      ),
    );
  }
}
