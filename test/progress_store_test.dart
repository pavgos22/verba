import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:verba/data/progress_store.dart';
import 'package:verba/data/settings_store.dart';

Future<ProviderContainer> createContainer() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  return ProviderContainer(overrides: [prefsProvider.overrideWithValue(prefs)]);
}

void main() {
  test('new word advances through boxes on due reviews', () async {
    final container = await createContainer();
    final notifier = container.read(progressProvider.notifier);

    expect(container.read(progressProvider).statusOf('hello'), WordStatus.fresh);

    notifier.recordAnswer('hello', true, now: DateTime(2026, 1, 1));
    expect(container.read(progressProvider).statusOf('hello'), WordStatus.learning);
    expect(container.read(progressProvider).words['hello']!.box, 1);

    notifier.recordAnswer('hello', true, now: DateTime(2026, 1, 2));
    notifier.recordAnswer('hello', true, now: DateTime(2026, 1, 4));
    notifier.recordAnswer('hello', true, now: DateTime(2026, 1, 8));
    expect(container.read(progressProvider).words['hello']!.box, 4);
    expect(container.read(progressProvider).statusOf('hello'), WordStatus.mastered);
  });

  test('correct answer before due date does not advance the box', () async {
    final container = await createContainer();
    final notifier = container.read(progressProvider.notifier);

    notifier.recordAnswer('hello', true, now: DateTime(2026, 1, 1));
    notifier.recordAnswer('hello', true, now: DateTime(2026, 1, 1));
    notifier.recordAnswer('hello', true, now: DateTime(2026, 1, 1));
    expect(container.read(progressProvider).words['hello']!.box, 1);
    expect(container.read(progressProvider).words['hello']!.correct, 3);
  });

  test('wrong answer resets box to one', () async {
    final container = await createContainer();
    final notifier = container.read(progressProvider.notifier);

    notifier.recordAnswer('hello', true, now: DateTime(2026, 1, 1));
    notifier.recordAnswer('hello', true, now: DateTime(2026, 1, 2));
    notifier.recordAnswer('hello', true, now: DateTime(2026, 1, 4));
    notifier.recordAnswer('hello', true, now: DateTime(2026, 1, 8));
    expect(container.read(progressProvider).words['hello']!.box, 4);

    notifier.recordAnswer('hello', false, now: DateTime(2026, 1, 9));
    expect(container.read(progressProvider).words['hello']!.box, 1);
    expect(container.read(progressProvider).statusOf('hello'), WordStatus.learning);
  });

  test('word reviewed today is not due', () async {
    final container = await createContainer();
    final notifier = container.read(progressProvider.notifier);

    notifier.recordAnswer('hello', true);
    expect(notifier.isDue('hello', DateTime.now()), isFalse);
    expect(notifier.isDue('hello', DateTime.now().add(const Duration(days: 1))), isTrue);
  });

  test('finish session updates streak once per day', () async {
    final container = await createContainer();
    final notifier = container.read(progressProvider.notifier);

    notifier.finishSession();
    expect(container.read(progressProvider).streak, 1);
    expect(container.read(progressProvider).sessions, 1);

    notifier.finishSession();
    expect(container.read(progressProvider).streak, 1);
    expect(container.read(progressProvider).sessions, 2);
  });

  test('almost answers count at half weight and keep advancing the box', () async {
    final container = await createContainer();
    final notifier = container.read(progressProvider.notifier);

    notifier.recordAnswer('x', true, now: DateTime(2026, 1, 1));
    notifier.recordAnswer('x', true, almost: true, now: DateTime(2026, 1, 2));

    final p = container.read(progressProvider).words['x']!;
    expect(p.box, 2);
    expect(p.almost, 1);
    expect(p.wrong, 0);
    expect(p.struggle, 0.5);
  });

  test('first learned timestamp is set once and stays stable', () async {
    final container = await createContainer();
    final notifier = container.read(progressProvider.notifier);

    notifier.recordAnswer('x', true, now: DateTime(2026, 1, 1));
    final first = container.read(progressProvider).words['x']!.firstLearnedMs;
    notifier.recordAnswer('x', true, now: DateTime(2026, 1, 20));
    expect(container.read(progressProvider).words['x']!.firstLearnedMs, first);
  });

  test('newestStarted orders by first learned, most recent first', () async {
    final container = await createContainer();
    final notifier = container.read(progressProvider.notifier);

    notifier.recordAnswer('old', true, now: DateTime(2026, 1, 1));
    notifier.recordAnswer('mid', true, now: DateTime(2026, 1, 5));
    notifier.recordAnswer('new', true, now: DateTime(2026, 1, 10));
    notifier.recordAnswer('old', true, now: DateTime(2026, 1, 20));

    expect(container.read(progressProvider).newestStarted(['old', 'mid', 'new']), ['new', 'mid', 'old']);
  });

  test('hardestStarted ranks by struggle, skips mastered and unmissed', () async {
    final container = await createContainer();
    final notifier = container.read(progressProvider.notifier);

    notifier.recordAnswer('a', false, now: DateTime(2026, 1, 1));
    notifier.recordAnswer('a', false, now: DateTime(2026, 1, 2));

    notifier.recordAnswer('b', false, now: DateTime(2026, 1, 1));
    notifier.recordAnswer('b', true, almost: true, now: DateTime(2026, 1, 2));

    notifier.recordAnswer('c', true, now: DateTime(2026, 1, 1));

    notifier.recordAnswer('d', false, now: DateTime(2026, 1, 1));
    notifier.recordAnswer('d', true, now: DateTime(2026, 1, 2));
    notifier.recordAnswer('d', true, now: DateTime(2026, 1, 4));
    notifier.recordAnswer('d', true, now: DateTime(2026, 1, 8));

    final progress = container.read(progressProvider);
    expect(progress.statusOf('d'), WordStatus.mastered);
    expect(progress.hardestStarted(['a', 'b', 'c', 'd']), ['a', 'b']);
  });

  test('hardestOfNewest ranks only inside the recent window', () async {
    final container = await createContainer();
    final notifier = container.read(progressProvider.notifier);

    // learned long ago, and the hardest of them all
    notifier.recordAnswer('old', false, now: DateTime(2026, 1, 1));
    notifier.recordAnswer('old', false, now: DateTime(2026, 1, 2));
    notifier.recordAnswer('old', false, now: DateTime(2026, 1, 3));

    notifier.recordAnswer('r1', false, now: DateTime(2026, 1, 10));
    notifier.recordAnswer('r2', false, now: DateTime(2026, 1, 11));
    notifier.recordAnswer('r2', false, now: DateTime(2026, 1, 12));
    notifier.recordAnswer('r3', true, now: DateTime(2026, 1, 13));
    notifier.recordAnswer('r4', false, now: DateTime(2026, 1, 14));

    final progress = container.read(progressProvider);
    const ids = ['old', 'r1', 'r2', 'r3', 'r4'];

    expect(progress.hardestStarted(ids).first, 'old');
    // count 1 means a window of the 3 newest (r4, r3, r2); r3 was never missed so it drops out
    expect(progress.hardestOfNewest(ids, 1), ['r2', 'r4']);
  });

  test('a hard word heals out after a streak of clean correct answers', () async {
    final container = await createContainer();
    final notifier = container.read(progressProvider.notifier);
    final day = DateTime(2026, 1, 1);

    notifier.recordAnswer('h', false, now: day);
    notifier.recordAnswer('h', false, now: day);
    expect(container.read(progressProvider).hardestStarted(['h']), ['h']);

    notifier.recordAnswer('h', true, now: day);
    notifier.recordAnswer('h', true, now: day);
    notifier.recordAnswer('h', true, now: day);
    expect(container.read(progressProvider).hardestStarted(['h']), isEmpty);

    notifier.recordAnswer('h', false, now: day);
    expect(container.read(progressProvider).hardestStarted(['h']), ['h']);
  });

  test('an almost answer breaks the healing streak', () async {
    final container = await createContainer();
    final notifier = container.read(progressProvider.notifier);
    final day = DateTime(2026, 1, 1);

    notifier.recordAnswer('h', false, now: day);
    notifier.recordAnswer('h', true, now: day);
    notifier.recordAnswer('h', true, now: day);
    notifier.recordAnswer('h', true, almost: true, now: day);
    notifier.recordAnswer('h', true, now: day);

    expect(container.read(progressProvider).words['h']!.streak, 1);
    expect(container.read(progressProvider).hardestStarted(['h']), ['h']);
  });

  test('points equal streak minus struggle', () async {
    final container = await createContainer();
    final notifier = container.read(progressProvider.notifier);
    final day = DateTime(2026, 1, 1);

    notifier.recordAnswer('x', false, now: day);
    notifier.recordAnswer('x', true, now: day);
    notifier.recordAnswer('x', true, now: day);
    expect(container.read(progressProvider).words['x']!.points, 1.0);

    notifier.recordAnswer('y', true, almost: true, now: day);
    expect(container.read(progressProvider).words['y']!.points, -0.5);
  });

  test('reset clears everything', () async {
    final container = await createContainer();
    final notifier = container.read(progressProvider.notifier);

    notifier.recordAnswer('hello', true);
    notifier.finishSession();
    notifier.resetAll();

    final state = container.read(progressProvider);
    expect(state.words, isEmpty);
    expect(state.streak, 0);
    expect(state.sessions, 0);
  });
}
