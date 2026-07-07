import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';

abstract class AudioService {
  Future<bool> speakRussian(String text, {bool slow = false});
}

class TtsAudioService implements AudioService {
  final FlutterTts _tts = FlutterTts();
  bool _configured = false;

  Future<bool> _ensureRussianVoice() async {
    if (_configured) return true;
    try {
      final voices = await _tts.getVoices;
      if (voices is List) {
        for (final voice in voices) {
          if (voice is Map) {
            final locale = voice['locale']?.toString().toLowerCase() ?? '';
            if (locale.startsWith('ru')) {
              await _tts.setVoice({
                'name': voice['name'].toString(),
                'locale': voice['locale'].toString(),
              });
              _configured = true;
              return true;
            }
          }
        }
      }
      final languages = await _tts.getLanguages;
      if (languages is List) {
        for (final language in languages) {
          if (language.toString().toLowerCase().startsWith('ru')) {
            await _tts.setLanguage(language.toString());
            _configured = true;
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
  Future<bool> speakRussian(String text, {bool slow = false}) async {
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

final audioServiceProvider = Provider<AudioService>((ref) => TtsAudioService());
