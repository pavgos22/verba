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
