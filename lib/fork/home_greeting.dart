// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:math';

import 'package:daily_you/config_provider.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:flutter/widgets.dart';

enum _DayPart { morning, afternoon, evening, night }

/// The Home page title: a time-of-day greeting, optionally with your name.
class HomeGreeting {
  static const String styleClassic = 'classic';
  static const String stylePlayful = 'playful';

  /// Longest name the greeting keeps, so it still fits the top bar.
  static const int maxNameLength = 20;

  /// The saved name, trimmed and capped to [maxNameLength].
  static String name() {
    final name = ConfigProvider.instance.get(Settings.homeGreetingName).trim();
    return name.length > maxNameLength
        ? name.substring(0, maxNameLength).trimRight()
        : name;
  }

  // Each line comes with and without a name, so it always reads naturally.
  static const Map<_DayPart, List<(String, String)>> _playful = {
    _DayPart.morning: [
      ('Rise and shine, {n}', 'Rise and shine'),
      ('Coffee first, {n}?', 'Coffee first?'),
      ('Fresh page, {n}', 'Fresh page today'),
      ('Morning, sunshine {n}', 'Morning, sunshine'),
      ("Up and at 'em, {n}", "Up and at 'em"),
      ('New day, who dis? Hi {n}', 'New day, who dis?'),
    ],
    _DayPart.afternoon: [
      ('Afternoon, {n}', 'Good afternoon'),
      ("Snack o'clock, {n}", "Snack o'clock"),
      ('Halfway there, {n}', 'Halfway there'),
      ("Hey {n}, how's it going?", "Hey, how's it going?"),
      ('Still standing, {n}?', 'Still standing?'),
      ('Tea break, {n}?', 'Tea break?'),
    ],
    _DayPart.evening: [
      ('Evening, {n}', 'Good evening'),
      ('How was today, {n}?', 'How was today?'),
      ('Kick your feet up, {n}', 'Kick your feet up'),
      ('Time to spill the tea, {n}', 'Time to spill the tea'),
      ("Dear diary... it's {n}", 'Dear diary...'),
      ("Day's done, {n}", "Day's done"),
    ],
    _DayPart.night: [
      ('Still up, {n}?', 'Still up?'),
      ('Hello, night owl {n}', 'Hello, night owl'),
      ('Midnight thoughts, {n}?', 'Midnight thoughts?'),
      ('Burning the midnight oil, {n}?', 'Burning the midnight oil?'),
      ("Shh, the diary's sleepy, {n}", "Shh, the diary's sleepy"),
      ("Can't sleep either, {n}?", "Can't sleep either?"),
    ],
  };

  // One playful line per time of day for as long as the app stays open, so
  // the title doesn't change every time the screen redraws.
  static final Map<_DayPart, (String, String)> _chosen = {};

  static _DayPart _partOf(DateTime time) {
    final hour = time.hour;
    if (hour >= 5 && hour < 12) return _DayPart.morning;
    if (hour >= 12 && hour < 18) return _DayPart.afternoon;
    if (hour >= 18 && hour < 22) return _DayPart.evening;
    return _DayPart.night;
  }

  /// The greeting to show, or null when the greeting is switched off.
  static String? text(AppLocalizations l10n, String languageCode) {
    final config = ConfigProvider.instance;
    if (!config.get(Settings.homeGreetingEnabled)) return null;

    final name = HomeGreeting.name();
    final part = _partOf(DateTime.now());
    final playful = config.get(Settings.homeGreetingStyle) == stylePlayful &&
        languageCode == 'en';

    if (playful) {
      final (withName, withoutName) = _chosen[part] ??= _pick(part);
      return name.isEmpty ? withoutName : withName.replaceAll('{n}', name);
    }

    final classic = switch (part) {
      _DayPart.morning => l10n.greetingMorning,
      _DayPart.afternoon => l10n.greetingAfternoon,
      _DayPart.evening => l10n.greetingEvening,
      _DayPart.night => l10n.greetingNight,
    };
    return name.isEmpty ? classic : '$classic, $name';
  }

  // Never repeats the previous app open's line for the same time of day.
  static (String, String) _pick(_DayPart part) {
    final config = ConfigProvider.instance;
    final options = _playful[part]!;
    final last = config.get(Settings.homeGreetingLastLine);
    final fresh = options.where((option) => option.$1 != last).toList();
    final choice = fresh[Random().nextInt(fresh.length)];
    // Saved after this frame: changing a setting mid-build isn't allowed
    Future.microtask(
        () => config.set(Settings.homeGreetingLastLine, choice.$1));
    return choice;
  }
}

/// Shows the greeting with the name in italics. A greeting too wide for the
/// top bar shrinks to fit, down to 80% size, and only then gets "…".
class HomeGreetingTitle extends StatelessWidget {
  final String text;

  const HomeGreetingTitle(this.text, {super.key});

  static const double _minScale = 0.8;

  List<InlineSpan> _spans(String name) {
    final index = name.isEmpty ? -1 : text.lastIndexOf(name);
    if (index < 0) return [TextSpan(text: text)];
    return [
      TextSpan(text: text.substring(0, index)),
      TextSpan(text: name, style: const TextStyle(fontStyle: FontStyle.italic)),
      TextSpan(text: text.substring(index + name.length)),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final span = TextSpan(children: _spans(HomeGreeting.name()));
    return LayoutBuilder(builder: (context, constraints) {
      final style = DefaultTextStyle.of(context).style;
      final textScaler = MediaQuery.textScalerOf(context);
      final painter = TextPainter(
        text: TextSpan(style: style, children: [span]),
        textDirection: Directionality.of(context),
        textScaler: textScaler,
        maxLines: 1,
      )..layout();
      final width = painter.width;
      painter.dispose();
      var scale = 1.0;
      if (constraints.hasBoundedWidth && width > constraints.maxWidth) {
        scale = max(_minScale, constraints.maxWidth / width);
      }
      return Text.rich(
        span,
        maxLines: 1,
        softWrap: false,
        overflow: TextOverflow.ellipsis,
        style: scale < 1 && style.fontSize != null
            ? TextStyle(fontSize: style.fontSize! * scale)
            : null,
      );
    });
  }
}
