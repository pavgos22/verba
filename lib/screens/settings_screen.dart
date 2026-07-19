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
                title: 'Odmiana słówek',
                description: 'Formy czasowników i rodzaje przymiotników (Na Tab = po przytrzymaniu)',
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
                  googleUnavailable: settings.activeCourseId.startsWith('custom-'),
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
                title: 'Głośniczek polskich słówek',
                description: 'Pokazuj polski głośnik obok polskich słówek w sesji',
                control: VerbaSwitch(value: settings.showPolishSpeaker, onChanged: notifier.setShowPolishSpeaker),
              ),
              _SettingRow(
                title: 'Auto-czytanie po polsku',
                description: 'Przy pytaniach PL→RU czytaj na głos polskie słówko',
                control: VerbaSwitch(value: settings.autoplayPolish, onChanged: notifier.setAutoplayPolish),
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
              _SettingRow(
                title: 'Automatyczny układ klawiatury',
                description: 'W edytorze kursu przełączaj układ (rosyjski/polski) do wybranego pola',
                control: VerbaSwitch(value: settings.autoKeyboardLayout, onChanged: notifier.setAutoKeyboardLayout),
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
                title: 'Puste Enter = „Nie wiem"',
                description: 'Enter przy pustym polu zalicza odpowiedź jako „Nie wiem"',
                control: VerbaSwitch(value: settings.enterEmptyIsGiveUp, onChanged: notifier.setEnterEmptyIsGiveUp),
              ),
              _SettingRow(
                title: 'Szczegóły po poprawnej odpowiedzi',
                description: 'Po dobrej odpowiedzi pokazuj odmianę i wymowę (jak na Tab)',
                control: VerbaSwitch(value: settings.detailsAfterCorrect, onChanged: notifier.setDetailsAfterCorrect),
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
          _Section(
            title: 'Tłumacz',
            rows: [
              _SettingRow(
                title: 'Klucz API DeepL',
                description: 'Opcjonalnie — klucz DeepL (deepl.com) dla lepszej jakości; bez klucza tłumaczy MyMemory',
                control: const _ApiKeyField(),
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

class _ApiKeyField extends ConsumerStatefulWidget {
  const _ApiKeyField();

  @override
  ConsumerState<_ApiKeyField> createState() => _ApiKeyFieldState();
}

class _ApiKeyFieldState extends ConsumerState<_ApiKeyField> {
  late final TextEditingController _controller =
      TextEditingController(text: ref.read(settingsProvider).translatorApiKey);
  bool _obscure = true;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      child: TextField(
        controller: _controller,
        obscureText: _obscure,
        onChanged: (value) => ref.read(settingsProvider.notifier).setTranslatorApiKey(value.trim()),
        style: TextStyle(fontSize: 14, color: context.c.mutedForeground),
        decoration: InputDecoration(
          hintText: 'xxxxxxxx-…:fx',
          hintStyle: TextStyle(fontSize: 14, color: context.c.mutedForeground.withValues(alpha: 0.5)),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          suffixIcon: IconButton(
            icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                size: 18, color: context.c.mutedForeground),
            onPressed: () => setState(() => _obscure = !_obscure),
            tooltip: _obscure ? 'Pokaż' : 'Ukryj',
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: context.c.inputBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: context.c.ring),
          ),
        ),
      ),
    );
  }
}

