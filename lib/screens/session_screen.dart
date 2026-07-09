import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/answer_check.dart';
import '../core/transliteration.dart';
import '../data/progress_store.dart';
import '../data/settings_store.dart';
import '../data/word.dart';
import '../data/words_repository.dart';
import '../services/audio_service.dart';
import '../services/sfx_service.dart';
import '../theme/app_colors.dart';
import '../widgets/accented_text.dart';
import '../widgets/common.dart';
import '../widgets/lector_dropdown.dart';
import '../widgets/onscreen_keyboard.dart';

enum SessionMode { full, reviewsOnly, practice, test, retry }

enum TaskKind { presentation, typingPlToRu, typingRuToPl }

class SessionTask {
  const SessionTask({required this.word, required this.kind});

  final Word word;
  final TaskKind kind;
}

class SessionMistake {
  const SessionMistake({required this.word, required this.kind, required this.given});

  final Word word;
  final TaskKind kind;
  final String given;

  String get correctAnswer => kind == TaskKind.typingRuToPl ? word.pl.join(', ') : word.ruAccented;
}

class SessionScreen extends ConsumerStatefulWidget {
  const SessionScreen({super.key, required this.mode, this.retryTasks = const [], this.loop = true});

  final SessionMode mode;
  final List<SessionTask> retryTasks;
  final bool loop;

