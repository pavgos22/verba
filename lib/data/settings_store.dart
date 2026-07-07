import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/audio_service.dart';

final prefsProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('prefsProvider requires an override');
});

enum SessionDirection { alternate, ruToPl, plToRu, random }

class Settings {
  const Settings({
    required this.themeMode,
    required this.autoplay,
    required this.slowSpeech,
    required this.showKeyboard,
    required this.showHints,
    required this.showAccents,
    required this.answerSounds,
    required this.lector,
    required this.activeCourseId,
    required this.dailyGoal,
    required this.practiceDirection,
    required this.testDirection,
  });

  final ThemeMode themeMode;
  final bool autoplay;
  final bool slowSpeech;
  final bool showKeyboard;
  final bool showHints;
  final bool showAccents;
  final bool answerSounds;
  final Lector lector;
  final String activeCourseId;
  final int dailyGoal;
  final SessionDirection practiceDirection;
  final SessionDirection testDirection;

  Settings copyWith({
    ThemeMode? themeMode,
    bool? autoplay,
    bool? slowSpeech,
    bool? showKeyboard,
    bool? showHints,
    bool? showAccents,
    bool? answerSounds,
    Lector? lector,
    String? activeCourseId,
    int? dailyGoal,
    SessionDirection? practiceDirection,
    SessionDirection? testDirection,
  }) {
    return Settings(
      themeMode: themeMode ?? this.themeMode,
      autoplay: autoplay ?? this.autoplay,
      slowSpeech: slowSpeech ?? this.slowSpeech,
      showKeyboard: showKeyboard ?? this.showKeyboard,
      showHints: showHints ?? this.showHints,
      showAccents: showAccents ?? this.showAccents,
      answerSounds: answerSounds ?? this.answerSounds,
      lector: lector ?? this.lector,
      activeCourseId: activeCourseId ?? this.activeCourseId,
      dailyGoal: dailyGoal ?? this.dailyGoal,
      practiceDirection: practiceDirection ?? this.practiceDirection,
      testDirection: testDirection ?? this.testDirection,
    );
  }
}

class SettingsNotifier extends Notifier<Settings> {
  @override
  Settings build() {
    final prefs = ref.read(prefsProvider);
    return Settings(
      themeMode: ThemeMode.values.asNameMap()[prefs.getString('settings.themeMode')] ?? ThemeMode.system,
      autoplay: prefs.getBool('settings.autoplay') ?? true,
      slowSpeech: prefs.getBool('settings.slowSpeech') ?? false,
      showKeyboard: prefs.getBool('settings.showKeyboard') ?? true,
      showHints: prefs.getBool('settings.showHints') ?? true,
      showAccents: prefs.getBool('settings.showAccents') ?? true,
      answerSounds: prefs.getBool('settings.answerSounds') ?? true,
      lector: Lector.fromName(prefs.getString('settings.lector')),
      activeCourseId: prefs.getString('settings.activeCourseId') ?? 'starter',
      dailyGoal: prefs.getInt('settings.dailyGoal') ?? 10,
      practiceDirection: SessionDirection.values.asNameMap()[prefs.getString('settings.practiceDirection')] ??
          SessionDirection.random,
      testDirection: SessionDirection.values.asNameMap()[prefs.getString('settings.testDirection')] ??
          SessionDirection.random,
    );
  }

  void setThemeMode(ThemeMode mode) {
    state = state.copyWith(themeMode: mode);
    ref.read(prefsProvider).setString('settings.themeMode', mode.name);
  }

  void setAutoplay(bool value) {
    state = state.copyWith(autoplay: value);
    ref.read(prefsProvider).setBool('settings.autoplay', value);
  }

  void setSlowSpeech(bool value) {
    state = state.copyWith(slowSpeech: value);
    ref.read(prefsProvider).setBool('settings.slowSpeech', value);
  }

  void setShowKeyboard(bool value) {
    state = state.copyWith(showKeyboard: value);
    ref.read(prefsProvider).setBool('settings.showKeyboard', value);
  }

  void setShowHints(bool value) {
    state = state.copyWith(showHints: value);
    ref.read(prefsProvider).setBool('settings.showHints', value);
  }

  void setShowAccents(bool value) {
    state = state.copyWith(showAccents: value);
    ref.read(prefsProvider).setBool('settings.showAccents', value);
  }

  void setAnswerSounds(bool value) {
    state = state.copyWith(answerSounds: value);
    ref.read(prefsProvider).setBool('settings.answerSounds', value);
  }

  void setActiveCourseId(String value) {
    state = state.copyWith(activeCourseId: value);
    ref.read(prefsProvider).setString('settings.activeCourseId', value);
  }

  void setLector(Lector value) {
    state = state.copyWith(lector: value);
    ref.read(prefsProvider).setString('settings.lector', value.name);
  }

  void setPracticeDirection(SessionDirection value) {
    state = state.copyWith(practiceDirection: value);
    ref.read(prefsProvider).setString('settings.practiceDirection', value.name);
  }

  void setTestDirection(SessionDirection value) {
    state = state.copyWith(testDirection: value);
    ref.read(prefsProvider).setString('settings.testDirection', value.name);
  }

  void setDailyGoal(int value) {
    final clamped = value.clamp(5, 50);
    state = state.copyWith(dailyGoal: clamped);
    ref.read(prefsProvider).setInt('settings.dailyGoal', clamped);
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, Settings>(SettingsNotifier.new);
