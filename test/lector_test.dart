import 'package:flutter_test/flutter_test.dart';
import 'package:verba/services/audio_service.dart';

void main() {
  test('lectorKey matches the FNV-1a generator', () {
    expect(lectorKey('привет'), '1bd8a912173e871f');
    expect(lectorKey('спасибо'), '19e9fea1d5faff19');
    expect(lectorKey('вода'), '91edba0df36e1fad');
  });

  test('lectorKey is stable and 16 hex chars', () {
    final key = lectorKey('вода');
    expect(key.length, 16);
    expect(RegExp(r'^[0-9a-f]{16}$').hasMatch(key), isTrue);
  });
}