  @override
  ConsumerState<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends ConsumerState<SessionScreen> {
  List<SessionTask>? _tasks;
  int _index = 0;
  int _answered = 0;
  int _correct = 0;
  final List<SessionMistake> _mistakes = [];
  bool _finished = false;
  bool _tabHeld = false;

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.space &&
        HardwareKeyboard.instance.isControlPressed) {
      _playCurrent();
      return KeyEventResult.handled;
    }
    if (event.logicalKey != LogicalKeyboardKey.tab) return KeyEventResult.ignored;
    if (event is KeyDownEvent && !_tabHeld) {
      setState(() => _tabHeld = true);
    } else if (event is KeyUpEvent && _tabHeld) {
      setState(() => _tabHeld = false);
    }
    return KeyEventResult.handled;
  }

  void _playCurrent() {
    final tasks = _tasks;
    if (tasks == null || _finished || _index >= tasks.length) return;
    final task = tasks[_index];
    if (task.kind == TaskKind.typingPlToRu) return;
    final settings = ref.read(settingsProvider);
    ref.read(audioServiceProvider).speakRussian(task.word.ru, slow: settings.slowSpeech);
  }

  List<Word> _inCategory(List<Word> words, String? category) =>
      category == null ? words : words.where((w) => w.category == category).toList();

  List<SessionTask> _buildTasks(List<Word> words) {
    final progress = ref.read(progressProvider);
    final notifier = ref.read(progressProvider.notifier);
    final settings = ref.read(settingsProvider);
    final rng = Random();
    final now = DateTime.now();
    switch (widget.mode) {
      case SessionMode.full:
        final cfg = settings.configFor('full');
        final pool = _inCategory(words, cfg.category);
        final fresh = pool.where((w) => progress.statusOf(w.id) == WordStatus.fresh).toList();
        if (settings.newWordOrder == NewWordOrder.random) fresh.shuffle(rng);
        final due = pool.where((w) => notifier.isDue(w.id, now)).toList()..shuffle(rng);
        final chosen = [...fresh, ...due].take(cfg.count).toList();
        final tasks = <SessionTask>[];
        for (var i = 0; i < chosen.length; i++) {
          final word = chosen[i];
          if (progress.statusOf(word.id) == WordStatus.fresh) {
            tasks.add(SessionTask(word: word, kind: TaskKind.presentation));
            tasks.add(SessionTask(word: word, kind: TaskKind.typingPlToRu));
          } else {
            tasks.add(SessionTask(word: word, kind: _kindFor(SessionDirection.random, i, rng)));
          }
        }
        return tasks;
      case SessionMode.reviewsOnly:
        final due = words.where((w) => notifier.isDue(w.id, now)).toList()..shuffle(rng);
        return [
          for (var i = 0; i < due.length; i++)
            SessionTask(word: due[i], kind: _kindFor(SessionDirection.random, i, rng)),
        ];
      case SessionMode.practice:
      case SessionMode.test:
        final key = widget.mode == SessionMode.test ? 'test' : 'practice';
        final cfg = settings.configFor(key);
        final started = _inCategory(words, cfg.category)
            .where((w) => progress.statusOf(w.id) != WordStatus.fresh)
            .toList()
          ..shuffle(rng);
        final pool = started.take(cfg.count).toList();
        return [
          for (var i = 0; i < pool.length; i++)
            SessionTask(word: pool[i], kind: _kindFor(cfg.direction, i, rng)),
        ];
      case SessionMode.retry:
        return List.of(widget.retryTasks);
    }
  }

  TaskKind _kindFor(SessionDirection direction, int index, Random rng) {
    return switch (direction) {
      SessionDirection.alternate => index.isEven ? TaskKind.typingRuToPl : TaskKind.typingPlToRu,
      SessionDirection.ruToPl => TaskKind.typingRuToPl,
      SessionDirection.plToRu => TaskKind.typingPlToRu,
      SessionDirection.random => rng.nextBool() ? TaskKind.typingPlToRu : TaskKind.typingRuToPl,
    };
  }

  void _onTypingResult(SessionTask task, AnswerGrade grade, String given) {
    ref.read(progressProvider.notifier).recordAnswer(task.word.id, grade != AnswerGrade.wrong);
    setState(() {
      _answered++;
      if (grade == AnswerGrade.correct) {
        _correct++;
      } else if (widget.mode == SessionMode.retry && widget.loop) {
        _tasks!.add(SessionTask(word: task.word, kind: task.kind));
      } else {
        _mistakes.add(SessionMistake(word: task.word, kind: task.kind, given: given));
      }
    });
  }

  void _next() {
    final tasks = _tasks!;
    setState(() {
      if (_index + 1 >= tasks.length) {
        _finished = true;
        ref.read(progressProvider.notifier).finishSession();
      } else {
        _index++;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final wordsAsync = ref.watch(wordsProvider);
    return Scaffold(
      body: wordsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => const Center(child: Text('Nie udało się wczytać kursu')),
        data: (words) {
          _tasks ??= _buildTasks(words);
          final tasks = _tasks!;
          if (tasks.isEmpty) return _EmptySession(onBack: () => Navigator.of(context).pop());
          if (_finished) {
            final loose = widget.mode == SessionMode.test || (widget.mode == SessionMode.retry && !widget.loop);
            return _SummaryView(
              correct: _correct,
              total: _answered,
              mistakes: _mistakes,
              allowRetry: _mistakes.isNotEmpty,
              loose: loose,
              cleared: widget.mode == SessionMode.retry && widget.loop,
              onRetry: () {
                final retryTasks = {
                  for (final m in _mistakes) m.word.id: SessionTask(word: m.word, kind: m.kind),
                }.values.toList();
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => SessionScreen(mode: SessionMode.retry, retryTasks: retryTasks, loop: !loose),
                  ),
                );
              },
              onFinish: () => Navigator.of(context).pop(),
            );
          }
          final task = tasks[_index];
          final wordIds = <String>{for (final t in tasks) t.word.id}.toList();
          final wordIndex = wordIds.indexOf(task.word.id);
          final modeLabel = switch (widget.mode) {
            SessionMode.practice => 'Utrwalanie',
            SessionMode.test => 'Test',
            SessionMode.retry => 'Poprawka',
            _ => null,
          };
          return Focus(
            onKeyEvent: _handleKey,
            child: Column(
              children: [
                _SessionTopBar(index: wordIndex, total: wordIds.length, modeLabel: modeLabel),
                Expanded(
                  child: KeyedSubtree(
                    key: ValueKey(_index),
                    child: task.kind == TaskKind.presentation
                        ? _PresentationView(word: task.word, showPronunciation: _tabHeld, onNext: _next)
                        : _TypingView(
                            word: task.word,
                            kind: task.kind,
                            showCorrections: widget.mode != SessionMode.test,
                            showPronunciation: _tabHeld,
                            onResult: (grade, given) => _onTypingResult(task, grade, given),
                            onNext: _next,
                          ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SessionTopBar extends StatelessWidget {
  const _SessionTopBar({required this.index, required this.total, this.modeLabel});

  final int index;
  final int total;
  final String? modeLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: context.c.border))),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(Icons.close, size: 18, color: context.c.mutedForeground),
            tooltip: 'Przerwij sesję',
          ),
          if (modeLabel != null) ...[
            const SizedBox(width: 16),
            AppBadge(label: modeLabel!),
          ],
          const SizedBox(width: 16),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: total == 0 ? 0 : index / total,
                minHeight: 8,
                backgroundColor: context.c.muted,
                color: context.c.primary,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Text('${index + 1} / $total',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: context.c.mutedForeground)),
        ],
      ),
    );
  }
}

class _SessionFooter extends StatelessWidget {
  const _SessionFooter({required this.children, this.leading});

  final List<Widget> children;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 88,
      padding: const EdgeInsets.symmetric(horizontal: 40),
      decoration: BoxDecoration(border: Border(top: BorderSide(color: context.c.border))),
      child: Row(
        children: [
          ?leading,
          const Spacer(),
          ...children,
        ],
      ),
    );
  }
}

