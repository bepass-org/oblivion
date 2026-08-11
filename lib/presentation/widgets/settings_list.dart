import 'package:flutter/cupertino.dart';

import '../../core/theme/app_theme.dart';

class SettingsGroup extends StatelessWidget {
  const SettingsGroup({super.key, required this.children, this.header});

  final List<Widget> children;
  final String? header;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    final rows = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i != 0) {
        rows.add(
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 16),
            child: Container(height: 1, color: palette.separator),
          ),
        );
      }
      rows.add(children[i]);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (header != null)
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(16, 24, 16, 8),
            child: Text(
              header!,
              style: AppText.caption(palette.primary).copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          )
        else
          const SizedBox(height: 8),
        Container(height: 1, color: palette.separator),
        ...rows,
      ],
    );
  }
}

class SettingsRow extends StatefulWidget {
  const SettingsRow({
    super.key,
    required this.title,
    this.subtitle,
    this.value,
    this.trailing,
    this.onTap,
    this.enabled = true,
    this.destructive = false,
  });

  final String title;
  final String? subtitle;
  final String? value;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool enabled;
  final bool destructive;

  @override
  State<SettingsRow> createState() => _SettingsRowState();
}

class _SettingsRowState extends State<SettingsRow> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final interactive = widget.enabled && widget.onTap != null;

    final titleColor = widget.destructive
        ? palette.danger
        : (widget.enabled ? palette.label : palette.labelSecondary);

    return GestureDetector(
      onTapDown: interactive ? (_) => setState(() => _pressed = true) : null,
      onTapUp: interactive ? (_) => setState(() => _pressed = false) : null,
      onTapCancel: interactive ? () => setState(() => _pressed = false) : null,
      onTap: interactive ? widget.onTap : null,
      behavior: HitTestBehavior.opaque,
      child: Container(
        color: _pressed ? palette.cardPressed : palette.card,
        padding: const EdgeInsetsDirectional.fromSTEB(16, 14, 16, 14),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(widget.title, style: AppText.rowTitle(titleColor)),
                  if (widget.subtitle != null) ...<Widget>[
                    const SizedBox(height: 3),
                    Text(
                      widget.subtitle!,
                      style: AppText.caption(palette.labelSecondary),
                    ),
                  ],
                ],
              ),
            ),
            if (widget.value != null) ...<Widget>[
              const SizedBox(width: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 160),
                child: Text(
                  widget.value!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: AppText.rowValue(
                    widget.enabled ? palette.primary : palette.labelSecondary,
                  ),
                ),
              ),
            ],
            if (widget.trailing != null) ...<Widget>[
              const SizedBox(width: 12),
              widget.trailing!,
            ],
            if (widget.trailing == null && widget.onTap != null) ...<Widget>[
              const SizedBox(width: 8),
              Icon(
                CupertinoIcons.chevron_forward,
                size: 15,
                color: widget.enabled
                    ? palette.labelSecondary
                    : palette.separator,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class AppSwitch extends StatelessWidget {
  const AppSwitch({super.key, required this.value, this.onChanged});

  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return CupertinoSwitch(
      value: value,
      onChanged: onChanged,
      activeTrackColor: palette.primary,
      inactiveTrackColor: palette.track,
    );
  }
}

class StatusDot extends StatelessWidget {
  const StatusDot({super.key, required this.color, this.size = 8});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
}
