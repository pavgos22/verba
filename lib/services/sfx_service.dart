import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/answer_check.dart';

class SfxService {
  SfxService() {
    _player.setReleaseMode(ReleaseMode.stop);
  }

  final AudioPlayer _player = AudioPlayer();

  Future<void> playGrade(AnswerGrade grade) async {
    try {
      await _player.stop();
      await _player.play(AssetSource('sounds/${grade.name}.wav'));
    } catch (_) {}
  }
}

final sfxProvider = Provider<SfxService>((ref) => SfxService());
