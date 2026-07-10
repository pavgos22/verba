import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/transliteration.dart';
import '../data/custom_courses.dart';
import '../data/word.dart';
import '../data/words_repository.dart';
import '../theme/app_colors.dart';
import '../widgets/app_dropdown.dart';
import '../widgets/onscreen_keyboard.dart';

class CourseEditorScreen extends ConsumerStatefulWidget {
  const CourseEditorScreen({super.key, required this.courseId});

  final String courseId;

  @override
  ConsumerState<CourseEditorScreen> createState() => _CourseEditorScreenState();
}

class _CourseEditorScreenState extends ConsumerState<CourseEditorScreen> {
  final _ru = TextEditingController();
  final _pl = TextEditingController();
  final _firstPerson = TextEditingController();
  final _verbType = TextEditingController();
  final _pronunciation = TextEditingController();
  final _ruFocus = FocusNode();
  final _plFocus = FocusNode();
  final _firstPersonFocus = FocusNode();
  final _verbTypeFocus = FocusNode();
  final _pronunciationFocus = FocusNode();
  String? _category;
  late TextEditingController _active = _ru;
  KeyboardLayoutType _layout = KeyboardLayoutType.polish;

  @override
  void initState() {
    super.initState();
    _target(_ruFocus, _ru);
    _target(_firstPersonFocus, _firstPerson);
    _target(_plFocus, _pl);
    _target(_verbTypeFocus, _verbType);
    _target(_pronunciationFocus, _pronunciation);
  }

  void _target(FocusNode node, TextEditingController controller) {
    node.addListener(() {
      if (node.hasFocus) _active = controller;
    });
  }

  @override
  void dispose() {
    _ru.dispose();
    _pl.dispose();
    _firstPerson.dispose();
    _verbType.dispose();
    _pronunciation.dispose();
    _ruFocus.dispose();
    _plFocus.dispose();
    _firstPersonFocus.dispose();
    _verbTypeFocus.dispose();
    _pronunciationFocus.dispose();
    super.dispose();
  }

  void _add() {
    final ru = _ru.text.trim();
    final plRaw = _pl.text.trim();
    if (ru.isEmpty || plRaw.isEmpty) return;
    final pl = plRaw.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    if (pl.isEmpty) return;
    final firstPerson = _firstPerson.text.trim();
    final verbType = _verbType.text.trim();
    final pronunciation = _pronunciation.text.trim();
    final word = Word(
      id: 'w-${DateTime.now().microsecondsSinceEpoch}',
      ru: ru,
      pl: pl,
      category: _category,
      pronunciation: pronunciation.isEmpty ? null : pronunciation,
      firstPerson: firstPerson.isEmpty ? null : firstPerson,
      verbType: verbType.isEmpty ? null : verbType,
    );
    ref.read(customCoursesProvider.notifier).addWord(widget.courseId, word);
    _ru.clear();
    _pl.clear();
    _firstPerson.clear();
    _verbType.clear();
    _pronunciation.clear();
    _ruFocus.requestFocus();
  }

  List<String> _allCategories() {
    return ref.watch(coursesProvider).maybeWhen(
      data: (courses) {
        final set = <String>{};
        for (final course in courses) {
          for (final word in course.words) {
            if (word.category != null && word.category!.isNotEmpty) set.add(word.category!);
          }
        }
        final list = set.toList()..sort();
        return list;
      },
      orElse: () => const <String>[],
    );
  }

