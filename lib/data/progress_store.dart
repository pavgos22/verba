import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'settings_store.dart';

enum WordStatus { fresh, learning, mastered }

class WordProgress {
  const WordProgress({
    required this.box,
    required this.lastReviewMs,
    required this.firstLearnedMs,
    required this.correct,
    required this.wrong,
    required this.almost,
    required this.streak,
  });

  final int box;
  final int lastReviewMs;
  final int firstLearnedMs;
  final int correct;
  final int wrong;
  final int almost;
  final int streak;

  double get struggle => wrong + 0.5 * almost;

  Map<String, dynamic> toJson() =>
      {'b': box, 'l': lastReviewMs, 'f': firstLearnedMs, 'c': correct, 'w': wrong, 'a': almost, 's': streak};

  factory WordProgress.fromJson(Map<String, dynamic> json) => WordProgress(
        box: json['b'] as int,
        lastReviewMs: json['l'] as int,
        firstLearnedMs: json['f'] as int? ?? json['l'] as int,
        correct: json['c'] as int,
        wrong: json['w'] as int,
        almost: json['a'] as int? ?? 0,
        streak: json['s'] as int? ?? 0,
      );
}

class ProgressState {
  const ProgressState({required this.words, required this.streak, required this.lastActiveDay, required this.sessions});

  final Map<String, WordProgress> words;
  final int streak;
  final String lastActiveDay;
  final int sessions;

  WordStatus statusOf(String wordId) {
    final progress = words[wordId];
    if (progress == null) return WordStatus.fresh;
    return progress.box >= 4 ? WordStatus.mastered : WordStatus.learning;
  }

  int countByStatus(Iterable<String> wordIds, WordStatus status) {
    return wordIds.where((id) => statusOf(id) == status).length;
  }

  List<String> newestStarted(Iterable<String> wordIds) {
    final ids = wordIds.where((id) => words.containsKey(id)).toList();
    ids.sort((a, b) => words[b]!.firstLearnedMs.compareTo(words[a]!.firstLearnedMs));
    return ids;
  }

  static const hardestHealStreak = 3;

  List<String> hardestStarted(Iterable<String> wordIds) {
    final ids = wordIds
        .where((id) =>
            words.containsKey(id) &&
            statusOf(id) != WordStatus.mastered &&
            words[id]!.struggle > 0 &&
            words[id]!.streak < hardestHealStreak)
        .toList();
    ids.sort((a, b) => words[b]!.struggle.compareTo(words[a]!.struggle));
    return ids;
  }
}

class ProgressNotifier extends Notifier<ProgressState> {
  static const reviewIntervalsDays = [0, 1, 2, 4, 7, 15];

  @override
  ProgressState build() {
    final prefs = ref.read(prefsProvider);
    final raw = prefs.getString('progress.words');
    final words = <String, WordProgress>{};
    if (raw != null) {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      decoded.forEach((key, value) {
        words[key] = WordProgress.fromJson(value as Map<String, dynamic>);
      });
    }
    return ProgressState(
      words: words,
      streak: prefs.getInt('progress.streak') ?? 0,
      lastActiveDay: prefs.getString('progress.lastActiveDay') ?? '',
      sessions: prefs.getInt('progress.sessions') ?? 0,
    );
  }

  static String dayKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  bool isDue(String wordId, DateTime now) {
    final progress = state.words[wordId];
    if (progress == null) return false;
    final last = DateTime.fromMillisecondsSinceEpoch(progress.lastReviewMs);
    final lastDay = DateTime(last.year, last.month, last.day);
    final today = DateTime(now.year, now.month, now.day);
    final interval = reviewIntervalsDays[progress.box.clamp(0, reviewIntervalsDays.length - 1)];
    return today.difference(lastDay).inDays >= interval;
  }

  void recordAnswer(String wordId, bool correct, {bool almost = false, DateTime? now}) {
    final at = now ?? DateTime.now();
    final previous = state.words[wordId];
    final firstLearned = previous?.firstLearnedMs ?? at.millisecondsSinceEpoch;
    final cleanCorrect = correct && !almost;
    final WordProgress updated;
    if (correct) {
      final advance = previous == null || isDue(wordId, at);
      updated = WordProgress(
        box: advance ? ((previous?.box ?? 0) + 1).clamp(1, 5) : previous.box,
        lastReviewMs: advance ? at.millisecondsSinceEpoch : previous.lastReviewMs,
        firstLearnedMs: firstLearned,
        correct: (previous?.correct ?? 0) + 1,
        wrong: previous?.wrong ?? 0,
        almost: (previous?.almost ?? 0) + (almost ? 1 : 0),
        streak: cleanCorrect ? (previous?.streak ?? 0) + 1 : 0,
      );
    } else {
      updated = WordProgress(
        box: 1,
        lastReviewMs: at.millisecondsSinceEpoch,
        firstLearnedMs: firstLearned,
        correct: previous?.correct ?? 0,
        wrong: (previous?.wrong ?? 0) + 1,
        almost: previous?.almost ?? 0,
        streak: 0,
      );
    }
    state = ProgressState(
      words: {...state.words, wordId: updated},
      streak: state.streak,
      lastActiveDay: state.lastActiveDay,
      sessions: state.sessions,
    );
    _persist();
  }

  void finishSession() {
    final today = dayKey(DateTime.now());
    if (state.lastActiveDay == today) {
      state = ProgressState(
        words: state.words,
        streak: state.streak == 0 ? 1 : state.streak,
        lastActiveDay: today,
        sessions: state.sessions + 1,
      );
    } else {
      final yesterday = dayKey(DateTime.now().subtract(const Duration(days: 1)));
      final streak = state.lastActiveDay == yesterday ? state.streak + 1 : 1;
      state = ProgressState(
        words: state.words,
        streak: streak,
        lastActiveDay: today,
        sessions: state.sessions + 1,
      );
    }
    _persist();
  }

  void resetAll() {
    state = const ProgressState(words: {}, streak: 0, lastActiveDay: '', sessions: 0);
    _persist();
  }

  void _persist() {
    final prefs = ref.read(prefsProvider);
    prefs.setString('progress.words', jsonEncode({for (final e in state.words.entries) e.key: e.value.toJson()}));
    prefs.setInt('progress.streak', state.streak);
    prefs.setString('progress.lastActiveDay', state.lastActiveDay);
    prefs.setInt('progress.sessions', state.sessions);
  }
}

final progressProvider = NotifierProvider<ProgressNotifier, ProgressState>(ProgressNotifier.new);
