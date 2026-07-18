import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:verba/services/translation_service.dart';

http.Response _deeplOk(String text) =>
    http.Response.bytes(utf8.encode(jsonEncode({'translations': [{'text': text}]})), 200);

http.Response _mmOk(String text) => http.Response.bytes(
    utf8.encode(jsonEncode({'responseData': {'translatedText': text}, 'responseStatus': 200})), 200);

void main() {
  test('with a key translates via DeepL free host and caches repeats', () async {
    var calls = 0;
    final client = MockClient((req) async {
      calls++;
      expect(req.url.host, 'api-free.deepl.com');
      expect(req.headers['Authorization'], 'DeepL-Auth-Key test-key:fx');
      expect(req.bodyFields['source_lang'], 'RU');
      expect(req.bodyFields['target_lang'], 'PL');
      return _deeplOk('cześć');
    });
    final service = TranslationService('test-key:fx', client: client);

    expect(await service.translate('привет', from: 'RU', to: 'PL'), 'cześć');
    expect(await service.translate('привет', from: 'RU', to: 'PL'), 'cześć');
    expect(calls, 1, reason: 'the second identical request is served from cache');
  });

  test('a pro key uses the paid DeepL host', () async {
    final client = MockClient((req) async {
      expect(req.url.host, 'api.deepl.com');
      return _deeplOk('ok');
    });
    await TranslationService('pro-key', client: client).translate('привет', from: 'RU', to: 'PL');
  });

  test('without a key translates via MyMemory (keyless)', () async {
    final client = MockClient((req) async {
      expect(req.method, 'GET');
      expect(req.url.host, 'api.mymemory.translated.net');
      expect(req.url.queryParameters['langpair'], 'ru|pl');
      expect(req.url.queryParameters['q'], 'привет');
      return _mmOk('cześć');
    });
    final service = TranslationService('', client: client);
    expect(service.provider, 'MyMemory');
    expect(await service.translate('привет', from: 'RU', to: 'PL'), 'cześć');
  });

  test('MyMemory decodes html entities in the result', () async {
    final service = TranslationService('', client: MockClient((_) async => _mmOk('to&#39;jest &quot;test&quot;')));
    expect(await service.translate('x', from: 'PL', to: 'RU'), 'to\'jest "test"');
  });

  test('MyMemory quota warning throws a friendly message', () async {
    final client = MockClient((_) async => http.Response.bytes(
        utf8.encode(jsonEncode({
          'responseData': {'translatedText': 'MYMEMORY WARNING: YOU USED ALL AVAILABLE FREE TRANSLATIONS FOR TODAY.'},
          'responseStatus': 403,
        })),
        200));
    final service = TranslationService('', client: client);
    expect(
      () => service.translate('привет', from: 'RU', to: 'PL'),
      throwsA(isA<TranslationException>()),
    );
  });

  test('empty input returns empty without hitting any API', () async {
    var calls = 0;
    final client = MockClient((_) async {
      calls++;
      return _mmOk('x');
    });
    expect(await TranslationService('', client: client).translate('   ', from: 'RU', to: 'PL'), '');
    expect(calls, 0);
  });

  test('403 from DeepL maps to an invalid-key message', () async {
    final service = TranslationService('bad:fx', client: MockClient((_) async => http.Response('', 403)));
    expect(
      () => service.translate('привет', from: 'RU', to: 'PL'),
      throwsA(predicate((e) => e is TranslationException && e.message.contains('Nieprawidłowy'))),
    );
  });
}
