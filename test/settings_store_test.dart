import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:verba/data/settings_store.dart';

Future<ProviderContainer> _container([Map<String, Object> initial = const {}]) async {
  SharedPreferences.setMockInitialValues(initial);
  final prefs = await SharedPreferences.getInstance();
  return ProviderContainer(overrides: [prefsProvider.overrideWithValue(prefs)]);
}

void main() {
  test('new word order defaults to random', () async {
    final container = await _container();
    expect(container.read(settingsProvider).newWordOrder, NewWordOrder.random);
  });

  test('setNewWordOrder updates state and persists', () async {
    final container = await _container();
    container.read(settingsProvider.notifier).setNewWordOrder(NewWordOrder.inOrder);
    expect(container.read(settingsProvider).newWordOrder, NewWordOrder.inOrder);
  });

  test('loads persisted new word order', () async {
    final container = await _container({'settings.newWordOrder': 'inOrder'});
    expect(container.read(settingsProvider).newWordOrder, NewWordOrder.inOrder);
  });

  test('verb info defaults to on-hold', () async {
    final container = await _container();
    expect(container.read(settingsProvider).verbInfo, VerbInfoMode.onHold);
  });

  test('setVerbInfo updates and persists', () async {
    final container = await _container();
    container.read(settingsProvider.notifier).setVerbInfo(VerbInfoMode.always);
    expect(container.read(settingsProvider).verbInfo, VerbInfoMode.always);
  });

  test('loads persisted verb info', () async {
    final container = await _container({'settings.verbInfo': 'never'});
    expect(container.read(settingsProvider).verbInfo, VerbInfoMode.never);
  });

  test('auto keyboard layout defaults to on', () async {
    final container = await _container();
    expect(container.read(settingsProvider).autoKeyboardLayout, isTrue);
  });

  test('setAutoKeyboardLayout updates and persists', () async {
    final container = await _container();
    container.read(settingsProvider.notifier).setAutoKeyboardLayout(false);
    expect(container.read(settingsProvider).autoKeyboardLayout, isFalse);
  });

  test('loads persisted auto keyboard layout', () async {
    final container = await _container({'settings.autoKeyboardLayout': false});
    expect(container.read(settingsProvider).autoKeyboardLayout, isFalse);
  });

  test('empty-Enter-is-give-up defaults to on', () async {
    final container = await _container();
    expect(container.read(settingsProvider).enterEmptyIsGiveUp, isTrue);
  });

  test('setEnterEmptyIsGiveUp updates and persists', () async {
    final container = await _container();
    container.read(settingsProvider.notifier).setEnterEmptyIsGiveUp(false);
    expect(container.read(settingsProvider).enterEmptyIsGiveUp, isFalse);
  });

  test('loads persisted empty-Enter-is-give-up', () async {
    final container = await _container({'settings.enterEmptyIsGiveUp': false});
    expect(container.read(settingsProvider).enterEmptyIsGiveUp, isFalse);
  });

  test('polish speaker defaults to off', () async {
    final container = await _container();
    expect(container.read(settingsProvider).showPolishSpeaker, isFalse);
  });

  test('setShowPolishSpeaker updates and persists', () async {
    final container = await _container();
    container.read(settingsProvider.notifier).setShowPolishSpeaker(true);
    expect(container.read(settingsProvider).showPolishSpeaker, isTrue);
  });

  test('loads persisted polish speaker', () async {
    final container = await _container({'settings.showPolishSpeaker': true});
    expect(container.read(settingsProvider).showPolishSpeaker, isTrue);
  });

  test('polish autoplay defaults to off', () async {
    final container = await _container();
    expect(container.read(settingsProvider).autoplayPolish, isFalse);
  });

  test('setAutoplayPolish updates and persists', () async {
    final container = await _container();
    container.read(settingsProvider.notifier).setAutoplayPolish(true);
    expect(container.read(settingsProvider).autoplayPolish, isTrue);
  });

  test('loads persisted polish autoplay', () async {
    final container = await _container({'settings.autoplayPolish': true});
    expect(container.read(settingsProvider).autoplayPolish, isTrue);
  });

  test('russian speaker defaults to on', () async {
    final container = await _container();
    expect(container.read(settingsProvider).showRussianSpeaker, isTrue);
  });

  test('setShowRussianSpeaker updates and persists', () async {
    final container = await _container();
    container.read(settingsProvider.notifier).setShowRussianSpeaker(false);
    expect(container.read(settingsProvider).showRussianSpeaker, isFalse);
  });

  test('loads persisted russian speaker', () async {
    final container = await _container({'settings.showRussianSpeaker': false});
    expect(container.read(settingsProvider).showRussianSpeaker, isFalse);
  });

  test('polish speech tempo defaults to normal', () async {
    final container = await _container();
    expect(container.read(settingsProvider).slowSpeechPolish, isFalse);
  });

  test('setSlowSpeechPolish updates and persists', () async {
    final container = await _container();
    container.read(settingsProvider.notifier).setSlowSpeechPolish(true);
    expect(container.read(settingsProvider).slowSpeechPolish, isTrue);
  });

  test('loads persisted polish speech tempo', () async {
    final container = await _container({'settings.slowSpeechPolish': true});
    expect(container.read(settingsProvider).slowSpeechPolish, isTrue);
  });
}
