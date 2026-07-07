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
    final textPainter = TextPainter(
      text: TextSpan(text: stripped, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    final markPainter = TextPainter(
      text: TextSpan(text: '´', style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    return SizedBox(
      width: textPainter.width,
      height: textPainter.height,
      child: CustomPaint(
        painter: _AccentPainter(
          textPainter: textPainter,
          markPainter: markPainter,
          stressIndices: stressIndices,
        ),
      ),
    );
  }
}

class _AccentPainter extends CustomPainter {
  _AccentPainter({
    required this.textPainter,
    required this.markPainter,
    required this.stressIndices,
  });

  final TextPainter textPainter;
  final TextPainter markPainter;
  final List<int> stressIndices;

  @override
  void paint(Canvas canvas, Size size) {
    textPainter.paint(canvas, Offset.zero);
    final textBaseline = textPainter.computeDistanceToActualBaseline(TextBaseline.alphabetic);
    final markBaseline = markPainter.computeDistanceToActualBaseline(TextBaseline.alphabetic);
    for (final index in stressIndices) {
      final left = textPainter.getOffsetForCaret(TextPosition(offset: index), Rect.zero).dx;
      final right = textPainter.getOffsetForCaret(TextPosition(offset: index + 1), Rect.zero).dx;
      final midX = (left + right) / 2;
      markPainter.paint(canvas, Offset(midX - markPainter.width / 2, textBaseline - markBaseline));
    }
  }

  @override
  bool shouldRepaint(_AccentPainter oldDelegate) {
    return oldDelegate.textPainter.text != textPainter.text ||
        oldDelegate.markPainter.text != markPainter.text ||
        oldDelegate.stressIndices.toString() != stressIndices.toString();
  }
}
