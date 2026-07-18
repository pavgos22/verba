import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/transliteration.dart';
import '../data/settings_store.dart';
import '../services/audio_service.dart';
import '../services/translation_service.dart';
import '../theme/app_colors.dart';
import '../widgets/common.dart';
import '../widgets/onscreen_keyboard.dart';

class TranslatorScreen extends ConsumerStatefulWidget {
  const TranslatorScreen({super.key});

  @override
  ConsumerState<TranslatorScreen> createState() => _TranslatorScreenState();
}

class _TranslatorScreenState extends ConsumerState<TranslatorScreen> {
  final _source = TextEditingController();
  final _sourceFocus = FocusNode();
  Timer? _debounce;
  bool _ruToPl = true;
  late bool _deepl;
  String _result = '';
  bool _loading = false;
  String? _error;
  int _reqId = 0;

  String get _from => _ruToPl ? 'RU' : 'PL';
  String get _to => _ruToPl ? 'PL' : 'RU';
  String get _srcLang => _ruToPl ? 'ru' : 'pl';
  String get _dstLang => _ruToPl ? 'pl' : 'ru';
  bool get _sourceRussian => _ruToPl;

  @override
  void initState() {
    super.initState();
    _deepl = ref.read(settingsProvider).translatorApiKey.trim().isNotEmpty;
    _source.addListener(_onSourceChanged);
  }

  void _onSourceChanged() {
    _debounce?.cancel();
    final text = _source.text;
    if (text.trim().isEmpty) {
      setState(() {
        _result = '';
        _error = null;
        _loading = false;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    _debounce = Timer(const Duration(milliseconds: 400), () => _translate(text));
  }

  Future<void> _translate(String text) async {
    final id = ++_reqId;
    final via = _deepl ? TranslationProvider.deepl : TranslationProvider.myMemory;
    try {
      final out = await ref.read(translationServiceProvider).translate(text, from: _from, to: _to, via: via);
      if (!mounted || id != _reqId) return;
      setState(() {
        _result = out;
        _error = null;
        _loading = false;
      });
    } on TranslationException catch (e) {
      if (!mounted || id != _reqId) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted || id != _reqId) return;
      setState(() {
        _error = 'Nie udało się przetłumaczyć.';
        _loading = false;
      });
    }
  }

  void _retranslate() {
    if (_source.text.trim().isEmpty) {
      setState(() {
        _result = '';
        _error = null;
        _loading = false;
      });
    } else {
      _onSourceChanged();
    }
  }

  void _swap() {
    final newSource = _result;
    setState(() {
      _ruToPl = !_ruToPl;
      _result = _source.text;
    });
    _source.text = newSource;
  }

  Future<void> _speak(BuildContext context, String text, String lang) async {
    if (text.trim().isEmpty) return;
    final ok = await ref.read(audioServiceProvider).speakSystem(text, lang: lang);
    if (!ok && context.mounted) {
      final name = lang == 'ru' ? 'rosyjskiego' : 'polskiego';
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text('Brak $name głosu w Windows. Dodaj go: Ustawienia → Czas i język → Mowa.'),
          duration: const Duration(seconds: 4),
        ));
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _source.removeListener(_onSourceChanged);
    _source.dispose();
    _sourceFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasKey = ref.watch(settingsProvider.select((s) => s.translatorApiKey.trim().isNotEmpty));
    return SingleChildScrollView(
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tłumacz', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: context.c.foreground)),
          const SizedBox(height: 4),
          Text('Tłumaczenie rosyjski ↔ polski',
              style: TextStyle(fontSize: 14, color: context.c.mutedForeground)),
          const SizedBox(height: 20),
          Row(
            children: [
              _directionSelector(context),
              const Spacer(),
              _providerSelector(context, hasKey),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 210,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _sourcePanel(context)),
                const SizedBox(width: 16),
                Expanded(child: _resultPanel(context)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: OnScreenKeyboard(
              layout: _sourceRussian ? KeyboardLayoutType.russian : KeyboardLayoutType.polish,
              onText: (text) => insertIntoController(_source, text),
              onBackspace: () => backspaceInController(_source),
            ),
          ),
        ],
      ),
    );
  }

