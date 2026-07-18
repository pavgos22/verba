import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../data/settings_store.dart';

class TranslationException implements Exception {
  const TranslationException(this.message);

  final String message;

  @override
  String toString() => message;
}

class TranslationService {
  TranslationService(this.apiKey, {http.Client? client}) : _client = client ?? http.Client();

  final String apiKey;
  final http.Client _client;
  final Map<String, String> _cache = {};

  bool get hasKey => apiKey.trim().isNotEmpty;

  String get provider => hasKey ? 'DeepL' : 'MyMemory';

  Future<String> translate(String text, {required String from, required String to}) async {
    final source = text.trim();
    if (source.isEmpty) return '';
    final cacheKey = '$provider>$from>$to>$source';
    final cached = _cache[cacheKey];
    if (cached != null) return cached;
    final result = hasKey ? await _deepl(source, from, to) : await _myMemory(source, from, to);
    _cache[cacheKey] = result;
    return result;
  }

  Future<String> _deepl(String text, String from, String to) async {
    final key = apiKey.trim();
    final host = key.endsWith(':fx') ? 'api-free.deepl.com' : 'api.deepl.com';
    final http.Response response;
    try {
      response = await _client.post(
        Uri.https(host, '/v2/translate'),
        headers: {'Authorization': 'DeepL-Auth-Key $key'},
        body: {'text': text, 'source_lang': from, 'target_lang': to},
      );
    } catch (_) {
      throw const TranslationException('Brak połączenia — sprawdź internet.');
    }
    switch (response.statusCode) {
      case 200:
        break;
      case 401:
      case 403:
        throw const TranslationException('Nieprawidłowy klucz DeepL.');
      case 429:
        throw const TranslationException('Za dużo zapytań — spróbuj za chwilę.');
      case 456:
        throw const TranslationException('Wyczerpany miesięczny limit DeepL.');
      default:
        throw TranslationException('Błąd tłumaczenia (kod ${response.statusCode}).');
    }
    final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    final translations = data['translations'] as List<dynamic>? ?? const [];
    return translations.isEmpty ? '' : (translations.first as Map<String, dynamic>)['text'] as String;
  }

  Future<String> _myMemory(String text, String from, String to) async {
    final uri = Uri.https('api.mymemory.translated.net', '/get', {
      'q': text,
      'langpair': '${from.toLowerCase()}|${to.toLowerCase()}',
    });
    final http.Response response;
    try {
      response = await _client.get(uri);
    } catch (_) {
      throw const TranslationException('Brak połączenia — sprawdź internet.');
    }
    if (response.statusCode != 200) {
      throw TranslationException('Błąd tłumaczenia (kod ${response.statusCode}).');
    }
    final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    final status = data['responseStatus'];
    final ok = status == 200 || status == '200';
    final translated = (data['responseData'] as Map<String, dynamic>?)?['translatedText'] as String? ?? '';
    if (!ok || translated.isEmpty || translated.toUpperCase().contains('MYMEMORY WARNING')) {
      throw const TranslationException(
          'Wyczerpany dzienny limit MyMemory — spróbuj później albo dodaj klucz DeepL w Ustawieniach.');
    }
    return _decodeEntities(translated);
  }

  String _decodeEntities(String value) => value
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAll('&apos;', "'")
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&amp;', '&');

  void dispose() => _client.close();
}

final translationServiceProvider = Provider<TranslationService>((ref) {
  final key = ref.watch(settingsProvider.select((s) => s.translatorApiKey));
  final service = TranslationService(key);
  ref.onDispose(service.dispose);
  return service;
});
