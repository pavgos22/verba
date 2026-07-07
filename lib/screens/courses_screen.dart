import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/course.dart';
import '../data/progress_store.dart';
import '../data/settings_store.dart';
import '../data/words_repository.dart';
import '../theme/app_colors.dart';
import '../widgets/common.dart';

class CoursesScreen extends ConsumerWidget {
  const CoursesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coursesAsync = ref.watch(coursesProvider);
    return coursesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => const Center(child: Text('Nie udało się wczytać kursów')),
      data: (courses) {
        final activeId = ref.watch(settingsProvider.select((s) => s.activeCourseId));
        return SingleChildScrollView(
          padding: const EdgeInsets.all(40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Kursy', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: context.c.foreground)),
              const SizedBox(height: 4),
              Text('Wybierz kurs, z którego chcesz się uczyć',
                  style: TextStyle(fontSize: 14, color: context.c.mutedForeground)),
              const SizedBox(height: 24),
              for (final course in courses) ...[
                _CourseCard(course: course, active: course.id == activeId),
                const SizedBox(height: 16),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _CourseCard extends ConsumerWidget {
  const _CourseCard({required this.course, required this.active});

  final Course course;
  final bool active;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(progressProvider);
    final ids = course.words.map((w) => w.id);
    final mastered = progress.countByStatus(ids, WordStatus.mastered);
    final learning = progress.countByStatus(ids, WordStatus.learning);
    final total = course.words.length;
    final percent = total == 0 ? 0 : (mastered * 100 / total).round();

    return AppCard(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(course.name,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: context.c.foreground)),
                const SizedBox(height: 4),
                Text(course.description, style: TextStyle(fontSize: 14, color: context.c.mutedForeground)),
                const SizedBox(height: 12),
                Text('$total słówek · $learning w nauce · $mastered opanowanych ($percent%)',
                    style: TextStyle(fontSize: 13, color: context.c.mutedForeground)),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: total == 0 ? 0 : mastered / total,
                    minHeight: 6,
                    backgroundColor: context.c.muted,
                    color: context.c.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          if (active)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: context.c.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text('Aktywny',
                  style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w500, color: context.c.primaryForeground)),
            )
          else
            OutlinedButton(
              onPressed: () => ref.read(settingsProvider.notifier).setActiveCourseId(course.id),
              child: const Text('Wybierz'),
            ),
        ],
      ),
    );
  }
}
