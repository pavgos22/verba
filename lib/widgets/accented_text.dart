import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/settings_store.dart';

const stressMark = '́';

class AccentedText extends ConsumerWidget {
  const AccentedText(this.text, {super.key, required this.style, this.overflow});

  final String text;
  final TextStyle style;
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showAccents = ref.watch(settingsProvider.select((s) => s.showAccents));
    final stripped = text.replaceAll(stressMark, '');
    if (!showAccents || !text.contains(stressMark)) {
      return Text(stripped, style: style, overflow: overflow);
    }
    final stressIndices = <int>[];
    var strippedCount = 0;
    for (final ch in text.split('')) {
      if (ch == stressMark) {
        if (strippedCount > 0) stressIndices.add(strippedCount - 1);
      } else {
        strippedCount++;
      }
    }
    final painter = TextPainter(
      text: TextSpan(text: stripped, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    final fontSize = style.fontSize ?? 14;
    final topPad = fontSize * 0.24;
    return SizedBox(
      width: painter.width,
      height: painter.height + topPad,
      child: CustomPaint(
        painter: _AccentPainter(
          textPainter: painter,
          stressIndices: stressIndices,
          topPad: topPad,
          fontSize: fontSize,
          color: style.color ?? Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }
}

class _AccentPainter extends CustomPainter {
  _AccentPainter({
    required this.textPainter,
    required this.stressIndices,
    required this.topPad,
    required this.fontSize,
    required this.color,
  });

  final TextPainter textPainter;
  final List<int> stressIndices;
  final double topPad;
  final double fontSize;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    textPainter.paint(canvas, Offset(0, topPad));
    final paint = Paint()
      ..color = color
      ..strokeWidth = fontSize * 0.075
      ..strokeCap = StrokeCap.round;
    for (final index in stressIndices) {
      final left = textPainter.getOffsetForCaret(TextPosition(offset: index), Rect.zero).dx;
      final right = textPainter.getOffsetForCaret(TextPosition(offset: index + 1), Rect.zero).dx;
      final midX = (left + right) / 2;
      canvas.drawLine(
        Offset(midX - fontSize * 0.055, topPad * 0.88),
        Offset(midX + fontSize * 0.055, topPad * 0.16),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_AccentPainter oldDelegate) {
    return oldDelegate.textPainter.text != textPainter.text ||
        oldDelegate.color != color ||
        oldDelegate.fontSize != fontSize ||
        oldDelegate.stressIndices.toString() != stressIndices.toString();
  }
}
