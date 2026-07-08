import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/settings_store.dart';

final themeFadeKey = GlobalKey<ThemeFadeState>();

Future<void> switchThemeAnimated(WidgetRef ref, ThemeMode mode) async {
  final fade = themeFadeKey.currentState;
  await fade?.capture();
  ref.read(settingsProvider.notifier).setThemeMode(mode);
  fade?.startFade();
}

class ThemeFade extends StatefulWidget {
  const ThemeFade({super.key, required this.child});

  final Widget child;

  @override
  State<ThemeFade> createState() => ThemeFadeState();
}

class ThemeFadeState extends State<ThemeFade> with SingleTickerProviderStateMixin {
  final _boundaryKey = GlobalKey();
  ui.Image? _snapshot;
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
  late final Animation<double> _opacity =
      Tween(begin: 1.0, end: 0.0).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

  @override
  void initState() {
    super.initState();
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _snapshot?.dispose();
          _snapshot = null;
        });
      }
    });
  }

  @override
  void dispose() {
    _snapshot?.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> capture() async {
    final boundary = _boundaryKey.currentContext?.findRenderObject();
    if (boundary is! RenderRepaintBoundary) return;
    _controller.stop();
    _controller.value = 0;
    final image = await boundary.toImage(pixelRatio: MediaQuery.devicePixelRatioOf(context));
    if (!mounted) {
      image.dispose();
      return;
    }
    setState(() {
      _snapshot?.dispose();
      _snapshot = image;
    });
    await WidgetsBinding.instance.endOfFrame;
  }

  void startFade() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _snapshot != null) _controller.forward(from: 0);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      textDirection: TextDirection.ltr,
      children: [
        RepaintBoundary(key: _boundaryKey, child: widget.child),
        if (_snapshot != null)
          Positioned.fill(
            child: IgnorePointer(
              child: FadeTransition(
                opacity: _opacity,
                child: RawImage(image: _snapshot, fit: BoxFit.fill),
              ),
            ),
          ),
      ],
    );
  }
}
