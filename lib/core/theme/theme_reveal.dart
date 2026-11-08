import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

enum ThemeRevealDirection { leftToRight, rightToLeft }

/// Reveals the new theme beneath the previous screen.
class ThemeReveal extends StatefulWidget {
  const ThemeReveal({required this.child, super.key});

  final Widget child;

  static ThemeRevealState? maybeOf(BuildContext context) =>
      context.findAncestorStateOfType<ThemeRevealState>();

  @override
  State<ThemeReveal> createState() => ThemeRevealState();
}

class ThemeRevealState extends State<ThemeReveal>
    with SingleTickerProviderStateMixin {
  final _boundary = GlobalKey();
  late final AnimationController _progress;
  late final Animation<double> _reveal;
  ui.Image? _snapshot;
  ThemeRevealDirection _direction = ThemeRevealDirection.leftToRight;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _progress = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _reveal = CurvedAnimation(parent: _progress, curve: Curves.easeInOutCubic);
  }

  Future<void> run(
    VoidCallback change, {
    required ThemeRevealDirection direction,
  }) async {
    if (_busy) {
      return;
    }
    if (MediaQuery.disableAnimationsOf(context)) {
      change();
      return;
    }
    _busy = true;
    try {
      var timedOut = false;
      final capture = _capture();
      unawaited(
        capture.then((lateImage) {
          if (timedOut) {
            lateImage?.dispose();
          }
        }),
      );
      final image = await capture.timeout(
        const Duration(milliseconds: 350),
        onTimeout: () {
          timedOut = true;
          return null;
        },
      );
      if (!mounted) {
        image?.dispose();
        return;
      }
      if (image == null) {
        change();
        return;
      }

      _progress.value = 0;
      setState(() {
        _snapshot = image;
        _direction = direction;
      });
      await WidgetsBinding.instance.endOfFrame;
      change();
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) {
        return;
      }
      await _progress.forward(from: 0);
    } finally {
      _busy = false;
      if (mounted) {
        final old = _snapshot;
        setState(() => _snapshot = null);
        old?.dispose();
      }
    }
  }

  Future<ui.Image?> _capture() async {
    try {
      var boundary =
          _boundary.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) {
        return null;
      }
      for (var i = 0; i < 3 && boundary!.debugNeedsPaint; i++) {
        await WidgetsBinding.instance.endOfFrame;
        if (!mounted) {
          return null;
        }
        boundary =
            _boundary.currentContext?.findRenderObject()
                as RenderRepaintBoundary?;
      }
      if (boundary == null || boundary.debugNeedsPaint) {
        return null;
      }
      final ratio = MediaQuery.devicePixelRatioOf(context).clamp(1.0, 2.0);
      return await boundary.toImage(pixelRatio: ratio);
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    _progress.dispose();
    _snapshot?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.passthrough,
    children: [
      RepaintBoundary(key: _boundary, child: widget.child),
      if (_snapshot != null)
        Positioned.fill(
          child: AbsorbPointer(
            child: ClipRect(
              key: const ValueKey('theme-reveal-wipe'),
              clipper: _OldThemeClip(reveal: _reveal, direction: _direction),
              child: RawImage(image: _snapshot, fit: BoxFit.fill),
            ),
          ),
        ),
    ],
  );
}

class _OldThemeClip extends CustomClipper<Rect> {
  _OldThemeClip({required this.reveal, required this.direction})
    : super(reclip: reveal);

  final Animation<double> reveal;
  final ThemeRevealDirection direction;

  @override
  Rect getClip(Size size) => switch (direction) {
    ThemeRevealDirection.leftToRight => Rect.fromLTRB(
      size.width * reveal.value,
      0,
      size.width,
      size.height,
    ),
    ThemeRevealDirection.rightToLeft => Rect.fromLTRB(
      0,
      0,
      size.width * (1 - reveal.value),
      size.height,
    ),
  };

  @override
  bool shouldReclip(_OldThemeClip oldClipper) =>
      oldClipper.reveal != reveal || oldClipper.direction != direction;
}
