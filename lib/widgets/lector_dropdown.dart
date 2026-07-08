import 'package:flutter/material.dart';

import '../services/audio_service.dart';
import '../theme/app_colors.dart';

class LectorDropdown extends StatelessWidget {
  const LectorDropdown({super.key, required this.value, required this.onChanged});

  final Lector value;
  final ValueChanged<Lector> onChanged;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: context.c.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: context.c.inputBorder),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<Lector>(
            value: value,
            isDense: true,
            borderRadius: BorderRadius.circular(8),
            dropdownColor: context.c.card,
            style: TextStyle(fontSize: 14, fontFamily: 'Inter', color: context.c.foreground),
            icon: Icon(Icons.expand_more, size: 18, color: context.c.mutedForeground),
            items: [
              for (final lector in Lector.values)
                DropdownMenuItem(
                  value: lector,
                  child: MouseRegion(cursor: SystemMouseCursors.click, child: Text(lector.label)),
                ),
            ],
            onChanged: (lector) {
              if (lector != null) onChanged(lector);
            },
          ),
        ),
      ),
    );
  }
}
