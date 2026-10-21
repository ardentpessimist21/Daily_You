// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:async';

import 'package:flutter/rendering.dart';
import 'package:material_ui/material_ui.dart';

/// Calls [onDoubleTap] when an empty part of [child] is double-tapped.
/// Double-tapping text is left alone, so it still selects a word.
///
/// It only watches pointers (it never joins the gesture arena), so taps,
/// scrolling, swiping between entries and text selection work as before.
class DoubleTapToEdit extends StatefulWidget {
  const DoubleTapToEdit(
      {super.key, required this.onDoubleTap, required this.child});

  final VoidCallback onDoubleTap;
  final Widget child;

  @override
  State<DoubleTapToEdit> createState() => _DoubleTapToEditState();
}

class _DoubleTapToEditState extends State<DoubleTapToEdit> {
  static const Duration _window = Duration(milliseconds: 300);
  static const double _slop = 24;

  int? _pointer;
  Offset? _downAt;
  bool _moved = false;

  /// Whether the current press started on text. Checked when the finger
  /// goes down, before scrolling can make the list ignore hit tests.
  bool _downOnText = false;

  /// Where the first tap of a possible double tap landed, until the window
  /// for the second one closes.
  Offset? _lastTapAt;
  Timer? _windowTimer;

  void _onDown(PointerDownEvent event) {
    if (_pointer != null) {
      // A second finger: not a tap.
      _reset();
      return;
    }
    _pointer = event.pointer;
    _downAt = event.position;
    _moved = false;
    _downOnText = _isOnText(event.position);
  }

  void _onMove(PointerMoveEvent event) {
    if (event.pointer != _pointer || _downAt == null) return;
    if ((event.position - _downAt!).distance > _slop) _moved = true;
  }

  void _onUp(PointerUpEvent event) {
    if (event.pointer != _pointer) return;
    _pointer = null;
    if (_moved) {
      _clearFirstTap();
      return;
    }
    final previousAt = _lastTapAt;
    if (previousAt != null &&
        (event.position - previousAt).distance <= _slop * 2) {
      _clearFirstTap();
      if (!_downOnText) widget.onDoubleTap();
      return;
    }
    _lastTapAt = event.position;
    _windowTimer?.cancel();
    _windowTimer = Timer(_window, _clearFirstTap);
  }

  void _clearFirstTap() {
    _windowTimer?.cancel();
    _windowTimer = null;
    _lastTapAt = null;
  }

  void _reset() {
    _pointer = null;
    _clearFirstTap();
  }

  @override
  void dispose() {
    _windowTimer?.cancel();
    super.dispose();
  }

  bool _isOnText(Offset globalPosition) {
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.attached) return true;
    final result = BoxHitTestResult();
    box.hitTest(result, position: box.globalToLocal(globalPosition));
    return result.path.any((entry) => entry.target is RenderParagraph);
  }

  @override
  Widget build(BuildContext context) => Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: _onDown,
        onPointerMove: _onMove,
        onPointerUp: _onUp,
        onPointerCancel: (_) => _reset(),
        child: widget.child,
      );
}
