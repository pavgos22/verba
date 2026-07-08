import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class VerbaSwitch extends StatefulWidget {
  const VerbaSwitch({super.key, required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  State<VerbaSwitch> createState() => _VerbaSwitchState();
}

class _VerbaSwitchState extends State<VerbaSwitch> {
  static const _w = 52.0;
  static const _h = 30.0;
  static const _knob = 22.0;
  static const _wider = 44.0;
  static const _offset = (_h - _knob) / 2;
  static const _duration = Duration(milliseconds: 300);
  static const _curve = Curves.easeInOut;

  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final on = widget.value;
    final knobWidth = _pressed ? _wider : _knob;
    final left = on ? _w - knobWidth - _offset : _offset;
    final trackOff = context.c.mutedForeground.withValues(alpha: 0.35);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => widget.onChanged(!on),
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedContainer(
          duration: _duration,
          curve: _curve,
          width: _w,
          height: _h,
          decoration: BoxDecoration(
            color: on ? context.c.primary : trackOff,
            borderRadius: BorderRadius.circular(_h / 2),
          ),
          child: Stack(
            children: [
              AnimatedPositioned(
                duration: _duration,
                curve: _curve,
                left: left,
                top: _offset,
                child: AnimatedContainer(
                  duration: _duration,
                  curve: _curve,
                  width: knobWidth,
                  height: _knob,
                  decoration: BoxDecoration(
                    color: context.c.primaryForeground,
                    borderRadius: BorderRadius.circular(_knob / 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.10),
                        offset: Offset(on ? -10 : 10, 0),
                        blurRadius: 40,
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
