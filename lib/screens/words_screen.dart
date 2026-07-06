import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/progress_store.dart';
import '../data/word.dart';
import '../data/words_repository.dart';
import '../theme/app_colors.dart';
import '../widgets/common.dart';

class WordsScreen extends ConsumerStatefulWidget {
  const WordsScreen({super.key});

  @override
  ConsumerState<WordsScreen> createState() => _WordsScreenState();
}

class _WordsScreenState extends ConsumerState<WordsScreen> {
  String _query = '';
  String? _category;

  @override
  Widget build(BuildContext context) {
    final wordsAsync = ref.watch(wordsProvider);
    final progress = ref.watch(progressProvider);
    return wordsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => const Center(child: Text('Nie udało się wczytać kursu')),
      data: (words) {
        final query = _query.trim().toLowerCase();
        final filtered = words.where((w) {
          if (_category != null && w.category != _category) return false;
          if (query.isEmpty) return true;
          return w.ru.contains(query) || w.pl.any((p) => p.toLowerCase().contains(query));
        }).toList();
        final mastered = words.where((w) => progress.statusOf(w.id) == WordStatus.mastered).length;

        return Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Słówka', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: context.c.foreground)),
              const SizedBox(height: 4),
              Text('${words.length} słów w kursie · $mastered opanowanych',
                  style: TextStyle(fontSize: 14, color: context.c.mutedForeground)),
              const SizedBox(height: 20),
              Row(
                children: [
                  SizedBox(
                    width: 280,
                    height: 40,
                    child: TextField(
                      onChanged: (value) => setState(() => _query = value),
                      style: TextStyle(fontSize: 14, color: context.c.foreground),
                      decoration: InputDecoration(
                        hintText: 'Szukaj słówka...',
                        hintStyle: TextStyle(fontSize: 14, color: context.c.mutedForeground),
                        prefixIcon: Icon(Icons.search, size: 18, color: context.c.mutedForeground),
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
                  const SizedBox(width: 12),
                  _FilterChip(
                    label: 'Wszystkie (${words.length})',
                    active: _category == null,
                    onTap: () => setState(() => _category = null),
                  ),
                  for (final category in wordCategories) ...[
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: category,
                      active: _category == category,
                      onTap: () => setState(() => _category = category),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: context.c.card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: context.c.border),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      _TableRow(
                        height: 44,
                        cells: [
                          _HeaderCell('Słowo'),
                          _HeaderCell('Tłumaczenie'),
                          _HeaderCell('Kategoria'),
                          _HeaderCell('Status'),
                          _HeaderCell('Audio'),
                        ],
                      ),
                      Expanded(
                        child: filtered.isEmpty
                            ? Center(
                                child: Text('Brak wyników',
                                    style: TextStyle(fontSize: 14, color: context.c.mutedForeground)),
                              )
                            : ListView.builder(
                                itemCount: filtered.length,
                                itemBuilder: (context, index) =>
                                    _WordRow(word: filtered[index], status: progress.statusOf(filtered[index].id)),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.active, required this.onTap});

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? context.c.primary : context.c.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: active ? context.c.primary : context.c.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: active ? context.c.primaryForeground : context.c.mutedForeground,
            ),
          ),
        ),
      ),
    );
  }
}

class _TableRow extends StatelessWidget {
  const _TableRow({required this.cells, required this.height, this.withBorder = false});

  final List<Widget> cells;
  final double height;
  final bool withBorder;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: withBorder ? BoxDecoration(border: Border(top: BorderSide(color: context.c.border))) : null,
      child: Row(
        children: [
          SizedBox(width: 220, child: cells[0]),
          const SizedBox(width: 16),
          SizedBox(width: 220, child: cells[1]),
          const SizedBox(width: 16),
          SizedBox(width: 170, child: cells[2]),
          const SizedBox(width: 16),
          SizedBox(width: 150, child: cells[3]),
          const SizedBox(width: 16),
          Expanded(child: cells[4]),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: context.c.mutedForeground)),
    );
  }
}

class _WordRow extends StatelessWidget {
  const _WordRow({required this.word, required this.status});

  final Word word;
  final WordStatus status;

  @override
  Widget build(BuildContext context) {
    final (statusLabel, statusColor) = switch (status) {
      WordStatus.fresh => ('Nowe', context.c.mutedForeground),
      WordStatus.learning => ('W nauce', context.c.foreground),
      WordStatus.mastered => ('Opanowane', context.c.success),
    };
    return _TableRow(
      height: 52,
      withBorder: true,
      cells: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(word.ruAccented,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: context.c.foreground)),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(word.pl.join(', '), style: TextStyle(fontSize: 14, color: context.c.foreground)),
        ),
        Align(alignment: Alignment.centerLeft, child: Row(children: [AppBadge(label: word.category)])),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(statusLabel, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: statusColor)),
        ),
        Align(alignment: Alignment.centerLeft, child: SpeakerButton(text: word.ru, size: 32)),
      ],
    );
  }
}
