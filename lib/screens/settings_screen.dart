import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../data/progress_store.dart';
import '../data/settings_store.dart';
import '../services/audio_service.dart';
import '../theme/app_colors.dart';
import '../theme/theme_fade.dart';
import '../widgets/common.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Ustawienia', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: context.c.foreground)),
          const SizedBox(height: 20),
          _Section(
            title: 'Wygląd',
            rows: [
              _SettingRow(
                title: 'Motyw',
                description: 'Wygląd interfejsu aplikacji',
                control: SegmentedButton<ThemeMode>(
                  segments: const [
                    ButtonSegment(value: ThemeMode.light, label: Text('Jasny')),
                    ButtonSegment(value: ThemeMode.dark, label: Text('Ciemny')),
                    ButtonSegment(value: ThemeMode.system, label: Text('Systemowy')),
                  ],
                  selected: {settings.themeMode},
                  onSelectionChanged: (selection) => switchThemeAnimated(ref, selection.first),
                  showSelectedIcon: false,
                ),
              ),
              _SettingRow(
                title: 'Znaki akcentu',
                description: 'Pokazuj akcent nad rosyjskimi słowami',
                control: Switch(value: settings.showAccents, onChanged: notifier.setShowAccents),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _Section(
            title: 'Audio',
            rows: [
              _SettingRow(
                title: 'Lektor',
                description: 'Głos czytający rosyjskie słówka',
                control: _LectorDropdown(
                  value: settings.lector,
                  onChanged: (lector) {
                    notifier.setLector(lector);
                    ref.read(audioServiceProvider).speakRussian('привет');
                  },
                ),
              ),
              _SettingRow(
                title: 'Auto-czytanie słówek',
                description: 'Czytaj na głos nowe słówka i pytania po rosyjsku',
                control: Switch(value: settings.autoplay, onChanged: notifier.setAutoplay),
              ),
              _SettingRow(
                title: 'Dźwięki odpowiedzi',
                description: 'Sygnał przy dobrej, prawie dobrej i błędnej odpowiedzi',
                control: Switch(value: settings.answerSounds, onChanged: notifier.setAnswerSounds),
              ),
              _SettingRow(
                title: 'Tempo mowy',
                description: 'Szybkość czytania słówek',
                control: SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: true, label: Text('Wolno')),
                    ButtonSegment(value: false, label: Text('Normalnie')),
                  ],
                  selected: {settings.slowSpeech},
                  onSelectionChanged: (selection) => notifier.setSlowSpeech(selection.first),
                  showSelectedIcon: false,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _Section(
            title: 'Klawiatura',
            rows: [
              _SettingRow(
                title: 'Klawiatura ekranowa',
                description: 'Pokazuj klawiaturę podczas ćwiczeń',
                control: Switch(value: settings.showKeyboard, onChanged: notifier.setShowKeyboard),
              ),
              _SettingRow(
                title: 'Podpowiedzi transliteracji',
                description: 'Łacińskie podpowiedzi na klawiszach',
                control: Switch(value: settings.showHints, onChanged: notifier.setShowHints),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _Section(
            title: 'Nauka',
            rows: [
              _SettingRow(
                title: 'Cel dzienny',
                description: 'Liczba nowych słówek na dzień',
                control: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _StepButton(icon: Icons.remove, onTap: () => notifier.setDailyGoal(settings.dailyGoal - 5)),
                    SizedBox(
                      width: 40,
                      child: Center(
                        child: Text('${settings.dailyGoal}',
                            style:
                                TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: context.c.foreground)),
                      ),
                    ),
                    _StepButton(icon: Icons.add, onTap: () => notifier.setDailyGoal(settings.dailyGoal + 5)),
                  ],
                ),
              ),
              _SettingRow(
                title: 'Zresetuj postępy',
                description: 'Usuwa całą historię nauki — nieodwracalne',
                control: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: context.c.destructive,
                    side: BorderSide(color: context.c.destructive),
                    minimumSize: const Size(0, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                  ),
                  onPressed: () => _confirmReset(context, ref),
                  child: const Text('Zresetuj'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          FutureBuilder<PackageInfo>(
            future: PackageInfo.fromPlatform(),
            builder: (context, snapshot) {
              final info = snapshot.data;
              if (info == null) return const SizedBox.shrink();
              return Text(
                'Verba ${info.version} (build ${info.buildNumber})',
                style: TextStyle(fontSize: 12, color: context.c.mutedForeground),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _confirmReset(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Zresetować postępy?'),
        content: const Text('Cała historia nauki zostanie usunięta. Tej operacji nie można cofnąć.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Anuluj')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Zresetuj')),
        ],
      ),
    );
    if (confirmed == true) {
      ref.read(progressProvider.notifier).resetAll();
    }
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.rows});

  final String title;
  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 640,
      child: AppCard(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: context.c.foreground)),
            const SizedBox(height: 8),
            for (final row in rows) row,
          ],
        ),
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({required this.title, required this.description, required this.control});

  final String title;
  final String description;
  final Widget control;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: context.c.foreground)),
                const SizedBox(height: 2),
                Text(description, style: TextStyle(fontSize: 13, color: context.c.mutedForeground)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          control,
        ],
      ),
    );
  }
}

class _LectorDropdown extends StatelessWidget {
  const _LectorDropdown({required this.value, required this.onChanged});

  final Lector value;
  final ValueChanged<Lector> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
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
                child: Text(lector.isPiper ? '${lector.label} (neuronowy)' : lector.label),
              ),
          ],
          onChanged: (lector) {
            if (lector != null) onChanged(lector);
          },
        ),
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      height: 32,
      child: Material(
        color: context.c.background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: context.c.border),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          mouseCursor: SystemMouseCursors.click,
          onTap: onTap,
          child: Icon(icon, size: 14, color: context.c.foreground),
        ),
      ),
    );
  }
}
