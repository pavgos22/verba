import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/transliteration.dart';
import '../data/course.dart';
import '../data/custom_courses.dart';
import '../data/settings_store.dart';
import '../data/word.dart';
import '../data/words_repository.dart';
import '../theme/app_colors.dart';
import '../widgets/accented_text.dart';
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
  final _secondPerson = TextEditingController();
  final _verbType = TextEditingController();
  final _masculine = TextEditingController();
  final _feminine = TextEditingController();
  final _neuter = TextEditingController();
  final _plural = TextEditingController();
  final _pronunciation = TextEditingController();
  final _ruFocus = FocusNode();
  final _plFocus = FocusNode();
  final _firstPersonFocus = FocusNode();
  final _secondPersonFocus = FocusNode();
  final _verbTypeFocus = FocusNode();
  final _masculineFocus = FocusNode();
  final _feminineFocus = FocusNode();
  final _neuterFocus = FocusNode();
  final _pluralFocus = FocusNode();
  final _pronunciationFocus = FocusNode();
  String? _category;
  late TextEditingController _active = _ru;
  KeyboardLayoutType _layout = KeyboardLayoutType.polish;
  bool _ruError = false;
  bool _plError = false;

  bool get _isVerb => _category == 'czasowniki';
  bool get _isAdjective => _category == 'przymiotniki';

  @override
  void initState() {
    super.initState();
    _target(_ruFocus, _ru, KeyboardLayoutType.russian);
    _target(_firstPersonFocus, _firstPerson, KeyboardLayoutType.russian);
    _target(_secondPersonFocus, _secondPerson, KeyboardLayoutType.russian);
    _target(_masculineFocus, _masculine, KeyboardLayoutType.russian);
    _target(_feminineFocus, _feminine, KeyboardLayoutType.russian);
    _target(_neuterFocus, _neuter, KeyboardLayoutType.russian);
    _target(_pluralFocus, _plural, KeyboardLayoutType.russian);
    _target(_plFocus, _pl, KeyboardLayoutType.polish);
    _target(_verbTypeFocus, _verbType);
    _target(_pronunciationFocus, _pronunciation, KeyboardLayoutType.polish);
  }

  void _target(FocusNode node, TextEditingController controller, [KeyboardLayoutType? layout]) {
    node.addListener(() {
      if (!node.hasFocus) return;
      _active = controller;
      if (layout != null && layout != _layout && ref.read(settingsProvider).autoKeyboardLayout) {
        setState(() => _layout = layout);
      }
    });
  }

  @override
  void dispose() {
    _ru.dispose();
    _pl.dispose();
    _firstPerson.dispose();
    _secondPerson.dispose();
    _verbType.dispose();
    _masculine.dispose();
    _feminine.dispose();
    _neuter.dispose();
    _plural.dispose();
    _pronunciation.dispose();
    _ruFocus.dispose();
    _plFocus.dispose();
    _firstPersonFocus.dispose();
    _secondPersonFocus.dispose();
    _verbTypeFocus.dispose();
    _masculineFocus.dispose();
    _feminineFocus.dispose();
    _neuterFocus.dispose();
    _pluralFocus.dispose();
    _pronunciationFocus.dispose();
    super.dispose();
  }

  void _add() {
    final ruParts = _ru.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    final ruAccented = ruParts.isEmpty ? '' : ruParts.first;
    final ru = ruAccented.replaceAll(stressMark, '');
    final ruAlt = [for (final part in ruParts.skip(1)) part.replaceAll(stressMark, '')];
    final pl = _pl.text.trim().split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    if (ru.isEmpty || pl.isEmpty) {
      setState(() {
        _ruError = ru.isEmpty;
        _plError = pl.isEmpty;
      });
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(
          content: Text('Podaj słówko po rosyjsku i po polsku — te pola nie mogą być puste.'),
          duration: Duration(seconds: 3),
        ));
      return;
    }
    setState(() {
      _ruError = false;
      _plError = false;
    });
    final firstPerson = _firstPerson.text.trim();
    final secondPerson = _secondPerson.text.trim();
    final verbType = _verbType.text.trim();
    final masculine = _masculine.text.trim();
    final feminine = _feminine.text.trim();
    final neuter = _neuter.text.trim();
    final plural = _plural.text.trim();
    final pronunciation = _pronunciation.text.trim();
    final word = Word(
      id: 'w-${DateTime.now().microsecondsSinceEpoch}',
      ru: ru,
      ruAccented: ruAccented,
      ruAlt: ruAlt,
      pl: pl,
      category: _category,
      pronunciation: pronunciation.isEmpty ? null : pronunciation,
      firstPerson: _isVerb && firstPerson.isNotEmpty ? firstPerson : null,
      secondPerson: _isVerb && secondPerson.isNotEmpty ? secondPerson : null,
      verbType: _isVerb && verbType.isNotEmpty ? verbType : null,
      masculine: _isAdjective && masculine.isNotEmpty ? masculine : null,
      feminine: _isAdjective && feminine.isNotEmpty ? feminine : null,
      neuter: _isAdjective && neuter.isNotEmpty ? neuter : null,
      plural: _isAdjective && plural.isNotEmpty ? plural : null,
    );
    ref.read(customCoursesProvider.notifier).addWord(widget.courseId, word);
    _ru.clear();
    _pl.clear();
    _firstPerson.clear();
    _secondPerson.clear();
    _verbType.clear();
    _masculine.clear();
    _feminine.clear();
    _neuter.clear();
    _plural.clear();
    _pronunciation.clear();
    _ruFocus.requestFocus();
  }

  List<String> _watchCategories() =>
      ref.watch(coursesProvider).maybeWhen(data: gatherCategories, orElse: () => const <String>[]);

  Future<void> _editWord(Word word) async {
    final categories = ref.read(coursesProvider).maybeWhen(data: gatherCategories, orElse: () => const <String>[]);
    final edited = await showDialog<Word>(
      context: context,
      builder: (_) => _EditWordDialog(word: word, categories: categories),
    );
    if (edited != null) {
      ref.read(customCoursesProvider.notifier).updateWord(widget.courseId, word.id, edited);
    }
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
                padding: const EdgeInsets.fromLTRB(6, 4, 12, 4),
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
                            hasError: _ruError,
                            onChanged: (_) {
                              if (_ruError) setState(() => _ruError = false);
                            },
                            onSubmit: _add),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _Field(
                            label: 'Polski',
                            controller: _pl,
                            focusNode: _plFocus,
                            hasError: _plError,
                            onChanged: (_) {
                              if (_plError) setState(() => _plError = false);
                            },
                            onSubmit: _add),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 200,
                        child: _DropdownField(
                          value: _category,
                          categories: _watchCategories(),
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
                            label: '1. osoba (opcjonalnie)',
                            controller: _firstPerson,
                            focusNode: _firstPersonFocus,
                            transliterate: true,
                            enabled: _isVerb,
                            onSubmit: _add),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _Field(
                            label: '2. osoba — ё (opcjonalnie)',
                            controller: _secondPerson,
                            focusNode: _secondPersonFocus,
                            transliterate: true,
                            enabled: _isVerb,
                            onSubmit: _add),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 120,
                        child: _Field(
                            label: 'Typ (opcjonalnie)',
                            controller: _verbType,
                            focusNode: _verbTypeFocus,
                            enabled: _isVerb,
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
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: _Field(
                            label: 'Rodz. męski (opcj.)',
                            controller: _masculine,
                            focusNode: _masculineFocus,
                            transliterate: true,
                            enabled: _isAdjective,
                            onSubmit: _add),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _Field(
                            label: 'Rodz. żeński (opcj.)',
                            controller: _feminine,
                            focusNode: _feminineFocus,
                            transliterate: true,
                            enabled: _isAdjective,
                            onSubmit: _add),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _Field(
                            label: 'Rodz. nijaki (opcj.)',
                            controller: _neuter,
                            focusNode: _neuterFocus,
                            transliterate: true,
                            enabled: _isAdjective,
                            onSubmit: _add),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _Field(
                            label: 'L. mnoga (opcj.)',
                            controller: _plural,
                            focusNode: _pluralFocus,
                            transliterate: true,
                            enabled: _isAdjective,
                            onSubmit: _add),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Rosyjski oraz formy: pisz po łacińsku (q = akcent) lub klawiaturą niżej '
                    '(dolny rząd rosyjskiej klawiatury to samogłoski z akcentem). '
                    'Polski: warianty po przecinku. 2. osoba wypełniaj tylko przy przeskoku na ё (np. живёшь). '
                    'Pola czasownika są aktywne dla „czasowniki", pola rodzajów dla „przymiotniki". Wymowa i kategoria są opcjonalne.',
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
                      accentRow: true,
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
                              onPressed: () => _editWord(word),
                              icon: Icon(Icons.edit_outlined, size: 18, color: context.c.mutedForeground),
                              tooltip: 'Edytuj',
                              mouseCursor: SystemMouseCursors.click,
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

List<String> gatherCategories(List<Course> courses) {
  final set = <String>{};
  for (final course in courses) {
    for (final word in course.words) {
      if (word.category != null && word.category!.isNotEmpty) set.add(word.category!);
    }
  }
  final list = set.toList()..sort();
  return list;
}

class _EditWordDialog extends StatefulWidget {
  const _EditWordDialog({required this.word, required this.categories});

  final Word word;
  final List<String> categories;

  @override
  State<_EditWordDialog> createState() => _EditWordDialogState();
}

class _EditWordDialogState extends State<_EditWordDialog> {
  late final _ru = TextEditingController(text: [widget.word.ruAccented, ...widget.word.ruAlt].join(', '));
  late final _pl = TextEditingController(text: widget.word.pl.join(', '));
  late final _pronunciation = TextEditingController(text: widget.word.pronunciation ?? '');
  late final _firstPerson = TextEditingController(text: widget.word.firstPerson ?? '');
  late final _secondPerson = TextEditingController(text: widget.word.secondPerson ?? '');
  late final _verbType = TextEditingController(text: widget.word.verbType ?? '');
  late final _masculine = TextEditingController(text: widget.word.masculine ?? '');
  late final _feminine = TextEditingController(text: widget.word.feminine ?? '');
  late final _neuter = TextEditingController(text: widget.word.neuter ?? '');
  late final _plural = TextEditingController(text: widget.word.plural ?? '');
  late String? _category = widget.word.category;

  bool get _isVerb => _category == 'czasowniki';
  bool get _isAdjective => _category == 'przymiotniki';

  @override
  void dispose() {
    _ru.dispose();
    _pl.dispose();
    _pronunciation.dispose();
    _firstPerson.dispose();
    _secondPerson.dispose();
    _verbType.dispose();
    _masculine.dispose();
    _feminine.dispose();
    _neuter.dispose();
    _plural.dispose();
    super.dispose();
  }

  void _save() {
    final ruParts = _ru.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    final ruAccented = ruParts.isEmpty ? '' : ruParts.first;
    final ruAlt = [for (final part in ruParts.skip(1)) part.replaceAll('́', '')];
    final plRaw = _pl.text.trim();
    if (ruAccented.isEmpty || plRaw.isEmpty) return;
    final pl = plRaw.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    if (pl.isEmpty) return;
    final pronunciation = _pronunciation.text.trim();
    final firstPerson = _firstPerson.text.trim();
    final secondPerson = _secondPerson.text.trim();
    final verbType = _verbType.text.trim();
    final masculine = _masculine.text.trim();
    final feminine = _feminine.text.trim();
    final neuter = _neuter.text.trim();
    final plural = _plural.text.trim();
    Navigator.of(context).pop(Word(
      id: widget.word.id,
      ru: ruAccented.replaceAll('́', ''),
      ruAccented: ruAccented,
      ruAlt: ruAlt,
      pl: pl,
      category: _category,
      pronunciation: pronunciation.isEmpty ? null : pronunciation,
      firstPerson: _isVerb && firstPerson.isNotEmpty ? firstPerson : null,
      secondPerson: _isVerb && secondPerson.isNotEmpty ? secondPerson : null,
      verbType: _isVerb && verbType.isNotEmpty ? verbType : null,
      masculine: _isAdjective && masculine.isNotEmpty ? masculine : null,
      feminine: _isAdjective && feminine.isNotEmpty ? feminine : null,
      neuter: _isAdjective && neuter.isNotEmpty ? neuter : null,
      plural: _isAdjective && plural.isNotEmpty ? plural : null,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edytuj słówko'),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _Field(label: 'Rosyjski (warianty po przecinku)', controller: _ru, transliterate: true, onSubmit: _save),
              const SizedBox(height: 12),
              _Field(label: 'Polski (warianty po przecinku)', controller: _pl, onSubmit: _save),
              const SizedBox(height: 12),
              _DropdownField(
                value: _category,
                categories: widget.categories,
                onChanged: (value) => setState(() => _category = value),
              ),
              const SizedBox(height: 12),
              _Field(label: 'Wymowa (opcjonalnie)', controller: _pronunciation, onSubmit: _save),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: _Field(
                        label: '1. osoba (opcjonalnie)',
                        controller: _firstPerson,
                        transliterate: true,
                        enabled: _isVerb,
                        onSubmit: _save),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 120,
                    child: _Field(
                        label: 'Typ (opcjonalnie)', controller: _verbType, enabled: _isVerb, onSubmit: _save),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _Field(
                  label: '2. osoba — ё (opcjonalnie)',
                  controller: _secondPerson,
                  transliterate: true,
                  enabled: _isVerb,
                  onSubmit: _save),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: _Field(
                        label: 'Rodz. męski (opcj.)',
                        controller: _masculine,
                        transliterate: true,
                        enabled: _isAdjective,
                        onSubmit: _save),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _Field(
                        label: 'Rodz. żeński (opcj.)',
                        controller: _feminine,
                        transliterate: true,
                        enabled: _isAdjective,
                        onSubmit: _save),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: _Field(
                        label: 'Rodz. nijaki (opcj.)',
                        controller: _neuter,
                        transliterate: true,
                        enabled: _isAdjective,
                        onSubmit: _save),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _Field(
                        label: 'L. mnoga (opcj.)',
                        controller: _plural,
                        transliterate: true,
                        enabled: _isAdjective,
                        onSubmit: _save),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Anuluj')),
        FilledButton(onPressed: _save, child: const Text('Zapisz')),
      ],
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
    this.hasError = false,
    this.enabled = true,
    this.onChanged,
    required this.onSubmit,
  });

  final String label;
  final TextEditingController controller;
  final FocusNode? focusNode;
  final bool transliterate;
  final bool hasError;
  final bool enabled;
  final ValueChanged<String>? onChanged;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final borderColor = hasError ? context.c.destructive : context.c.inputBorder;
    final focusedColor = hasError ? context.c.destructive : context.c.ring;
    final disabledFg = context.c.mutedForeground.withValues(alpha: 0.4);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: enabled ? context.c.mutedForeground : disabledFg)),
        const SizedBox(height: 6),
        SizedBox(
          height: 40,
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            enabled: enabled,
            inputFormatters: transliterate ? [TransliterationFormatter()] : null,
            onChanged: onChanged,
            onSubmitted: (_) => onSubmit(),
            style: TextStyle(fontSize: 14, color: enabled ? context.c.foreground : disabledFg),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: focusedColor),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: context.c.inputBorder.withValues(alpha: 0.4)),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
