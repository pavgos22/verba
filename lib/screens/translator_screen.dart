import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/transliteration.dart';
import '../data/settings_store.dart';
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
  String _result = '';
  bool _loading = false;
  String? _error;
  int _reqId = 0;

  String get _from => _ruToPl ? 'RU' : 'PL';
  String get _to => _ruToPl ? 'PL' : 'RU';
  bool get _sourceRussian => _ruToPl;

  @override
  void initState() {
    super.initState();
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
    try {
      final out = await ref.read(translationServiceProvider).translate(text, from: _from, to: _to);
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

  void _swap() {
    final newSource = _result;
    setState(() {
      _ruToPl = !_ruToPl;
      _result = _source.text;
    });
    _source.text = newSource;
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
    final srcLabel = _sourceRussian ? 'Rosyjski' : 'Polski';
    final dstLabel = _sourceRussian ? 'Polski' : 'Rosyjski';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tłumacz', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: context.c.foreground)),
          const SizedBox(height: 4),
          Text('Tłumaczenie rosyjski ↔ polski · ${hasKey ? 'DeepL' : 'MyMemory'}',
              style: TextStyle(fontSize: 14, color: context.c.mutedForeground)),
          const SizedBox(height: 20),
          Row(
            children: [
              Text(srcLabel, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: context.c.foreground)),
              IconButton(
                onPressed: _swap,
                icon: Icon(Icons.swap_horiz, size: 20, color: context.c.mutedForeground),
                tooltip: 'Zamień kierunek',
              ),
              Text(dstLabel, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: context.c.foreground)),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 200,
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
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => _source.clear(),
              child: const Text('Wyczyść'),
            ),
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
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
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

  Widget _hint(BuildContext context, String text, {Color? color}) {
    return Text(text, style: TextStyle(fontSize: 14, color: color ?? context.c.mutedForeground));
  }
}
