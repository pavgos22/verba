import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/settings_store.dart';
import '../services/audio_service.dart';
import '../theme/app_colors.dart';

class AppCard extends StatelessWidget {
  const AppCard({super.key, required this.child, this.padding = const EdgeInsets.all(20)});

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: context.c.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.c.border),
      ),
      child: child,
    );
  }
}

class AppBadge extends StatelessWidget {
  const AppBadge({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: context.c.muted,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: context.c.mutedForeground),
      ),
    );
  }
}

class PronunciationSlot extends StatelessWidget {
  const PronunciationSlot({
    super.key,
    required this.pronunciation,
    required this.visible,
    this.fontSize = 13,
  });

  final String? pronunciation;
  final bool visible;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: fontSize + 8,
      child: visible && pronunciation != null
          ? Text(
              pronunciation!,
              style: TextStyle(fontSize: fontSize, color: context.c.mutedForeground),
            )
          : null,
    );
  }
}

class SpeakerButton extends ConsumerWidget {
  const SpeakerButton({super.key, required this.text, this.size = 36});

  final String text;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: size,
      height: size,
      child: Material(
        color: context.c.background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(size >= 44 ? 10 : 8),
          side: BorderSide(color: context.c.border),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(size >= 44 ? 10 : 8),
          mouseCursor: SystemMouseCursors.click,
          onTap: () async {
            final settings = ref.read(settingsProvider);
            final spoken =
                await ref.read(audioServiceProvider).speakRussian(text, slow: settings.slowSpeech);
            if (!spoken && context.mounted) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(const SnackBar(
                  content: Text(
                      'Brak rosyjskiego głosu w Windows. Zainstaluj: Ustawienia → Czas i język → Mowa → Dodaj głosy → rosyjski.'),
                  duration: Duration(seconds: 4),
                ));
            }
          },
          child: Icon(Icons.volume_up_outlined, size: size * 0.45, color: context.c.foreground),
        ),
      ),
    );
  }
}
