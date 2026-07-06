import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/progress_store.dart';
import '../data/settings_store.dart';
import '../data/word.dart';
import '../data/words_repository.dart';
import '../theme/app_colors.dart';
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                          Text(wordOfDay.ruAccented,
                              style:
                                  TextStyle(fontSize: 32, fontWeight: FontWeight.w600, color: context.c.foreground)),
                          const SizedBox(width: 12),
                          SpeakerButton(text: wordOfDay.ru),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(wordOfDay.pl.join(', '), style: TextStyle(fontSize: 14, color: context.c.mutedForeground)),
                      const SizedBox(height: 12),
                      Row(children: [AppBadge(label: wordOfDay.category)]),
                    ],
                  ),
                ),
              ),
            ],
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
