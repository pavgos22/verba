import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';

abstract class AudioService {
  Future<void> speakRussian(String text, {bool slow = false});
}

class TtsAudioService implements AudioService {
  TtsAudioService() {
    _initialized = _init();
  }

  final FlutterTts _tts = FlutterTts();
  late final Future<void> _initialized;

  Future<void> _init() async {
    try {
      await _tts.setLanguage('ru-RU');
    } catch (_) {}
  }

  @override
  Future<void> speakRussian(String text, {bool slow = false}) async {
    try {
      await _initialized;
      await _tts.stop();
      await _tts.setSpeechRate(slow ? 0.3 : 0.5);
      await _tts.speak(text.replaceAll('́', ''));
    } catch (_) {}
  }
}

final audioServiceProvider = Provider<AudioService>((ref) => TtsAudioService());
