import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../data/settings_store.dart';

enum Lector {
  google('Verba', true, true),
  system('Systemowy', false, false);

  const Lector(this.label, this.hasAssets, this.hasSlowAssets);

  final String label;
  final bool hasAssets;
  final bool hasSlowAssets;

  static Lector fromName(String? name) =>
      Lector.values.firstWhere((l) => l.name == name, orElse: () => Lector.google);
}

bool useAssetVoice(Lector lector, String activeCourseId) =>
    lector.hasAssets && !activeCourseId.startsWith('custom-');

String lectorKey(String text) {
  var hash = BigInt.parse('14695981039346656037');
  final prime = BigInt.parse('1099511628211');
  final mask = (BigInt.one << 64) - BigInt.one;
  for (final b in utf8.encode(text)) {
    hash = hash ^ BigInt.from(b);
    hash = (hash * prime) & mask;
  }
  return hash.toRadixString(16).padLeft(16, '0');
}

abstract class AudioService {
  Future<bool> speakRussian(String text, {bool slow = false});
  Future<bool> speakPolish(String text, {bool slow = false});
  Future<bool> speakSystem(String text, {required String lang, bool slow = false});
}

class VerbaAudioService implements AudioService {
  VerbaAudioService(this._ref);

  final Ref _ref;
  final AudioPlayer _player = AudioPlayer()..setReleaseMode(ReleaseMode.stop);
  final FlutterTts _tts = FlutterTts();
  String? _ttsLang;

  @override
  Future<bool> speakRussian(String text, {bool slow = false}) async {
    final settings = _ref.read(settingsProvider);
    if (useAssetVoice(settings.lector, settings.activeCourseId)) {
      if (await _playAsset(settings.lector, text, slow: slow)) return true;
    }
    return speakSystem(text, lang: 'ru', slow: slow);
  }

  Future<bool> _playAsset(Lector lector, String text, {required bool slow}) async {
    final folder = slow && lector.hasSlowAssets ? '${lector.name}_slow' : lector.name;
    final rate = slow && !lector.hasSlowAssets ? 0.75 : 1.0;
    try {
      await _player.stop();
      await _player.setPlaybackRate(rate);
      await _player.play(AssetSource('lector/$folder/${lectorKey(text)}.mp3'));
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> speakPolish(String text, {bool slow = false}) async {
    final settings = _ref.read(settingsProvider);
    if (!settings.activeCourseId.startsWith('custom-')) {
      if (await _playPolishAsset(text, slow: slow)) return true;
    }
    return speakSystem(text, lang: 'pl', slow: slow);
  }

  Future<bool> _playPolishAsset(String text, {required bool slow}) async {
    try {
      await _player.stop();
      await _player.setPlaybackRate(slow ? 0.75 : 1.0);
      await _player.play(AssetSource('lector/google_pl/${lectorKey(text)}.mp3'));
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _ensureVoice(String prefix) async {
    if (_ttsLang == prefix) return true;
    try {
      final voices = await _tts.getVoices;
      if (voices is List) {
        for (final voice in voices) {
          if (voice is Map && (voice['locale']?.toString().toLowerCase() ?? '').startsWith(prefix)) {
            await _tts.setVoice({'name': voice['name'].toString(), 'locale': voice['locale'].toString()});
            _ttsLang = prefix;
            return true;
          }
        }
      }
      final languages = await _tts.getLanguages;
      if (languages is List) {
        for (final language in languages) {
          if (language.toString().toLowerCase().startsWith(prefix)) {
            await _tts.setLanguage(language.toString());
            _ttsLang = prefix;
            return true;
          }
        }
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> speakSystem(String text, {required String lang, bool slow = false}) async {
    if (!await _ensureVoice(lang)) return false;
    try {
      await _tts.stop();
      await _tts.setSpeechRate(slow ? 0.3 : 0.5);
      await _tts.speak(text.replaceAll('́', ''));
      return true;
    } catch (_) {
      return false;
    }
  }
}

final audioServiceProvider = Provider<AudioService>((ref) => VerbaAudioService(ref));
