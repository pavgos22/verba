import 'package:flutter/material.dart';

import '../services/audio_service.dart';
import 'app_dropdown.dart';

class LectorDropdown extends StatelessWidget {
  const LectorDropdown({
    super.key,
    required this.value,
    required this.onChanged,
    this.googleUnavailable = false,
  });

  final Lector value;
  final ValueChanged<Lector> onChanged;
  final bool googleUnavailable;

  @override
  Widget build(BuildContext context) {
    return AppDropdown<Lector>(
      value: value,
      leadingIcon: Icons.record_voice_over_outlined,
      triggerPrefix: 'Lektor: ',
      menuWidth: 200,
      items: [
        for (final l in Lector.values)
          AppDropdownItem(
            value: l,
            label: l.label,
            enabled: !(googleUnavailable && l.hasAssets),
            tooltip: googleUnavailable && l.hasAssets
                ? 'Ten głos jest tylko dla wbudowanych kursów.\nDla własnych słówek gra głos systemowy.'
                : null,
          ),
      ],
      onChanged: onChanged,
    );
  }
}
