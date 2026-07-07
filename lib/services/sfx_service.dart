import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/answer_check.dart';

class SfxService {
  SfxService() {
    _player.setReleaseMode(ReleaseMode.stop);
  }

  final AudioPlayer _player = AudioPlayer();

  Future<void> playGrade(AnswerGrade grade) {
    return _play(switch (grade) {
      AnswerGrade.correct => 'correct.wav',
      AnswerGrade.almost => 'almost.wav',
      AnswerGrade.wrong => 'wrong.wav',
    });
  }

  Future<void> _play(String file) async {
    try {
      await _player.stop();
      await _player.play(AssetSource('sounds/$file'));
    } catch (_) {}
  }
}

final sfxProvider = Provider<SfxService>((ref) => SfxService());
