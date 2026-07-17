import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class VerbaSwitch extends StatelessWidget {
  const VerbaSwitch({super.key, required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  static const _trackW = 42.0;
  static const _trackH = 16.0;
  static const _thumb = 22.0;
  static const _travel = _trackW - _thumb;
  static const _duration = Duration(milliseconds: 200);
  static const _curve = Curves.easeInOut;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final on = value;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final trackColor = (on ? c.primary : c.mutedForeground).withValues(alpha: 0.38);
    final thumbColor = on ? c.primary : (isDark ? c.foreground : c.card);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => onChanged(!on),
        child: SizedBox(
          width: _trackW,
          height: _thumb,
          child: Stack(
            alignment: Alignment.centerLeft,
            clipBehavior: Clip.none,
            children: [
              AnimatedContainer(
                duration: _duration,
                curve: _curve,
                width: _trackW,
                height: _trackH,
                decoration: BoxDecoration(
                  color: trackColor,
                  borderRadius: BorderRadius.circular(_trackH / 2),
                ),
              ),
              AnimatedPositioned(
                duration: _duration,
                curve: _curve,
                left: on ? _travel : 0,
                child: AnimatedContainer(
                  duration: _duration,
                  curve: _curve,
                  width: _thumb,
                  height: _thumb,
                  decoration: BoxDecoration(
                    color: thumbColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.20),
                        offset: const Offset(0, 2),
                        blurRadius: 2.5,
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        offset: const Offset(0, 1),
                        blurRadius: 5,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
