import 'package:flutter/material.dart';

import '../services/audio_service.dart';
import 'app_dropdown.dart';

class LectorDropdown extends StatelessWidget {
  const LectorDropdown({super.key, required this.value, required this.onChanged});

  final Lector value;
  final ValueChanged<Lector> onChanged;

  @override
  Widget build(BuildContext context) {
    return AppDropdown<Lector>(
      value: value,
      leadingIcon: Icons.record_voice_over_outlined,
      triggerPrefix: 'Lektor: ',
      menuWidth: 200,
      items: [for (final l in Lector.values) AppDropdownItem(value: l, label: l.label)],
      onChanged: onChanged,
    );
  }
}