class _PresentationView extends ConsumerStatefulWidget {
  const _PresentationView({required this.word, required this.showPronunciation, required this.onNext});

  final Word word;
  final bool showPronunciation;
  final VoidCallback onNext;

  @override
  ConsumerState<_PresentationView> createState() => _PresentationViewState();
}

class _PresentationViewState extends ConsumerState<_PresentationView> {
  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsProvider);
    if (settings.autoplay) {
      ref.read(audioServiceProvider).speakRussian(widget.word.ru, slow: settings.slowSpeech);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    return Column(
      children: [
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const AppBadge(label: 'Nowe słówko'),
                const SizedBox(height: 24),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AccentedText(widget.word.ruAccented,
                        style: TextStyle(fontSize: 48, fontWeight: FontWeight.w600, color: context.c.foreground)),
                    const SizedBox(width: 16),
                    SpeakerButton(text: widget.word.ru, size: 44),
                  ],
                ),
                const SizedBox(height: 8),
                PronunciationSlot(
                  pronunciation: widget.word.pronunciation,
                  visible: widget.showPronunciation,
                  fontSize: 15,
                ),
                const SizedBox(height: 16),
                Container(width: 64, height: 1, color: context.c.border),
                const SizedBox(height: 24),
                Text(widget.word.pl.join(', '),
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500, color: context.c.foreground)),
                const SizedBox(height: 24),
                if (widget.word.category != null) AppBadge(label: widget.word.category!),
              ],
            ),
          ),
        ),
        _SessionFooter(
          leading: LectorDropdown(
            value: settings.lector,
            onChanged: (lector) {
              ref.read(settingsProvider.notifier).setLector(lector);
              ref.read(audioServiceProvider).speakRussian(widget.word.ru, slow: settings.slowSpeech);
            },
          ),
          children: [
            Text(
                widget.word.pronunciation != null
                    ? 'Ctrl+Spacja — odsłuchaj · Tab — transkrypcja · Enter ↵ — dalej'
                    : 'Ctrl+Spacja — odsłuchaj · Enter ↵ — dalej',
                style: TextStyle(fontSize: 13, color: context.c.mutedForeground)),
            const SizedBox(width: 16),
            FilledButton(autofocus: true, onPressed: widget.onNext, child: const Text('Dalej')),
          ],
        ),
      ],
    );
  }
}

