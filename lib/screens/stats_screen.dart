import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/progress_store.dart';
import '../data/words_repository.dart';
import '../theme/app_colors.dart';
import '../widgets/common.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wordsAsync = ref.watch(wordsProvider);
    final progress = ref.watch(progressProvider);
    return wordsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => const Center(child: Text('Nie udało się wczytać kursu')),
      data: (words) {
        final ids = words.map((w) => w.id);
        final fresh = progress.countByStatus(ids, WordStatus.fresh);
        final learning = progress.countByStatus(ids, WordStatus.learning);
        final mastered = progress.countByStatus(ids, WordStatus.mastered);
        var correct = 0;
        var wrong = 0;
        for (final p in progress.words.values) {
          correct += p.correct;
          wrong += p.wrong;
        }
        final total = correct + wrong;
        final accuracy = total == 0 ? '—' : '${(correct * 100 / total).round()}%';

        return Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Statystyki', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: context.c.foreground)),
              const SizedBox(height: 4),
              Text('Twoje postępy w kursie', style: TextStyle(fontSize: 14, color: context.c.mutedForeground)),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(child: _StatTile(label: 'Nowe', value: '$fresh', color: context.c.mutedForeground)),
                  const SizedBox(width: 16),
                  Expanded(child: _StatTile(label: 'W nauce', value: '$learning', color: context.c.foreground)),
                  const SizedBox(width: 16),
                  Expanded(child: _StatTile(label: 'Opanowane', value: '$mastered', color: context.c.success)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _StatTile(label: 'Ukończone sesje', value: '${progress.sessions}', color: context.c.foreground)),
                  const SizedBox(width: 16),
                  Expanded(child: _StatTile(label: 'Skuteczność odpowiedzi', value: accuracy, color: context.c.foreground)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _StatTile(
                      label: 'Seria dni',
                      value: '${progress.streak}',
                      color: context.c.foreground,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: context.c.mutedForeground)),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}
