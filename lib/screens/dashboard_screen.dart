import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/progress_store.dart';
import '../data/settings_store.dart';
import '../data/word.dart';
import '../data/words_repository.dart';
import '../theme/app_colors.dart';
import '../widgets/accented_text.dart';
import '../widgets/common.dart';
import 'session_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wordsAsync = ref.watch(wordsProvider);
    return wordsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => const Center(child: Text('Nie udało się wczytać kursu')),
      data: (words) => _Dashboard(words: words),
    );
  }
}

class _Dashboard extends ConsumerWidget {
  const _Dashboard({required this.words});

  final List<Word> words;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(progressProvider);
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(progressProvider.notifier);
    final now = DateTime.now();
    final fresh = words.where((w) => progress.statusOf(w.id) == WordStatus.fresh).toList();
    final due = words.where((w) => notifier.isDue(w.id, now)).toList();
    final mastered = words.where((w) => progress.statusOf(w.id) == WordStatus.mastered).length;
    final started = words.length - fresh.length;
    final newToday = min(settings.dailyGoal, fresh.length);
    final dayOfYear = now.difference(DateTime(now.year)).inDays;
    final wordOfDay = words[dayOfYear % words.length];
    final minutes = max(1, ((newToday * 2 + due.length) / 3).ceil());
    final hasWork = newToday > 0 || due.isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Привет!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: context.c.foreground)),
          const SizedBox(height: 4),
          Text(
            progress.streak > 0
                ? 'Tak trzymaj — Twoja seria to ${_dayLabel(progress.streak)}.'
                : 'Zacznij dziś swoją serię nauki.',
            style: TextStyle(fontSize: 14, color: context.c.mutedForeground),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _StatCard(icon: Icons.auto_awesome_outlined, label: 'Nowe słówka', value: '$newToday', sub: 'na dziś'),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _StatCard(icon: Icons.history, label: 'Powtórki', value: '${due.length}', sub: 'na dziś'),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _StatCard(
                  icon: Icons.local_fire_department_outlined,
                  label: 'Seria',
                  value: _dayLabel(progress.streak),
                  sub: 'sesje łącznie: ${progress.sessions}',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _StatCard(
                  icon: Icons.trending_up,
                  label: 'Postęp kursu',
                  value: '$mastered / ${words.length}',
                  sub: '${(mastered * 100 / words.length).round()}% opanowane',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
              Expanded(
                child: AppCard(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Dzisiejsza sesja',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: context.c.foreground)),
                      const SizedBox(height: 4),
                      Text(
                        hasWork
                            ? '$newToday nowych słówek i ${due.length} powtórek — około $minutes min'
                            : 'Wszystko zrobione! Wróć jutro po nowe powtórki.',
                        style: TextStyle(fontSize: 14, color: context.c.mutedForeground),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        children: [
                          FilledButton(
                            onPressed: hasWork
                                ? () => Navigator.of(context).push(
                                      MaterialPageRoute(builder: (_) => const SessionScreen(mode: SessionMode.full)),
                                    )
                                : null,
                            child: const Text('Rozpocznij naukę'),
                          ),
                          OutlinedButton(
                            onPressed: due.isNotEmpty
                                ? () => Navigator.of(context).push(
                                      MaterialPageRoute(
                                          builder: (_) => const SessionScreen(mode: SessionMode.reviewsOnly)),
                                    )
                                : null,
                            child: const Text('Tylko powtórki'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: AppCard(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Słowo dnia',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: context.c.mutedForeground)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          AccentedText(wordOfDay.ruAccented,
                              style:
                                  TextStyle(fontSize: 32, fontWeight: FontWeight.w600, color: context.c.foreground)),
                          const SizedBox(width: 12),
                          SpeakerButton(text: wordOfDay.ru),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(wordOfDay.pl.join(', '), style: TextStyle(fontSize: 14, color: context.c.mutedForeground)),
                      const SizedBox(height: 12),
                      AppBadge(label: wordOfDay.category),
                    ],
                  ),
                ),
              ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _ModeCard(
                    title: 'Utrwalanie',
                    description:
                        'Tłumaczysz rozpoczęte słówka bez podpowiedzi i bez presji terminów. Błędy poprawiasz na bieżąco.',
                    buttonLabel: 'Ćwicz',
                    onPressed: started > 0
                        ? () => Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) => const SessionScreen(mode: SessionMode.practice)),
                            )
                        : null,
                    onSettings: () => showDialog<void>(
                      context: context,
                      builder: (_) => const _SessionSettingsDialog(forTest: false),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _ModeCard(
                    title: 'Test',
                    description:
                        'Sprawdzian z poznanych słówek — bez poprawiania błędów po drodze, wynik zobaczysz dopiero na końcu.',
                    buttonLabel: 'Rozpocznij test',
                    onPressed: started > 0
                        ? () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const SessionScreen(mode: SessionMode.test)),
                            )
                        : null,
                    onSettings: () => showDialog<void>(
                      context: context,
                      builder: (_) => const _SessionSettingsDialog(forTest: true),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _dayLabel(int days) {
    if (days == 1) return '1 dzień';
    return '$days dni';
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.title,
    required this.description,
    required this.buttonLabel,
    required this.onPressed,
    required this.onSettings,
  });

  final String title;
  final String description;
  final String buttonLabel;
  final VoidCallback? onPressed;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: context.c.foreground)),
          const SizedBox(height: 4),
          Text(description, style: TextStyle(fontSize: 14, color: context.c.mutedForeground)),
          const SizedBox(height: 16),
          const Spacer(),
          Row(
            children: [
              OutlinedButton(onPressed: onPressed, child: Text(buttonLabel)),
              const Spacer(),
              SizedBox(
                width: 32,
                height: 32,
                child: Material(
                  color: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    mouseCursor: SystemMouseCursors.click,
                    onTap: onSettings,
                    child: Tooltip(
                      message: 'Ustawienia sesji',
                      child: Icon(Icons.settings_outlined, size: 18, color: context.c.mutedForeground),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SessionSettingsDialog extends ConsumerStatefulWidget {
  const _SessionSettingsDialog({required this.forTest});

  final bool forTest;

  @override
  ConsumerState<_SessionSettingsDialog> createState() => _SessionSettingsDialogState();
}

class _SessionSettingsDialogState extends ConsumerState<_SessionSettingsDialog> {
  SessionDirection? _selected;

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final current = _selected ?? (widget.forTest ? settings.testDirection : settings.practiceDirection);
    return AlertDialog(
      title: Text(widget.forTest ? 'Ustawienia testu' : 'Ustawienia utrwalania'),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Kierunek tłumaczenia',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: context.c.mutedForeground)),
            const SizedBox(height: 8),
            for (final (direction, label) in const [
              (SessionDirection.random, 'Losowo (domyślnie)'),
              (SessionDirection.ruToPl, 'Rosyjski → polski'),
              (SessionDirection.plToRu, 'Polski → rosyjski'),
              (SessionDirection.alternate, 'Na przemian'),
            ])
              _DirectionOption(
                label: label,
                selected: current == direction,
                onTap: () => setState(() => _selected = direction),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Anuluj')),
        FilledButton(
          onPressed: () {
            final notifier = ref.read(settingsProvider.notifier);
            if (widget.forTest) {
              notifier.setTestDirection(current);
            } else {
              notifier.setPracticeDirection(current);
            }
            Navigator.of(context).pop();
          },
          child: const Text('Zapisz'),
        ),
      ],
    );
  }
}

class _DirectionOption extends StatelessWidget {
  const _DirectionOption({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      mouseCursor: SystemMouseCursors.click,
      onTap: onTap,
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? context.c.primary : context.c.border,
                  width: selected ? 5 : 1.5,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(label, style: TextStyle(fontSize: 14, color: context.c.foreground)),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.icon, required this.label, required this.value, required this.sub});

  final IconData icon;
  final String label;
  final String value;
  final String sub;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: context.c.mutedForeground),
              const SizedBox(width: 8),
              Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: context.c.mutedForeground)),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: context.c.foreground)),
          const SizedBox(height: 4),
          Text(sub, style: TextStyle(fontSize: 12, color: context.c.mutedForeground)),
        ],
      ),
    );
  }
}
