import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../data/progress_store.dart';
import '../data/settings_store.dart';
import '../services/audio_service.dart';
import '../theme/app_colors.dart';
import '../theme/theme_fade.dart';
import '../widgets/common.dart';
import '../widgets/lector_dropdown.dart';
import '../widgets/verba_switch.dart';

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
                control: VerbaSwitch(value: settings.showAccents, onChanged: notifier.setShowAccents),
              ),
              _SettingRow(
                title: 'Odmiana czasowników',
                description: 'Forma 1. osoby i typ przy czasownikach (Na Tab = po przytrzymaniu)',
                control: SegmentedButton<VerbInfoMode>(
                  segments: const [
                    ButtonSegment(value: VerbInfoMode.never, label: Text('Nie')),
                    ButtonSegment(value: VerbInfoMode.always, label: Text('Zawsze')),
                    ButtonSegment(value: VerbInfoMode.onHold, label: Text('Na Tab')),
                  ],
                  selected: {settings.verbInfo},
                  onSelectionChanged: (selection) => notifier.setVerbInfo(selection.first),
                  showSelectedIcon: false,
                ),
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
                control: LectorDropdown(
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
                control: VerbaSwitch(value: settings.autoplay, onChanged: notifier.setAutoplay),
              ),
              _SettingRow(
                title: 'Dźwięki odpowiedzi',
                description: 'Sygnał przy dobrej, prawie dobrej i błędnej odpowiedzi',
                control: VerbaSwitch(value: settings.answerSounds, onChanged: notifier.setAnswerSounds),
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
                control: VerbaSwitch(value: settings.showKeyboard, onChanged: notifier.setShowKeyboard),
              ),
              _SettingRow(
                title: 'Podpowiedzi transliteracji',
                description: 'Łacińskie podpowiedzi na klawiszach',
                control: VerbaSwitch(value: settings.showHints, onChanged: notifier.setShowHints),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _Section(
            title: 'Nauka',
            rows: [
              _SettingRow(
                title: 'Kolejność nowych słówek',
                description: 'Dobór nowych słówek w „Dzisiejszej sesji"',
                control: SegmentedButton<NewWordOrder>(
                  segments: const [
                    ButtonSegment(value: NewWordOrder.inOrder, label: Text('Po kolei')),
                    ButtonSegment(value: NewWordOrder.random, label: Text('Losowo')),
                  ],
                  selected: {settings.newWordOrder},
                  onSelectionChanged: (selection) => notifier.setNewWordOrder(selection.first),
                  showSelectedIcon: false,
                ),
              ),
              _SettingRow(
                title: 'Kolumna punktów (debug)',
                description: 'Pokazuje wynik punktowy słówka w tabeli Słówka',
                control: VerbaSwitch(value: settings.showWordPoints, onChanged: notifier.setShowWordPoints),
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

