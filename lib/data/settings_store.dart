import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/audio_service.dart';

final prefsProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('prefsProvider requires an override');
});

enum SessionDirection { alternate, ruToPl, plToRu, random }

enum NewWordOrder { inOrder, random }

enum SessionScope { all, newest, hardest }

enum VerbInfoMode { never, always, onHold }

const sessionModeKeys = ['full', 'practice', 'test'];

class ModeConfig {
  const ModeConfig({
    required this.count,
    required this.category,
    required this.direction,
    this.scope = SessionScope.all,
  });

  final int count;
  final String? category;
  final SessionDirection direction;
  final SessionScope scope;
}

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
    required this.newWordOrder,
    required this.verbInfo,
    required this.showWordPoints,
    required this.autoKeyboardLayout,
    required this.enterEmptyIsGiveUp,
    required this.modes,
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
  final NewWordOrder newWordOrder;
  final VerbInfoMode verbInfo;
  final bool showWordPoints;
  final bool autoKeyboardLayout;
  final bool enterEmptyIsGiveUp;
  final Map<String, ModeConfig> modes;

  ModeConfig configFor(String mode) =>
      modes[mode] ?? const ModeConfig(count: 20, category: null, direction: SessionDirection.random);

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
    NewWordOrder? newWordOrder,
    VerbInfoMode? verbInfo,
    bool? showWordPoints,
    bool? autoKeyboardLayout,
    bool? enterEmptyIsGiveUp,
    Map<String, ModeConfig>? modes,
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
      newWordOrder: newWordOrder ?? this.newWordOrder,
      verbInfo: verbInfo ?? this.verbInfo,
      showWordPoints: showWordPoints ?? this.showWordPoints,
      autoKeyboardLayout: autoKeyboardLayout ?? this.autoKeyboardLayout,
      enterEmptyIsGiveUp: enterEmptyIsGiveUp ?? this.enterEmptyIsGiveUp,
      modes: modes ?? this.modes,
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
      newWordOrder: NewWordOrder.values.asNameMap()[prefs.getString('settings.newWordOrder')] ??
          NewWordOrder.random,
      verbInfo: VerbInfoMode.values.asNameMap()[prefs.getString('settings.verbInfo')] ?? VerbInfoMode.onHold,
      showWordPoints: prefs.getBool('settings.showWordPoints') ?? false,
      autoKeyboardLayout: prefs.getBool('settings.autoKeyboardLayout') ?? true,
      enterEmptyIsGiveUp: prefs.getBool('settings.enterEmptyIsGiveUp') ?? true,
      modes: {
        for (final mode in sessionModeKeys)
          mode: ModeConfig(
            count: prefs.getInt('settings.mode.$mode.count') ?? 20,
            category: prefs.getString('settings.mode.$mode.category'),
            direction: SessionDirection.values.asNameMap()[prefs.getString('settings.mode.$mode.direction')] ??
                SessionDirection.random,
            scope: SessionScope.values.asNameMap()[prefs.getString('settings.mode.$mode.scope')] ??
                SessionScope.all,
          ),
      },
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

  void setNewWordOrder(NewWordOrder value) {
    state = state.copyWith(newWordOrder: value);
    ref.read(prefsProvider).setString('settings.newWordOrder', value.name);
  }

  void setVerbInfo(VerbInfoMode value) {
    state = state.copyWith(verbInfo: value);
    ref.read(prefsProvider).setString('settings.verbInfo', value.name);
  }

  void setShowWordPoints(bool value) {
    state = state.copyWith(showWordPoints: value);
    ref.read(prefsProvider).setBool('settings.showWordPoints', value);
  }

  void setAutoKeyboardLayout(bool value) {
    state = state.copyWith(autoKeyboardLayout: value);
    ref.read(prefsProvider).setBool('settings.autoKeyboardLayout', value);
  }

  void setEnterEmptyIsGiveUp(bool value) {
    state = state.copyWith(enterEmptyIsGiveUp: value);
    ref.read(prefsProvider).setBool('settings.enterEmptyIsGiveUp', value);
  }

  void setModeConfig(String mode, ModeConfig config) {
    final clamped = ModeConfig(
      count: config.count.clamp(5, 50),
      category: config.category,
      direction: config.direction,
      scope: config.scope,
    );
    state = state.copyWith(modes: {...state.modes, mode: clamped});
    final prefs = ref.read(prefsProvider);
    prefs.setInt('settings.mode.$mode.count', clamped.count);
    prefs.setString('settings.mode.$mode.direction', clamped.direction.name);
    prefs.setString('settings.mode.$mode.scope', clamped.scope.name);
    if (clamped.category == null) {
      prefs.remove('settings.mode.$mode.category');
    } else {
      prefs.setString('settings.mode.$mode.category', clamped.category!);
    }
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, Settings>(SettingsNotifier.new);