  Widget _directionSelector(BuildContext context) {
    final style = TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: context.c.foreground);
    final srcLabel = _sourceRussian ? 'Rosyjski' : 'Polski';
    final dstLabel = _sourceRussian ? 'Polski' : 'Rosyjski';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(width: 76, child: Text(srcLabel, textAlign: TextAlign.right, style: style)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: IconButton(
            onPressed: _swap,
            icon: Icon(Icons.swap_horiz, size: 20, color: context.c.mutedForeground),
            tooltip: 'Zamień kierunek',
            visualDensity: VisualDensity.compact,
          ),
        ),
        SizedBox(width: 76, child: Text(dstLabel, textAlign: TextAlign.left, style: style)),
      ],
    );
  }

  Widget _providerSelector(BuildContext context, bool hasKey) {
    return SegmentedButton<bool>(
      segments: [
        const ButtonSegment(value: false, label: Text('MyMemory')),
        ButtonSegment(
          value: true,
          label: hasKey
              ? const Text('DeepL')
              : Tooltip(
                  message: 'Wymaga własnego klucza DeepL — dodaj w Ustawieniach → Tłumacz',
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('DeepL'),
                      const SizedBox(width: 5),
                      Icon(Icons.lock_outline, size: 13, color: context.c.mutedForeground),
                    ],
                  ),
                ),
        ),
      ],
      selected: {_deepl},
      showSelectedIcon: false,
      onSelectionChanged: (selection) {
        setState(() => _deepl = selection.first);
        _retranslate();
      },
    );
  }

  Widget _sourcePanel(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _source,
                focusNode: _sourceFocus,
                expands: true,
                maxLines: null,
                minLines: null,
                textAlignVertical: TextAlignVertical.top,
                inputFormatters: _sourceRussian ? [TransliterationFormatter()] : null,
                style: TextStyle(fontSize: 18, height: 1.4, color: context.c.foreground),
                decoration: InputDecoration.collapsed(
                  hintText: _sourceRussian ? 'privet — привет...' : 'Wpisz tekst...',
                  hintStyle: TextStyle(fontSize: 18, color: context.c.mutedForeground),
                ),
              ),
            ),
          ),
          Divider(height: 1, color: context.c.border),
          _footer(
            context,
            speakLang: _srcLang,
            speakText: _source.text,
            action: TextButton(onPressed: () => _source.clear(), child: const Text('Wyczyść')),
          ),
        ],
      ),
    );
  }

  Widget _resultPanel(BuildContext context) {
    final Widget body;
    if (_error != null) {
      body = _hint(context, _error!, color: context.c.destructive);
    } else if (_loading) {
      body = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2, color: context.c.mutedForeground),
          ),
          const SizedBox(width: 10),
          Text('Tłumaczę…', style: TextStyle(fontSize: 14, color: context.c.mutedForeground)),
        ],
      );
    } else if (_result.isEmpty) {
      body = _hint(context, 'Tłumaczenie pojawi się tutaj.');
    } else {
      body = SelectableText(_result, style: TextStyle(fontSize: 18, height: 1.4, color: context.c.foreground));
    }
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Align(alignment: Alignment.topLeft, child: body),
            ),
          ),
          Divider(height: 1, color: context.c.border),
          _footer(
            context,
            speakLang: _dstLang,
            speakText: _result,
            action: TextButton.icon(
              onPressed: _result.isEmpty
                  ? null
                  : () async {
                      await Clipboard.setData(ClipboardData(text: _result));
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(const SnackBar(
                          content: Text('Skopiowano do schowka'),
                          duration: Duration(seconds: 2),
                        ));
                    },
              icon: const Icon(Icons.copy, size: 16),
              label: const Text('Kopiuj'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _footer(BuildContext context, {required String speakLang, required String speakText, required Widget action}) {
    final enabled = speakText.trim().isNotEmpty;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          IconButton(
            onPressed: enabled ? () => _speak(context, speakText, speakLang) : null,
            icon: const Icon(Icons.volume_up_outlined, size: 18),
            color: context.c.mutedForeground,
            tooltip: 'Wymów',
            visualDensity: VisualDensity.compact,
          ),
          const Spacer(),
          action,
        ],
      ),
    );
  }

  Widget _hint(BuildContext context, String text, {Color? color}) {
    return Text(text, style: TextStyle(fontSize: 14, color: color ?? context.c.mutedForeground));
  }
}
