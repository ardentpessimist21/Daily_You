// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

/// A date typed into a fixed template (3.7.0.50), e.g. `mm / dd / yyyy`.
///
/// Each part is its own small box inside one outlined field, so its hint
/// (mm, dd, yyyy) stays in place until it's filled. A full part moves on to
/// the next one; Backspace in an empty part goes back to the one before.
/// Tapping a part edits just that part.
class DateTemplateBox extends StatefulWidget {
  const DateTemplateBox({
    super.key,
    required this.order,
    required this.separator,
    required this.label,
    required this.onChanged,
    required this.onSubmitted,
    this.errorText,
    this.autofocus = true,
  });

  /// 'd', 'M' and 'y' in the order they are typed.
  final List<String> order;
  final String separator;
  final String label;
  final String? errorText;
  final bool autofocus;

  /// Every change, with the parts keyed 'd', 'M' and 'y'.
  final void Function(Map<String, String> parts) onChanged;

  /// Done on the keyboard.
  final VoidCallback onSubmitted;

  @override
  State<DateTemplateBox> createState() => _DateTemplateBoxState();
}

class _DateTemplateBoxState extends State<DateTemplateBox> {
  late final Map<String, TextEditingController> _text = {
    for (final part in widget.order) part: TextEditingController(),
  };
  late final Map<String, FocusNode> _focus = {
    for (final part in widget.order)
      part: FocusNode(onKeyEvent: (node, event) => _onKey(part, event)),
  };

  static int _lengthOf(String part) => part == 'y' ? 4 : 2;

  static String _hintOf(String part) => switch (part) {
        'd' => 'dd',
        'M' => 'mm',
        _ => 'yyyy',
      };

  @override
  void initState() {
    super.initState();
    for (final node in _focus.values) {
      node.addListener(() {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    for (final controller in _text.values) {
      controller.dispose();
    }
    for (final node in _focus.values) {
      node.dispose();
    }
    super.dispose();
  }

  Map<String, String> get _parts =>
      {for (final part in widget.order) part: _text[part]!.text};

  void _changed(String part, String value) {
    widget.onChanged(_parts);
    final index = widget.order.indexOf(part);
    if (value.length >= _lengthOf(part) && index < widget.order.length - 1) {
      _focusPart(widget.order[index + 1]);
    }
  }

  /// Backspace in an empty part goes back and removes the last digit there.
  KeyEventResult _onKey(String part, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    if (event.logicalKey != LogicalKeyboardKey.backspace) {
      return KeyEventResult.ignored;
    }
    final controller = _text[part]!;
    final index = widget.order.indexOf(part);
    if (controller.text.isNotEmpty || index == 0) {
      return KeyEventResult.ignored;
    }
    final previous = widget.order[index - 1];
    final before = _text[previous]!;
    if (before.text.isNotEmpty) {
      before.text = before.text.substring(0, before.text.length - 1);
      widget.onChanged(_parts);
    }
    _focusPart(previous);
    return KeyEventResult.handled;
  }

  void _focusPart(String part) {
    _focus[part]!.requestFocus();
    final controller = _text[part]!;
    controller.selection =
        TextSelection.collapsed(offset: controller.text.length);
  }

  /// Tapping the field outside the parts goes to the first unfilled one.
  void _focusFirstOpen() {
    for (final part in widget.order) {
      if (_text[part]!.text.length < _lengthOf(part)) {
        _focusPart(part);
        return;
      }
    }
    _focusPart(widget.order.last);
  }

  double _widthOf(String part, TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(text: part == 'y' ? '0000' : '00', style: style),
      textDirection: TextDirection.ltr,
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();
    final hint = TextPainter(
      text: TextSpan(text: _hintOf(part), style: style),
      textDirection: TextDirection.ltr,
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();
    return (painter.width > hint.width ? painter.width : hint.width) + 4;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.titleMedium ?? const TextStyle(fontSize: 16);
    final hintStyle =
        style.copyWith(color: theme.colorScheme.onSurfaceVariant.withValues(
      alpha: 0.6,
    ));
    final focused = _focus.values.any((node) => node.hasFocus);
    final children = <Widget>[];
    for (var i = 0; i < widget.order.length; i++) {
      final part = widget.order[i];
      if (i > 0) {
        children.add(Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Text(widget.separator,
              style: style.copyWith(
                  color: theme.colorScheme.onSurfaceVariant)),
        ));
      }
      final last = i == widget.order.length - 1;
      children.add(SizedBox(
        width: _widthOf(part, style),
        child: TextField(
          key: ValueKey('jump-date-$part'),
          controller: _text[part],
          focusNode: _focus[part],
          autofocus: widget.autofocus && i == 0,
          keyboardType: TextInputType.number,
          textInputAction: last ? TextInputAction.done : TextInputAction.next,
          textAlign: TextAlign.center,
          style: style,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(_lengthOf(part)),
          ],
          onChanged: (value) => _changed(part, value),
          onSubmitted: (_) {
            if (last) {
              widget.onSubmitted();
            } else {
              _focusPart(widget.order[i + 1]);
            }
          },
          decoration: InputDecoration(
            isCollapsed: true,
            border: InputBorder.none,
            hintText: _hintOf(part),
            hintStyle: hintStyle,
          ),
        ),
      ));
    }

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: _focusFirstOpen,
      child: InputDecorator(
        isFocused: focused,
        isEmpty: false,
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          labelText: widget.label,
          errorText: widget.errorText,
          errorMaxLines: 3,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        ),
        child: Row(children: children),
      ),
    );
  }
}
