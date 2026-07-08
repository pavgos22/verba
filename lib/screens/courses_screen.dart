import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/course.dart';
import '../data/custom_courses.dart';
import '../data/progress_store.dart';
import '../data/settings_store.dart';
import '../data/words_repository.dart';
import '../theme/app_colors.dart';
import '../widgets/common.dart';
import 'course_editor_screen.dart';

class CoursesScreen extends ConsumerWidget {
  const CoursesScreen({super.key});

  void _openEditor(BuildContext context, String courseId) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => CourseEditorScreen(courseId: courseId)),
    );
  }

  Future<void> _newCourse(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<(String, String)>(
      context: context,
      builder: (_) => const _CourseDialog(),
    );
    if (result == null) return;
    final course = ref.read(customCoursesProvider.notifier).createCourse(result.$1, result.$2);
    if (context.mounted) _openEditor(context, course.id);
  }

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
              Text('Wybierz kurs lub stwórz własny',
                  style: TextStyle(fontSize: 14, color: context.c.mutedForeground)),
              const SizedBox(height: 24),
              for (final course in courses) ...[
                _CourseCard(
                  course: course,
                  active: course.id == activeId,
                  onEdit: course.isCustom ? () => _openEditor(context, course.id) : null,
                  onDelete: course.isCustom ? () => _confirmDelete(context, ref, course) : null,
                ),
                const SizedBox(height: 16),
              ],
              _AddCourseCard(onTap: () => _newCourse(context, ref)),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, Course course) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Usunąć kurs?'),
        content: Text('Kurs „${course.name}" i jego słówka zostaną usunięte. Tej operacji nie można cofnąć.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Anuluj')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: context.c.destructive),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Usuń'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      ref.read(customCoursesProvider.notifier).deleteCourse(course.id);
      if (ref.read(settingsProvider).activeCourseId == course.id) {
        ref.read(settingsProvider.notifier).setActiveCourseId('starter');
      }
    }
  }
}

class _CourseCard extends ConsumerWidget {
  const _CourseCard({required this.course, required this.active, this.onEdit, this.onDelete});

  final Course course;
  final bool active;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(progressProvider);
    final ids = course.words.map((w) => w.id);
    final mastered = progress.countByStatus(ids, WordStatus.mastered);
    final learning = progress.countByStatus(ids, WordStatus.learning);
    final total = course.words.length;
    final percent = total == 0 ? 0 : (mastered * 100 / total).round();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.c.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: active ? context.c.primary : context.c.border, width: active ? 2 : 1),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: context.c.muted, borderRadius: BorderRadius.circular(10)),
            child: Icon(course.isCustom ? Icons.edit_note : Icons.menu_book_outlined,
                size: 22, color: context.c.foreground),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(course.name,
                          overflow: TextOverflow.ellipsis,
                          style:
                              TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: context.c.foreground)),
                    ),
                    if (course.isCustom) ...[
                      const SizedBox(width: 8),
                      const AppBadge(label: 'własny'),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                Text(course.description.isEmpty ? 'Własny zestaw' : course.description,
                    style: TextStyle(fontSize: 14, color: context.c.mutedForeground)),
                const SizedBox(height: 6),
                Text('$total słówek · $learning w nauce · $mastered opanowanych ($percent%)',
                    style: TextStyle(fontSize: 13, color: context.c.mutedForeground)),
                const SizedBox(height: 10),
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
          const SizedBox(width: 20),
          if (onEdit != null) ...[
            _IconAction(icon: Icons.edit_outlined, onTap: onEdit!, tooltip: 'Edytuj'),
            const SizedBox(width: 4),
            _IconAction(icon: Icons.delete_outline, onTap: onDelete!, tooltip: 'Usuń', danger: true),
            const SizedBox(width: 8),
          ],
          if (active)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: context.c.primary, borderRadius: BorderRadius.circular(14)),
              child: Text('Aktywny',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: context.c.primaryForeground)),
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

class _IconAction extends StatelessWidget {
  const _IconAction({required this.icon, required this.onTap, required this.tooltip, this.danger = false});

  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      height: 36,
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
          child: Tooltip(
            message: tooltip,
            child: Icon(icon, size: 16, color: danger ? context.c.destructive : context.c.mutedForeground),
          ),
        ),
      ),
    );
  }
}

class _AddCourseCard extends StatelessWidget {
  const _AddCourseCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.c.background,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        mouseCursor: SystemMouseCursors.click,
        onTap: onTap,
        child: Container(
          height: 72,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.c.border, width: 2),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add, size: 18, color: context.c.mutedForeground),
              const SizedBox(width: 10),
              Text('Dodaj własny kurs',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: context.c.mutedForeground)),
            ],
          ),
        ),
      ),
    );
  }
}

class _CourseDialog extends StatefulWidget {
  const _CourseDialog();

  @override
  State<_CourseDialog> createState() => _CourseDialogState();
}

class _CourseDialogState extends State<_CourseDialog> {
  final _name = TextEditingController();
  final _desc = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nowy kurs'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nazwa kursu',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: context.c.mutedForeground)),
            const SizedBox(height: 6),
            _Box(controller: _name, hint: 'np. Moje czasowniki', autofocus: true),
            const SizedBox(height: 14),
            Text('Opis (opcjonalnie)',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: context.c.mutedForeground)),
            const SizedBox(height: 6),
            _Box(controller: _desc, hint: 'Krótki opis kursu', minLines: 3, maxLines: 4),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Anuluj')),
        FilledButton(
          onPressed: () {
            final name = _name.text.trim();
            if (name.isEmpty) return;
            Navigator.of(context).pop((name, _desc.text.trim()));
          },
          child: const Text('Utwórz'),
        ),
      ],
    );
  }
}

class _Box extends StatelessWidget {
  const _Box({
    required this.controller,
    required this.hint,
    this.autofocus = false,
    this.minLines = 1,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String hint;
  final bool autofocus;
  final int minLines;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      autofocus: autofocus,
      minLines: minLines,
      maxLines: maxLines,
      style: TextStyle(fontSize: 14, color: context.c.foreground),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(fontSize: 14, color: context.c.mutedForeground),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: context.c.inputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: context.c.ring),
        ),
      ),
    );
  }
}
