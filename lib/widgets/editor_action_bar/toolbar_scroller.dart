// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/config_provider.dart';
import 'package:material_ui/material_ui.dart';

/// The editor toolbar when its buttons don't fit (3.7.0.64): they scroll
/// sideways instead of going into a ⋯ menu. The edges fade where there's
/// more, with a ‹ or › to tap that scrolls that way. It opens where you
/// left it last time.
class ToolbarScroller extends StatefulWidget {
  const ToolbarScroller({
    super.key,
    required this.width,
    required this.height,
    required this.children,
  });

  final double width;
  final double height;
  final List<Widget> children;

  /// Where it was left, kept while the app runs and saved for next time.
  static double? _lastOffset;

  @override
  State<ToolbarScroller> createState() => _ToolbarScrollerState();
}

class _ToolbarScrollerState extends State<ToolbarScroller> {
  static const double _fade = 28;
  static const double _arrowSize = 26;

  late final ScrollController _controller = ScrollController(
      initialScrollOffset: ToolbarScroller._lastOffset ??
          ConfigProvider.instance.get(Settings.editorToolbarScroll).toDouble());

  bool _canLeft = false;
  bool _canRight = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_update);
    WidgetsBinding.instance.addPostFrameCallback((_) => _update());
  }

  void _update() {
    if (!mounted || !_controller.hasClients) return;
    final position = _controller.position;
    if (!position.hasContentDimensions) return;
    final left = position.pixels > 1;
    final right = position.pixels < position.maxScrollExtent - 1;
    if (left != _canLeft || right != _canRight) {
      setState(() {
        _canLeft = left;
        _canRight = right;
      });
    }
  }

  void _save() {
    if (!_controller.hasClients) return;
    final offset = _controller.offset;
    ToolbarScroller._lastOffset = offset;
    ConfigProvider.instance.set(Settings.editorToolbarScroll, offset.round());
  }

  void _step(int direction) {
    if (!_controller.hasClients) return;
    final position = _controller.position;
    final target = (position.pixels + direction * widget.width * 0.6)
        .clamp(0.0, position.maxScrollExtent);
    _controller
        .animateTo(target,
            duration: const Duration(milliseconds: 250), curve: Curves.easeOut)
        .then((_) => _save());
  }

  @override
  void dispose() {
    if (_controller.hasClients) {
      ToolbarScroller._lastOffset = _controller.offset;
    }
    _controller.dispose();
    super.dispose();
  }

  Widget _arrow(BuildContext context, {required bool left}) {
    final colorScheme = Theme.of(context).colorScheme;
    final visible = left ? _canLeft : _canRight;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 150),
      opacity: visible ? 1 : 0,
      child: IgnorePointer(
        ignoring: !visible,
        child: SizedBox(
          width: _arrowSize,
          height: _arrowSize,
          child: IconButton(
            padding: EdgeInsets.zero,
            iconSize: 18,
            style: IconButton.styleFrom(
              backgroundColor:
                  colorScheme.surfaceContainerHighest.withValues(alpha: 0.92),
              foregroundColor: colorScheme.onSurface,
            ),
            tooltip: left
                ? MaterialLocalizations.of(context).previousPageTooltip
                : MaterialLocalizations.of(context).nextPageTooltip,
            icon: Icon(left
                ? Icons.chevron_left_rounded
                : Icons.chevron_right_rounded),
            onPressed: () => _step(left ? -1 : 1),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fadeStop = (_fade / widget.width).clamp(0.0, 0.4);
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: Stack(
        alignment: Alignment.center,
        children: [
          ShaderMask(
            shaderCallback: (rect) => LinearGradient(
              colors: [
                _canLeft ? Colors.transparent : Colors.black,
                Colors.black,
                Colors.black,
                _canRight ? Colors.transparent : Colors.black,
              ],
              stops: [0, fadeStop, 1 - fadeStop, 1],
            ).createShader(rect),
            blendMode: BlendMode.dstIn,
            child: NotificationListener<ScrollEndNotification>(
              onNotification: (_) {
                _save();
                return false;
              },
              child: SingleChildScrollView(
                controller: _controller,
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: widget.children,
                ),
              ),
            ),
          ),
          Positioned(left: 0, child: _arrow(context, left: true)),
          Positioned(right: 0, child: _arrow(context, left: false)),
        ],
      ),
    );
  }
}