  Future<void> _import(bool hasWords) async {
    final messenger = ScaffoldMessenger.of(context);
    void fail(String msg) => messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('Nie udało się zaimportować: $msg'), duration: const Duration(seconds: 4)));
    List<Word> words;
    try {
      final file = await pickCourseJson();
      if (file == null) return;
      words = parseCourseJson(file.raw, 'import').words;
    } on FormatException catch (e) {
      fail(e.message);
      return;
    } catch (_) {
      fail('nie udało się odczytać pliku');
      return;
    }
    if (!mounted) return;
    var mode = 'add';
    if (hasWords) {
      final choice = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Import słówek'),
          content: Text('Plik zawiera ${words.length} słówek. Co zrobić z obecnymi słówkami w kursie?'),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Anuluj')),
            TextButton(onPressed: () => Navigator.of(context).pop('add'), child: const Text('Dodaj do kursu')),
            FilledButton(onPressed: () => Navigator.of(context).pop('replace'), child: const Text('Zastąp wszystkie')),
          ],
        ),
      );
      if (choice == null) return;
      mode = choice;
    }
    final notifier = ref.read(customCoursesProvider.notifier);
    if (mode == 'replace') {
      notifier.setWords(widget.courseId, words);
    } else {
      notifier.addWords(widget.courseId, words);
    }
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(mode == 'replace'
            ? 'Zastąpiono — ${words.length} słówek'
            : 'Dodano ${words.length} słówek'),
        duration: const Duration(seconds: 3),
      ));
  }

  @override
  Widget build(BuildContext context) {
    final course = ref.watch(customCoursesProvider.select((list) {
      for (final c in list) {
        if (c.id == widget.courseId) return c;
      }
      return null;
    }));

    if (course == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Kurs nie istnieje'),
              const SizedBox(height: 12),
              FilledButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Wróć')),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(6),
              mouseCursor: SystemMouseCursors.click,
              onTap: () => Navigator.of(context).pop(),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.chevron_left, size: 16, color: context.c.mutedForeground),
                    const SizedBox(width: 4),
                    Text('Kursy', style: TextStyle(fontSize: 13, color: context.c.mutedForeground)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(course.name,
                          style:
                              TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: context.c.foreground)),
                      const SizedBox(height: 4),
                      Text('${course.words.length} słówek · własny kurs',
                          style: TextStyle(fontSize: 14, color: context.c.mutedForeground)),
                    ],
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () => _import(course.words.isNotEmpty),
                  icon: const Icon(Icons.upload_file_outlined, size: 16),
                  label: const Text('Importuj JSON'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.c.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.c.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: _Field(
                            label: 'Rosyjski',
                            controller: _ru,
                            focusNode: _ruFocus,
                            transliterate: true,
                            onSubmit: _add),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _Field(label: 'Polski', controller: _pl, focusNode: _plFocus, onSubmit: _add),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 200,
                        child: _DropdownField(
                          value: _category,
                          categories: _allCategories(),
                          onChanged: (value) => setState(() => _category = value),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: _Field(
                            label: 'Wymowa (opcjonalnie)',
                            controller: _pronunciation,
                            focusNode: _pronunciationFocus,
                            onSubmit: _add),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _Field(
                            label: '1. osoba — czasownik (opcjonalnie)',
                            controller: _firstPerson,
                            focusNode: _firstPersonFocus,
                            transliterate: true,
                            onSubmit: _add),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 140,
                        child: _Field(
                            label: 'Typ (opcjonalnie)',
                            controller: _verbType,
                            focusNode: _verbTypeFocus,
                            onSubmit: _add),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        height: 40,
                        child: FilledButton(
                          onPressed: _add,
                          style: FilledButton.styleFrom(
                            minimumSize: Size.zero,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text('Dodaj'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Rosyjski i 1. osoba: pisz po łacińsku (q = akcent) lub klawiaturą niżej '
                    '(dolny rząd rosyjskiej klawiatury to samogłoski z akcentem). '
                    'Polski: warianty po przecinku. Wymowa, kategoria oraz pola czasownika są opcjonalne.',
                    style: TextStyle(fontSize: 12, color: context.c.mutedForeground),
                  ),
                  const SizedBox(height: 14),
                  Center(
                    child: SegmentedButton<KeyboardLayoutType>(
                      segments: const [
                        ButtonSegment(value: KeyboardLayoutType.russian, label: Text('Rosyjska')),
                        ButtonSegment(value: KeyboardLayoutType.polish, label: Text('Polska')),
                      ],
                      selected: {_layout},
                      onSelectionChanged: (selection) => setState(() => _layout = selection.first),
                      showSelectedIcon: false,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: OnScreenKeyboard(
                      layout: _layout,
                      onText: (text) => insertIntoController(_active, text),
                      onBackspace: () => backspaceInController(_active),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (course.words.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Text('Dodaj pierwsze słówko powyżej',
                      style: TextStyle(fontSize: 14, color: context.c.mutedForeground)),
                ),
              )
            else
              Container(
                decoration: BoxDecoration(
                  color: context.c.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: context.c.border),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    for (final (index, word) in course.words.indexed)
                      Container(
                        height: 52,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(border: Border(top: BorderSide(color: context.c.border))),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 36,
                              child: Text('${index + 1}',
                                  style: TextStyle(fontSize: 13, color: context.c.mutedForeground)),
                            ),
                            SizedBox(
                              width: 264,
                              child: Text(word.ru,
                                  style: TextStyle(
                                      fontSize: 15, fontWeight: FontWeight.w500, color: context.c.foreground)),
                            ),
                            Expanded(
                              child: Text(word.pl.join(', '),
                                  style: TextStyle(fontSize: 14, color: context.c.foreground)),
                            ),
                            IconButton(
                              onPressed: () =>
                                  ref.read(customCoursesProvider.notifier).removeWord(widget.courseId, word.id),
                              icon: Icon(Icons.delete_outline, size: 18, color: context.c.mutedForeground),
                              tooltip: 'Usuń',
                              mouseCursor: SystemMouseCursors.click,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Zapisz'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DropdownField extends StatelessWidget {
  const _DropdownField({required this.value, required this.categories, required this.onChanged});

  final String? value;
  final List<String> categories;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Kategoria',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: context.c.mutedForeground)),
        const SizedBox(height: 6),
        AppDropdown<String?>(
          value: value,
          expand: true,
          menuWidth: 200,
          onChanged: onChanged,
          items: [
            const AppDropdownItem<String?>(value: null, label: 'Bez kategorii'),
            for (final category in categories) AppDropdownItem<String?>(value: category, label: category),
          ],
        ),
      ],
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.controller,
    this.focusNode,
    this.transliterate = false,
    required this.onSubmit,
  });

  final String label;
  final TextEditingController controller;
  final FocusNode? focusNode;
  final bool transliterate;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: context.c.mutedForeground)),
        const SizedBox(height: 6),
        SizedBox(
          height: 40,
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            inputFormatters: transliterate ? [TransliterationFormatter()] : null,
            onSubmitted: (_) => onSubmit(),
            style: TextStyle(fontSize: 14, color: context.c.foreground),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
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
        ),
      ],
    );
  }
}
