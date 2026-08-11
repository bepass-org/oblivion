import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/tunnel_status.dart';

class ConnectSwitch extends StatelessWidget {
  const ConnectSwitch({
    super.key,
    required this.stage,
    required this.onConnect,
    required this.onDisconnect,
  });

  final TunnelStage stage;
  final VoidCallback onConnect;
  final VoidCallback onDisconnect;

  static const double _width = 160;
  static const double _height = 74;
  static const double _border = 3;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    final on = stage.isActive || stage.isBusy;
    final knob = _height - _border * 2;

    final trackColor = switch (stage) {
      TunnelStage.failed => palette.danger,
      _ => on ? palette.primary : palette.track,
    };

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.mediumImpact();
        if (stage.isActive || stage.isBusy) {
          onDisconnect();
        } else {
          onConnect();
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
        width: _width,
        height: _height,
        padding: const EdgeInsets.all(_border),
        decoration: BoxDecoration(
          color: trackColor,
          borderRadius: BorderRadius.circular(_height / 2),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOut,
          alignment: on ? Alignment.centerRight : Alignment.centerLeft,
          child: SizedBox(
            width: knob,
            height: knob,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: palette.card,
                shape: BoxShape.circle,
              ),
              child: stage.isBusy
                  ? const Center(child: CupertinoActivityIndicator(radius: 11))
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}
