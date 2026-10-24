// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:async';

import 'package:daily_you/widgets/editor_action_bar.dart';
import 'package:daily_you/widgets/editor_action_bar/dock_metrics.dart';
import 'package:daily_you/widgets/editor_action_bar/editor_keyboard_session.dart';
import 'package:material_ui/material_ui.dart';

/// Holds an editor page's body and its action bar.
///
/// While the keyboard slides in or out, only the action bar follows it. The
/// body keeps its size until the keyboard stops, then resizes once (fork,
/// Update L2): resizing it on every frame of the slide meant rebuilding,
/// restyling and repainting the whole entry ~15 times, which stuttered on
/// long entries. This is how native Android text apps behave too.
///
/// The host Scaffold must not resize for the keyboard itself:
/// `resizeToAvoidBottomInset: false`.
class EditorActionBarOverlay extends StatefulWidget {
  final Widget body;
  final EditorActionBar actionBar;

  const EditorActionBarOverlay({
    super.key,
    required this.body,
    required this.actionBar,
  });

  /// How long the keyboard has to stay still before the body resizes
  @visibleForTesting
  static Duration settleDelay = const Duration(milliseconds: 60);

  @override
  State<EditorActionBarOverlay> createState() => _EditorActionBarOverlayState();
}

class _EditorActionBarOverlayState extends State<EditorActionBarOverlay>
    with TickerProviderStateMixin {
  // Android's InsetsController animation curves
  static const _showCurve = Cubic(0.0, 0.0, 0.2, 1.0);
  static const _hideCurve = Cubic(0.4, 0.0, 1.0, 1.0);
  static const _imeAnimationDuration = Duration(milliseconds: 200);

  /// The action bar's dock animation, which follows the keyboard
  late final AnimationController _dockController;

  /// The dock state the body sees: only changes when the body resizes, so
  /// the body's spacing for the bar doesn't rebuild it on every frame
  late final AnimationController _bodyDock;
  late EditorKeyboardSession _session;

  late bool _docked;

  /// Keyboard height right now
  double _liveInset = 0;

  /// Keyboard height the body is laid out for
  double _bodyInset = 0;
  Timer? _settleTimer;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _dockController = AnimationController(vsync: this);
    _bodyDock = AnimationController(vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final inset = MediaQuery.viewInsetsOf(context).bottom;
    if (!_started) {
      // The keyboard may already be up
      _started = true;
      _liveInset = _bodyInset = inset;
      _docked = inset > 0;
      _dockController.value = _bodyDock.value = _docked ? 1.0 : 0.0;
      _session = EditorKeyboardSession(
          focusNode: widget.actionBar.focusNode, initialInset: inset);
      _session.addListener(_syncDocked);
      return;
    }
    _noteInset(inset);
  }

  void _noteInset(double inset) {
    if (inset == _liveInset) return;
    final rising = inset > _liveInset;
    _liveInset = inset;
    _session.noteKeyboardInset(inset);
    _syncDocked();

    if (!rising && _bodyInset > 0) {
      // Closing: the body takes the whole height straight away. The
      // keyboard is still covering the bottom, so nothing shows a gap.
      _bodyInset = 0;
    }
    _settleTimer?.cancel();
    _settleTimer = Timer(EditorActionBarOverlay.settleDelay, _settle);
  }

  /// The keyboard has stopped: lay the body out for where it ended up
  void _settle() {
    _settleTimer = null;
    if (!mounted) return;
    final grew = _liveInset > _bodyInset;
    final dock = _docked ? 1.0 : 0.0;
    if (_liveInset == _bodyInset && _bodyDock.value == dock) return;
    setState(() {
      _bodyInset = _liveInset;
      _bodyDock.value = dock;
    });
    if (grew) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _revealCaret());
    }
  }

  /// Text fields normally scroll their cursor clear of the keyboard as it
  /// rises. The body only shrinks once the keyboard has stopped, so do the
  /// same then.
  void _revealCaret() {
    if (!mounted) return;
    final focusContext = FocusManager.instance.primaryFocus?.context;
    if (focusContext == null || !focusContext.mounted) return;
    final editable = focusContext.findAncestorStateOfType<EditableTextState>();
    if (editable == null || !editable.mounted) return;
    final selection = editable.textEditingValue.selection;
    if (!selection.isValid) return;
    final render = editable.renderEditable;
    if (!render.attached || !render.hasSize) return;
    final caret = render.getLocalRectForCaret(selection.extent);
    render.showOnScreen(
      rect: editable.widget.scrollPadding.inflateRect(caret),
      duration: Duration.zero,
    );
  }

  void _syncDocked() => _setDocked(_session.isUp);

  void _setDocked(bool docked) {
    if (docked == _docked) return;
    _docked = docked;
    _dockController.animateTo(docked ? 1.0 : 0.0,
        duration: _imeAnimationDuration,
        curve: docked ? _showCurve : _hideCurve);
    // Without the keyboard moving (e.g. focus left the editor), the body
    // follows right away; otherwise it waits for the keyboard to stop
    _settleTimer ??= Timer(EditorActionBarOverlay.settleDelay, _settle);
  }

  @override
  void didUpdateWidget(covariant EditorActionBarOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.actionBar.focusNode != widget.actionBar.focusNode) {
      _session.removeListener(_syncDocked);
      _session.dispose();
      _session = EditorKeyboardSession(
          focusNode: widget.actionBar.focusNode, initialInset: _liveInset);
      _session.addListener(_syncDocked);
      _syncDocked();
    }
  }

  @override
  void dispose() {
    _settleTimer?.cancel();
    _session.removeListener(_syncDocked);
    _session.dispose();
    _dockController.dispose();
    _bodyDock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    // On Android the bottom padding (gesture/nav bar) shrinks as the
    // keyboard covers it. The body gets the values for its own inset, so
    // nothing in it changes until it resizes.
    MediaQueryData forInset(double inset) => media.copyWith(
          viewInsets: media.viewInsets.copyWith(bottom: inset),
          padding: media.padding.copyWith(
              bottom: (media.viewPadding.bottom - inset)
                  .clamp(0.0, media.viewPadding.bottom)),
        );

    return EditorKeyboardSessionScope(
      session: _session,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            right: 0,
            bottom: _bodyInset,
            child: MediaQuery(
              data: forInset(_bodyInset),
              child: DockProgressScope(
                progress: _bodyDock,
                // Moving the bar doesn't repaint the entry under it
                child: RepaintBoundary(child: widget.body),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: _liveInset,
            child: MediaQuery(
              data: forInset(_liveInset),
              child: DockProgressScope(
                progress: _dockController,
                child: RepaintBoundary(
                  child: TextFieldTapRegion(child: widget.actionBar),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
