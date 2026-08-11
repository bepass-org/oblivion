import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_theme.dart';

class PickerOption<T> {
  const PickerOption({required this.value, required this.title, this.subtitle});

  final T value;
  final String title;
  final String? subtitle;
}

Future<void> showChoiceSheet<T>({
  required BuildContext context,
  required String title,
  required T selected,
  required List<PickerOption<T>> options,
  required ValueChanged<T> onSelected,
  String? message,
}) async {
  final palette = context.palette;

  final chosen = await showCupertinoModalPopup<T>(
    context: context,
    builder: (sheetContext) => CupertinoActionSheet(
      title: Text(title, style: AppText.rowTitle(palette.label)),
      message: message == null
          ? null
          : Text(message, style: AppText.caption(palette.labelSecondary)),
      actions: options.map((option) {
        final isSelected = option.value == selected;
        return CupertinoActionSheetAction(
          onPressed: () => Navigator.of(sheetContext).pop(option.value),
          child: Column(
            children: <Widget>[
              Text(
                option.title,
                textAlign: TextAlign.center,
                style: AppText.rowTitle(
                  isSelected ? palette.primary : palette.label,
                ).copyWith(
                  fontSize: 17,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
              if (option.subtitle != null) ...<Widget>[
                const SizedBox(height: 2),
                Text(
                  option.subtitle!,
                  textAlign: TextAlign.center,
                  style: AppText.caption(palette.labelSecondary),
                ),
              ],
            ],
          ),
        );
      }).toList(),
      cancelButton: CupertinoActionSheetAction(
        isDefaultAction: true,
        onPressed: () => Navigator.of(sheetContext).pop(),
        child: Text(
          CupertinoLocalizations.of(context).modalBarrierDismissLabel,
        ),
      ),
    ),
  );

  if (chosen != null && chosen != selected) onSelected(chosen);
}

Future<void> showTextEditorSheet({
  required BuildContext context,
  required String title,
  required String initial,
  required ValueChanged<String> onSaved,
  String? placeholder,
  String? description,
  bool digitsOnly = false,
  bool multiline = false,
  String cancelLabel = 'Cancel',
  String saveLabel = 'Save',
}) async {
  final palette = context.palette;
  final controller = TextEditingController(text: initial);

  final saved = await showCupertinoModalPopup<bool>(
    context: context,
    builder: (sheetContext) {
      return Container(
        decoration: BoxDecoration(
          color: palette.canvas,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.only(
              left: 18,
              right: 18,
              top: 18,
              bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 18,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(title, style: AppText.title(palette.label)),
                if (description != null) ...<Widget>[
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: AppText.caption(palette.labelSecondary),
                  ),
                ],
                const SizedBox(height: 16),
                CupertinoTextField(
                  controller: controller,
                  autofocus: true,
                  placeholder: placeholder,
                  textDirection: TextDirection.ltr,
                  minLines: multiline ? 4 : 1,
                  maxLines: multiline ? 8 : 1,
                  keyboardType: digitsOnly
                      ? TextInputType.number
                      : (multiline
                          ? TextInputType.multiline
                          : TextInputType.text),
                  inputFormatters: digitsOnly
                      ? <TextInputFormatter>[
                          FilteringTextInputFormatter.digitsOnly,
                        ]
                      : null,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 13,
                  ),
                  style: AppText.rowTitle(palette.label),
                  placeholderStyle: AppText.rowTitle(palette.labelSecondary),
                  decoration: BoxDecoration(
                    color: palette.card,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: palette.separator),
                  ),
                  onSubmitted:
                      multiline ? null : (_) => Navigator.of(sheetContext).pop(true),
                ),
                const SizedBox(height: 16),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: CupertinoButton(
                        color: palette.cardPressed,
                        borderRadius: BorderRadius.circular(10),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        onPressed: () => Navigator.of(sheetContext).pop(false),
                        child: Text(
                          cancelLabel,
                          style: AppText.rowTitle(palette.label),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: CupertinoButton(
                        color: palette.primary,
                        borderRadius: BorderRadius.circular(10),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        onPressed: () => Navigator.of(sheetContext).pop(true),
                        child: Text(
                          saveLabel,
                          style: AppText.rowTitle(const Color(0xFFFFFFFF)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );

  if (saved ?? false) onSaved(controller.text);
  controller.dispose();
}

Future<bool> showConfirmDialog({
  required BuildContext context,
  required String title,
  required String message,
  required String confirmLabel,
  required String cancelLabel,
  bool destructive = true,
}) async {
  final result = await showCupertinoDialog<bool>(
    context: context,
    builder: (dialogContext) => CupertinoAlertDialog(
      title: Text(title),
      content: Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Text(message),
      ),
      actions: <Widget>[
        CupertinoDialogAction(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(cancelLabel),
        ),
        CupertinoDialogAction(
          isDestructiveAction: destructive,
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}