class _TypingView extends ConsumerStatefulWidget {
  const _TypingView({
    required this.word,
    required this.kind,
    required this.showCorrections,
    required this.showPronunciation,
    required this.onResult,
    required this.onNext,
  });

  final Word word;
  final TaskKind kind;
  final bool showCorrections;
  final bool showPronunciation;
  final void Function(AnswerGrade grade, String given) onResult;
  final VoidCallback onNext;

  @override
  ConsumerState<_TypingView> createState() => _TypingViewState();
}

class _TypingViewState extends ConsumerState<_TypingView> with TickerProviderStateMixin {
  final _controller = TextEditingController();
  final _fieldFocus = FocusNode();
  final _nextFocus = FocusNode();
  late final AnimationController _shake =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 450));
  late final AnimationController _pop =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
  double _shakeAmplitude = 10;
  int _shakeCycles = 6;
  AnswerGrade? _grade;
  bool _done = false;

  bool get _isPlToRu => widget.kind == TaskKind.typingPlToRu;

  bool get _retype => _grade != null && !_done;

  @override
  void initState() {
    super.initState();
    if (!_isPlToRu) {
      final settings = ref.read(settingsProvider);
      if (settings.autoplay) {
        ref.read(audioServiceProvider).speakRussian(widget.word.ru, slow: settings.slowSpeech);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _fieldFocus.dispose();
    _nextFocus.dispose();
    _shake.dispose();
    _pop.dispose();
    super.dispose();
  }

  void _startShake({required bool slow}) {
    setState(() {
      _shakeAmplitude = slow ? 6 : 10;
      _shakeCycles = slow ? 3 : 6;
    });
    _shake.duration = Duration(milliseconds: slow ? 650 : 450);
    _shake.forward(from: 0);
  }

  void _playFeedback(AnswerGrade grade) {
    if (!ref.read(settingsProvider).answerSounds) return;
    ref.read(sfxProvider).playGrade(grade);
  }

  Widget _buildFeedback(BuildContext context, Settings settings, String correctAnswer) {
    if (_done) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ScaleTransition(
            scale: CurvedAnimation(parent: _pop, curve: Curves.elasticOut),
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(color: context.c.success, shape: BoxShape.circle),
              child: Icon(Icons.check, size: 14, color: context.c.background),
            ),
          ),
          const SizedBox(width: 8),
          Text('Świetnie!',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: context.c.success)),
        ],
      );
    }
    if (_retype) {
      final almost = _grade == AnswerGrade.almost;
      final color = almost ? context.c.warning : context.c.destructive;
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(almost ? 'Prawie dobrze! Wpisz poprawnie:' : 'Poprawna odpowiedź:',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: color)),
          const SizedBox(width: 6),
          AccentedText(correctAnswer,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: color)),
          if (!almost) ...[
            const SizedBox(width: 6),
            Text('— przepisz ją',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: color)),
          ],
        ],
      );
    }
    if (_isPlToRu && settings.showHints) {
      return Text('pisz „spasibo” — litery łacińskie zamienią się w cyrylicę',
          style: TextStyle(fontSize: 13, color: context.c.mutedForeground));
    }
    return const SizedBox.shrink();
  }

  void _finish() {
    _playFeedback(AnswerGrade.correct);
    setState(() => _done = true);
    _pop.forward(from: 0);
    _nextFocus.requestFocus();
  }

  void _check() {
    if (_done) return;
    final given = _controller.text.trim();
    if (given.isEmpty) return;
    if (_grade == null) {
      final grade = _isPlToRu ? gradeRuAnswer(widget.word, given) : gradePlAnswer(widget.word, given);
      widget.onResult(grade, given);
      if (!widget.showCorrections) {
        widget.onNext();
        return;
      }
      setState(() => _grade = grade);
      if (grade == AnswerGrade.correct) {
        _finish();
      } else {
        _playFeedback(grade);
        _startShake(slow: grade == AnswerGrade.almost);
        _fieldFocus.requestFocus();
      }
    } else {
      final exact = _isPlToRu ? checkRuAnswer(widget.word, given) : checkPlAnswer(widget.word, given);
      if (exact) {
        _finish();
      } else {
        _playFeedback(AnswerGrade.wrong);
        _startShake(slow: false);
        _fieldFocus.requestFocus();
      }
    }
  }

  void _giveUp() {
    if (_grade != null || _done) return;
    widget.onResult(AnswerGrade.wrong, _controller.text.trim());
    if (!widget.showCorrections) {
      widget.onNext();
      return;
    }
    setState(() => _grade = AnswerGrade.wrong);
    _playFeedback(AnswerGrade.wrong);
    _startShake(slow: false);
    _fieldFocus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final correctAnswer = _isPlToRu ? widget.word.ruAccented : widget.word.pl.join(', ');
    final borderColor = _done
        ? context.c.success
        : switch (_grade) {
            null => context.c.inputBorder,
            AnswerGrade.almost => context.c.warning,
            _ => context.c.destructive,
          };

    return Column(
      children: [
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_isPlToRu ? 'Przetłumacz na rosyjski' : 'Przetłumacz na polski',
                      style: TextStyle(fontSize: 14, color: context.c.mutedForeground)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _isPlToRu
                          ? Text(widget.word.plPrimary,
                              style:
                                  TextStyle(fontSize: 36, fontWeight: FontWeight.w600, color: context.c.foreground))
                          : AccentedText(widget.word.ruAccented,
                              style:
                                  TextStyle(fontSize: 36, fontWeight: FontWeight.w600, color: context.c.foreground)),
                      if (!_isPlToRu) ...[
                        const SizedBox(width: 14),
                        Tooltip(
                          message: 'Ctrl+Spacja',
                          child: SpeakerButton(text: widget.word.ru, size: 40),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  PronunciationSlot(
                    pronunciation: _isPlToRu ? null : widget.word.pronunciation,
                    visible: widget.showPronunciation,
                    fontSize: 13,
                  ),
                  const SizedBox(height: 12),
                  AnimatedBuilder(
                    animation: _shake,
                    builder: (context, child) {
                      final t = _shake.value;
                      final dx = sin(t * pi * 2 * _shakeCycles) * _shakeAmplitude * (1 - t);
                      return Transform.translate(offset: Offset(dx, 0), child: child);
                    },
                    child: SizedBox(
                      width: 480,
                      child: TextField(
                        controller: _controller,
                        focusNode: _fieldFocus,
                        autofocus: true,
                        enabled: !_done,
                        inputFormatters: _isPlToRu ? [TransliterationFormatter()] : null,
                        onSubmitted: (_) => _check(),
                        style: TextStyle(fontSize: 22, color: context.c.foreground),
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: borderColor, width: _grade == null ? 1 : 2),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                                color: _grade == null && !_done ? context.c.ring : borderColor, width: 2),
                          ),
                          disabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: borderColor, width: 2),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 24,
                    child: Center(child: _buildFeedback(context, settings, correctAnswer)),
                  ),
                  if (settings.showKeyboard) ...[
                    const SizedBox(height: 24),
                    OnScreenKeyboard(
                      layout: _isPlToRu ? KeyboardLayoutType.russian : KeyboardLayoutType.polish,
                      onText: (text) {
                        if (!_done) insertIntoController(_controller, text);
                      },
                      onBackspace: () {
                        if (!_done) backspaceInController(_controller);
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        _SessionFooter(
          leading: LectorDropdown(
            value: settings.lector,
            onChanged: (lector) {
              ref.read(settingsProvider.notifier).setLector(lector);
              if (!_isPlToRu) {
                ref.read(audioServiceProvider).speakRussian(widget.word.ru, slow: settings.slowSpeech);
              }
            },
          ),
          children: _done
              ? [
                  FilledButton(focusNode: _nextFocus, onPressed: widget.onNext, child: const Text('Dalej')),
                ]
              : _grade == null
                  ? [
                      TextButton(onPressed: _giveUp, child: const Text('Nie wiem')),
                      const SizedBox(width: 12),
                      FilledButton(onPressed: _check, child: const Text('Sprawdź')),
                    ]
                  : [
                      FilledButton(onPressed: _check, child: const Text('Sprawdź')),
                    ],
        ),
      ],
    );
  }
}

class _SummaryView extends StatelessWidget {
  const _SummaryView({
    required this.correct,
    required this.total,
    required this.mistakes,
    required this.allowRetry,
    required this.cleared,
    required this.loose,
    required this.onRetry,
    required this.onFinish,
  });

  final int correct;
  final int total;
  final List<SessionMistake> mistakes;
  final bool allowRetry;
  final bool cleared;
  final bool loose;
  final VoidCallback onRetry;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    final percent = total == 0 ? 100 : (correct * 100 / total).round();
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(color: context.c.muted, shape: BoxShape.circle),
              child: Icon(Icons.check, size: 32, color: context.c.success),
            ),
            const SizedBox(height: 24),
            Text(cleared ? 'Wszystko poprawione!' : 'Sesja ukończona!',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: context.c.foreground)),
            const SizedBox(height: 8),
            Text(
                cleared
                    ? 'Każde błędne słówko zostało w końcu wpisane poprawnie'
                    : '$correct z $total poprawnie · $percent%',
                style: TextStyle(fontSize: 16, color: context.c.mutedForeground)),
            if (mistakes.isNotEmpty) ...[
              const SizedBox(height: 24),
              SizedBox(
                width: 560,
                child: AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Do poprawki (${mistakes.length})',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: context.c.foreground)),
                      for (final mistake in mistakes)
                        Container(
                          height: 44,
                          margin: const EdgeInsets.only(top: 8),
                          decoration:
                              BoxDecoration(border: Border(top: BorderSide(color: context.c.border))),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 150,
                                child: AccentedText(
                                  mistake.kind == TaskKind.typingRuToPl
                                      ? mistake.word.ruAccented
                                      : mistake.word.plPrimary,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      fontSize: 15, fontWeight: FontWeight.w500, color: context.c.foreground),
                                ),
                              ),
                              SizedBox(
                                width: 150,
                                child: Text(
                                  mistake.given.isEmpty ? '—' : mistake.given,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: context.c.destructive,
                                    decoration: TextDecoration.lineThrough,
                                    decorationColor: context.c.destructive,
                                  ),
                                ),
                              ),
                              Icon(Icons.arrow_forward, size: 14, color: context.c.mutedForeground),
                              const SizedBox(width: 12),
                              Expanded(
                                child: AccentedText(
                                  mistake.correctAnswer,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      fontSize: 14, fontWeight: FontWeight.w500, color: context.c.success),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (allowRetry) ...[
                  OutlinedButton(
                      autofocus: true,
                      onPressed: onRetry,
                      child: Text(loose
                          ? 'Popraw błędne (${mistakes.length})'
                          : 'Powtórz błędne (${mistakes.length})')),
                  const SizedBox(width: 12),
                ],
                FilledButton(
                    autofocus: !allowRetry,
                    onPressed: onFinish,
                    child: Text(loose ? 'Powróć do ekranu głównego' : 'Zakończ')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptySession extends StatelessWidget {
  const _EmptySession({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Brak słówek do nauki na dziś',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: context.c.foreground)),
          const SizedBox(height: 8),
          Text('Wróć jutro albo zwiększ cel dzienny w ustawieniach',
              style: TextStyle(fontSize: 14, color: context.c.mutedForeground)),
          const SizedBox(height: 20),
          FilledButton(autofocus: true, onPressed: onBack, child: const Text('Wróć')),
        ],
      ),
    );
  }
}
