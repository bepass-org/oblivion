import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_theme.dart';
import 'flag_icon.dart';

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
  bool reportReselect = false,
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
                style:
                    AppText.rowTitle(
                      isSelected ? palette.primary : palette.label,
                    ).copyWith(
                      fontSize: 17,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w400,
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

  if (chosen != null && (reportReselect || chosen != selected)) {
    onSelected(chosen);
  }
}

Future<void> showMultiChoiceSheet<T>({
  required BuildContext context,
  required String title,
  required Set<T> selected,
  required List<PickerOption<T>> options,
  required ValueChanged<Set<T>> onSaved,
  String? message,
  String cancelLabel = 'Cancel',
  String saveLabel = 'Save',
}) async {
  final palette = context.palette;
  final chosen = <T>{...selected};

  final saved = await showCupertinoModalPopup<bool>(
    context: context,
    builder: (sheetContext) {
      return StatefulBuilder(
        builder: (_, setSheetState) {
          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(sheetContext).size.height * 0.8,
            ),
            decoration: BoxDecoration(
              color: palette.canvas,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
                    child: Text(title, style: AppText.title(palette.label)),
                  ),
                  if (message != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 6, 18, 0),
                      child: Text(
                        message,
                        style: AppText.caption(palette.labelSecondary),
                      ),
                    ),
                  const SizedBox(height: 12),
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: options.length,
                      separatorBuilder: (_, _) => Padding(
                        padding: const EdgeInsetsDirectional.only(start: 18),
                        child: Container(height: 0.5, color: palette.separator),
                      ),
                      itemBuilder: (_, index) {
                        final option = options[index];
                        final picked = chosen.contains(option.value);

                        return CupertinoButton(
                          padding: EdgeInsets.zero,
                          borderRadius: BorderRadius.zero,
                          onPressed: () => setSheetState(() {
                            if (!chosen.remove(option.value)) {
                              chosen.add(option.value);
                            }
                          }),
                          child: Container(
                            color: palette.card,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 13,
                            ),
                            child: Row(
                              children: <Widget>[
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(
                                        option.title,
                                        style: AppText.rowTitle(
                                          picked
                                              ? palette.primary
                                              : palette.label,
                                        ),
                                      ),
                                      if (option.subtitle != null) ...<Widget>[
                                        const SizedBox(height: 2),
                                        Text(
                                          option.subtitle!,
                                          style: AppText.caption(
                                            palette.labelSecondary,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                if (picked)
                                  Icon(
                                    CupertinoIcons.check_mark,
                                    size: 18,
                                    color: palette.primary,
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: CupertinoButton(
                            color: palette.cardPressed,
                            borderRadius: BorderRadius.circular(10),
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            onPressed: () =>
                                Navigator.of(sheetContext).pop(false),
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
                            onPressed: () =>
                                Navigator.of(sheetContext).pop(true),
                            child: Text(
                              saveLabel,
                              style: AppText.rowTitle(const Color(0xFFFFFFFF)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );

  if (saved ?? false) onSaved(chosen);
}

Future<void> showTextEditorSheet({
  required BuildContext context,
  required String title,
  required String initial,
  required ValueChanged<String> onSaved,
  String? placeholder,
  String? description,
  String? Function(String value)? validator,
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
      String? refusal;

      return StatefulBuilder(
        builder: (_, setSheetState) {
          void attemptSave() {
            final complaint = validator?.call(controller.text);
            if (complaint == null) {
              Navigator.of(sheetContext).pop(true);
              return;
            }
            setSheetState(() => refusal = complaint);
          }

          return Container(
            decoration: BoxDecoration(
              color: palette.canvas,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
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
                      placeholderStyle: AppText.rowTitle(
                        palette.labelSecondary,
                      ),
                      decoration: BoxDecoration(
                        color: palette.card,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: refusal == null
                              ? palette.separator
                              : palette.danger,
                        ),
                      ),
                      onChanged: (_) {
                        if (refusal != null) {
                          setSheetState(() => refusal = null);
                        }
                      },
                      onSubmitted: multiline ? null : (_) => attemptSave(),
                    ),
                    if (refusal != null) ...<Widget>[
                      const SizedBox(height: 8),
                      Text(refusal!, style: AppText.caption(palette.danger)),
                    ],
                    const SizedBox(height: 16),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: CupertinoButton(
                            color: palette.cardPressed,
                            borderRadius: BorderRadius.circular(10),
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            onPressed: () =>
                                Navigator.of(sheetContext).pop(false),
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
                            onPressed: attemptSave,
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
    },
  );

  if (saved ?? false) onSaved(controller.text);
  controller.dispose();
}

Future<void> showNoticeDialog({
  required BuildContext context,
  required String title,
  required String message,
  required String dismissLabel,
}) async {
  await showCupertinoDialog<void>(
    context: context,
    builder: (dialogContext) => CupertinoAlertDialog(
      title: Text(title),
      content: Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Text(message),
      ),
      actions: <Widget>[
        CupertinoDialogAction(
          isDefaultAction: true,
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: Text(dismissLabel),
        ),
      ],
    ),
  );
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

Future<void> showCountrySheet({
  required BuildContext context,
  required String title,
  required String selected,
  required String autoLabel,
  required List<String> countryCodes,
  required ValueChanged<String> onSelected,
}) async {
  final palette = context.palette;

  final chosen = await showCupertinoModalPopup<String>(
    context: context,
    builder: (sheetContext) {
      return Container(
        height: MediaQuery.of(sheetContext).size.height * 0.7,
        decoration: BoxDecoration(
          color: palette.canvas,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 10),
                child: Text(title, style: AppText.title(palette.label)),
              ),
              Expanded(
                child: ListView.separated(
                  itemCount: countryCodes.length + 1,
                  separatorBuilder: (_, _) => Padding(
                    padding: const EdgeInsetsDirectional.only(start: 56),
                    child: Container(height: 0.5, color: palette.separator),
                  ),
                  itemBuilder: (itemContext, index) {
                    final code = index == 0 ? '' : countryCodes[index - 1];
                    final isSelected = code == selected;

                    return CupertinoButton(
                      padding: EdgeInsets.zero,
                      borderRadius: BorderRadius.zero,
                      onPressed: () => Navigator.of(itemContext).pop(code),
                      child: Container(
                        color: palette.card,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 13,
                        ),
                        child: Row(
                          children: <Widget>[
                            SizedBox(
                              width: 26,
                              child: code.isEmpty
                                  ? Icon(
                                      CupertinoIcons.globe,
                                      size: 20,
                                      color: palette.labelSecondary,
                                    )
                                  : FlagIcon(countryCode: code),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                code.isEmpty ? autoLabel : code,
                                style: AppText.rowTitle(
                                  isSelected ? palette.primary : palette.label,
                                ),
                              ),
                            ),
                            if (isSelected)
                              Icon(
                                CupertinoIcons.check_mark,
                                size: 18,
                                color: palette.primary,
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    },
  );

  if (chosen != null) onSelected(chosen);
}
