import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/answer_check.dart';

class SfxService {
  SfxService() {
    _players.forEach((grade, player) {
      player.setReleaseMode(ReleaseMode.stop);
      player.setSource(AssetSource('sounds/${grade.name}.wav'));
    });
  }

  final Map<AnswerGrade, AudioPlayer> _players = {
    for (final grade in AnswerGrade.values) grade: AudioPlayer(),
  };

  Future<void> playGrade(AnswerGrade grade) async {
    final player = _players[grade]!;
    try {
      await player.stop();
      await player.seek(Duration.zero);
      await player.resume();
    } catch (_) {}
  }
}

final sfxProvider = Provider<SfxService>((ref) => SfxService());
