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
}
