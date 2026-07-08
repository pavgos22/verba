import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../data/settings_store.dart';

enum Lector {
  google('Google', true, true),
  dmitri('Dmitrij (neuronowy)', true, false),
  irina('Irina (neuronowy)', true, false),
  ruslan('Rusłan (neuronowy)', true, false),
  system('Systemowy', false, false);

  const Lector(this.label, this.hasAssets, this.hasSlowAssets);

  final String label;
  final bool hasAssets;
  final bool hasSlowAssets;

  static Lector fromName(String? name) =>
      Lector.values.firstWhere((l) => l.name == name, orElse: () => Lector.google);
}

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
}

class VerbaAudioService implements AudioService {
  VerbaAudioService(this._ref);

  final Ref _ref;
  final AudioPlayer _player = AudioPlayer()..setReleaseMode(ReleaseMode.stop);
  final FlutterTts _tts = FlutterTts();
  bool _ttsConfigured = false;

  @override
  Future<bool> speakRussian(String text, {bool slow = false}) async {
    final lector = _ref.read(settingsProvider).lector;
    if (lector.hasAssets) {
      if (await _playAsset(lector, text, slow: slow)) return true;
    }
    return _speakSystem(text, slow: slow);
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

  Future<bool> _ensureRussianVoice() async {
    if (_ttsConfigured) return true;
    try {
      final voices = await _tts.getVoices;
      if (voices is List) {
        for (final voice in voices) {
          if (voice is Map && (voice['locale']?.toString().toLowerCase() ?? '').startsWith('ru')) {
            await _tts.setVoice({'name': voice['name'].toString(), 'locale': voice['locale'].toString()});
            _ttsConfigured = true;
            return true;
          }
        }
      }
      final languages = await _tts.getLanguages;
      if (languages is List) {
        for (final language in languages) {
          if (language.toString().toLowerCase().startsWith('ru')) {
            await _tts.setLanguage(language.toString());
            _ttsConfigured = true;
            return true;
          }
        }
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _speakSystem(String text, {required bool slow}) async {
    if (!await _ensureRussianVoice()) return false;
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
