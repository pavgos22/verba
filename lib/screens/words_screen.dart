import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/progress_store.dart';
import '../data/settings_store.dart';
import '../data/word.dart';
import '../data/words_repository.dart';
import '../theme/app_colors.dart';
import '../widgets/accented_text.dart';
import '../widgets/common.dart';

enum _WordFilter { all, fresh, learning, mastered, hard }

class WordsScreen extends ConsumerStatefulWidget {
  const WordsScreen({super.key});

  @override
  ConsumerState<WordsScreen> createState() => _WordsScreenState();
}

class _WordsScreenState extends ConsumerState<WordsScreen> {
  String _query = '';
  String? _category;
  _WordFilter _filter = _WordFilter.all;

  @override
  Widget build(BuildContext context) {
    final wordsAsync = ref.watch(wordsProvider);
    final progress = ref.watch(progressProvider);
    final showPoints = ref.watch(settingsProvider.select((s) => s.showWordPoints));
    return wordsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => const Center(child: Text('Nie udało się wczytać kursu')),
      data: (words) {
        final query = _query.trim().toLowerCase();
        final categories = <String>{
          for (final w in words)
            if (w.category != null) w.category!,
        }.toList();
        final hardIds = progress.hardestStarted(words.map((w) => w.id)).toSet();
        bool matchesFilter(Word w) => switch (_filter) {
              _WordFilter.all => true,
              _WordFilter.fresh => progress.statusOf(w.id) == WordStatus.fresh,
              _WordFilter.learning => progress.statusOf(w.id) == WordStatus.learning,
              _WordFilter.mastered => progress.statusOf(w.id) == WordStatus.mastered,
              _WordFilter.hard => hardIds.contains(w.id),
            };
        final filtered = words.where((w) {
          if (!matchesFilter(w)) return false;
          if (_category != null && w.category != _category) return false;
          if (query.isEmpty) return true;
          return w.ru.contains(query) || w.pl.any((p) => p.toLowerCase().contains(query));
        }).toList();
        final total = words.length;
        final mastered = words.where((w) => progress.statusOf(w.id) == WordStatus.mastered).length;
        final learning = words.where((w) => progress.statusOf(w.id) == WordStatus.learning).length;
        final fresh = total - learning - mastered;
        String pct(int n) => total == 0 ? '0%' : '${(n * 100 / total).round()}% kursu';

        return Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Słówka', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: context.c.foreground)),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _CountTile(
                      icon: Icons.menu_book_outlined,
                      label: 'W kursie',
                      value: '$total',
                      sub: 'wszystkich słów',
                      fraction: 1,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _CountTile(
                      icon: Icons.school_outlined,
                      label: 'W nauce',
                      value: '$learning',
                      sub: pct(learning),
                      fraction: total == 0 ? 0 : learning / total,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _CountTile(
                      icon: Icons.check_circle_outline,
                      label: 'Opanowane',
                      value: '$mastered',
                      sub: pct(mastered),
                      fraction: total == 0 ? 0 : mastered / total,
                      accent: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _FilterChip(
                    label: 'Wszystkie',
                    active: _filter == _WordFilter.all,
                    onTap: () => setState(() => _filter = _WordFilter.all),
                  ),
                  _FilterChip(
                    label: 'Nowe ($fresh)',
                    active: _filter == _WordFilter.fresh,
                    onTap: () => setState(() => _filter = _WordFilter.fresh),
                  ),
                  _FilterChip(
                    label: 'W nauce ($learning)',
                    active: _filter == _WordFilter.learning,
                    onTap: () => setState(() => _filter = _WordFilter.learning),
                  ),
                  _FilterChip(
                    label: 'Opanowane ($mastered)',
                    active: _filter == _WordFilter.mastered,
                    onTap: () => setState(() => _filter = _WordFilter.mastered),
                  ),
                  _FilterChip(
                    label: 'Sprawiające trudności (${hardIds.length})',
                    active: _filter == _WordFilter.hard,
                    onTap: () => setState(() => _filter = _WordFilter.hard),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
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
                  if (categories.isNotEmpty) ...[
                    _FilterChip(
                      label: 'Wszystkie (${words.length})',
                      active: _category == null,
                      onTap: () => setState(() => _category = null),
                    ),
                    for (final category in categories)
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
                        points: showPoints ? const _HeaderCell('Punkty') : null,
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
                                itemBuilder: (context, index) => _WordRow(
                                  word: filtered[index],
                                  status: progress.statusOf(filtered[index].id),
                                  points: showPoints ? (progress.words[filtered[index].id]?.points ?? 0) : null,
                                ),
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

class _CountTile extends StatelessWidget {
  const _CountTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.sub,
    required this.fraction,
    this.accent = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final String sub;
  final double fraction;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final barColor = accent ? context.c.success : context.c.primary;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: context.c.mutedForeground),
              const SizedBox(width: 8),
              Text(label,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: context.c.mutedForeground)),
            ],
          ),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  color: accent ? context.c.success : context.c.foreground)),
          const SizedBox(height: 4),
          Text(sub, style: TextStyle(fontSize: 12, color: context.c.mutedForeground)),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: fraction.clamp(0.0, 1.0),
              minHeight: 5,
              backgroundColor: context.c.muted,
              color: barColor,
            ),
          ),
        ],
      ),
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
        mouseCursor: SystemMouseCursors.click,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
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
  const _TableRow({required this.cells, required this.height, this.points, this.withBorder = false});

  final List<Widget> cells;
  final Widget? points;
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
          Expanded(flex: 4, child: cells[0]),
          const SizedBox(width: 16),
          Expanded(flex: 4, child: cells[1]),
          const SizedBox(width: 16),
          Expanded(flex: 3, child: cells[2]),
          const SizedBox(width: 16),
          Expanded(flex: 2, child: cells[3]),
          const SizedBox(width: 16),
          if (points != null) ...[
            SizedBox(width: 56, child: points!),
            const SizedBox(width: 16),
          ],
          SizedBox(width: 56, child: cells[4]),
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
  const _WordRow({required this.word, required this.status, this.points});

  final Word word;
  final WordStatus status;
  final double? points;

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
      points: points == null ? null : _PointsCell(points!),
      cells: [
        Align(
          alignment: Alignment.centerLeft,
          child: AccentedText(word.ruAccented,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: context.c.foreground)),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(word.pl.join(', '),
              overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14, color: context.c.foreground)),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: word.category != null
              ? AppBadge(label: word.category!)
              : Text('—', style: TextStyle(fontSize: 13, color: context.c.mutedForeground)),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(statusLabel,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: statusColor)),
        ),
        Align(alignment: Alignment.centerLeft, child: SpeakerButton(text: word.ru, size: 32)),
      ],
    );
  }
}

class _PointsCell extends StatelessWidget {
  const _PointsCell(this.value);

  final double value;

  @override
  Widget build(BuildContext context) {
    final color = value < 0
        ? context.c.destructive
        : value > 0
            ? context.c.success
            : context.c.foreground;
    final text = value.toStringAsFixed(1);
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text.endsWith('.0') ? text.substring(0, text.length - 2) : text,
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}
