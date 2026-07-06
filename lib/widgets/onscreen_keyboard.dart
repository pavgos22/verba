import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

enum KeyboardLayoutType { russian, polish }

const _russianRows = [
  [
    ('a', 'а'),
    ('b', 'б'),
    ('v', 'в'),
    ('g', 'г'),
    ('d', 'д'),
    ('e', 'е'),
    ('e=', 'ё'),
    ('zh', 'ж'),
    ('z', 'з'),
    ('i', 'и'),
    ('j', 'й'),
    ('k', 'к'),
    ('l', 'л'),
    ('m', 'м'),
    ('n', 'н'),
    ('o', 'о'),
  ],
  [
    ('p', 'п'),
    ('r', 'р'),
    ('s', 'с'),
    ('t', 'т'),
    ('u', 'у'),
    ('f', 'ф'),
    ('h', 'х'),
    ('c', 'ц'),
    ('ch', 'ч'),
    ('sh', 'ш'),
    ('w', 'щ'),
    ("''", 'ъ'),
    ('y', 'ы'),
    ("'", 'ь'),
    ('e==', 'э'),
    ('ju', 'ю'),
    ('ja', 'я'),
  ],
];

const _polishRows = [
  ['q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p'],
  ['a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l'],
  ['z', 'x', 'c', 'v', 'b', 'n', 'm'],
  ['ą', 'ć', 'ę', 'ł', 'ń', 'ó', 'ś', 'ź', 'ż'],
];

void insertIntoController(TextEditingController controller, String text) {
  final value = controller.value;
  final selection = value.selection.isValid
      ? value.selection
      : TextSelection.collapsed(offset: value.text.length);
  final newText = value.text.replaceRange(selection.start, selection.end, text);
  controller.value = TextEditingValue(
    text: newText,
    selection: TextSelection.collapsed(offset: selection.start + text.length),
  );
}

void backspaceInController(TextEditingController controller) {
  final value = controller.value;
  final selection = value.selection.isValid
      ? value.selection
      : TextSelection.collapsed(offset: value.text.length);
  if (!selection.isCollapsed) {
    final newText = value.text.replaceRange(selection.start, selection.end, '');
    controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: selection.start),
    );
    return;
  }
  if (selection.start == 0) return;
  final newText = value.text.replaceRange(selection.start - 1, selection.start, '');
  controller.value = TextEditingValue(
    text: newText,
    selection: TextSelection.collapsed(offset: selection.start - 1),
  );
}

class OnScreenKeyboard extends StatelessWidget {
  const OnScreenKeyboard({
    super.key,
    required this.layout,
    required this.onText,
    required this.onBackspace,
  });

  final KeyboardLayoutType layout;
  final ValueChanged<String> onText;
  final VoidCallback onBackspace;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    if (layout == KeyboardLayoutType.russian) {
      for (final row in _russianRows) {
        rows.add(Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final (hint, letter) in row)
              _KeyCap(hint: hint, label: letter, onTap: () => onText(letter)),
          ],
        ));
      }
    } else {
      for (final row in _polishRows) {
        rows.add(Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final letter in row) _KeyCap(label: letter, onTap: () => onText(letter)),
          ],
        ));
      }
    }
    rows.add(Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _KeyCap(label: 'spacja', width: 380, small: true, onTap: () => onText(' ')),
        _KeyCap(icon: Icons.backspace_outlined, width: 80, onTap: onBackspace),
      ],
    ));
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final row in rows)
            Padding(padding: const EdgeInsets.only(bottom: 6), child: row),
        ],
      ),
    );
  }
}

class _KeyCap extends StatelessWidget {
  const _KeyCap({
    this.hint,
    this.label,
    this.icon,
    this.width = 50,
    this.small = false,
    required this.onTap,
  });

  final String? hint;
  final String? label;
  final IconData? icon;
  final double width;
  final bool small;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 5),
      child: SizedBox(
        width: width,
        height: 52,
        child: Material(
          color: context.c.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
            side: BorderSide(color: context.c.border),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: onTap,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (hint != null)
                  Text(hint!, style: TextStyle(fontSize: 10, color: context.c.mutedForeground)),
                if (label != null)
                  Text(
                    label!,
                    style: TextStyle(
                      fontSize: small ? 12 : 16,
                      fontWeight: small ? FontWeight.w400 : FontWeight.w500,
                      color: small ? context.c.mutedForeground : context.c.foreground,
                    ),
                  ),
                if (icon != null) Icon(icon, size: 18, color: context.c.mutedForeground),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
