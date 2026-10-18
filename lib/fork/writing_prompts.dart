// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:math';

import 'package:daily_you/config_provider.dart';

/// Gentle questions shown as the placeholder of a new, empty entry. They're
/// only hint text: never saved, gone as soon as you type.
class WritingPrompts {
  static const List<String> _prompts = [
    'What made you smile today?',
    'What was the best part of your day?',
    'What are you grateful for right now?',
    'What happened today that you want to remember?',
    'How are you feeling, honestly?',
    'What did you learn today?',
    'Who made a difference to your day?',
    'What was harder than expected today?',
    'What would make tomorrow a good day?',
    "What's on your mind right now?",
    'What did you do just for yourself today?',
    'What small win can you celebrate today?',
    'What surprised you today?',
    'What do you want to let go of?',
    'Describe today in three words.',
  ];

  /// A random prompt, or null when prompts are off or the app isn't in
  /// English (the prompts aren't translated yet).
  static String? pick(String languageCode) {
    if (!ConfigProvider.instance.get(Settings.writingPrompts)) return null;
    if (languageCode != 'en') return null;
    return _prompts[Random().nextInt(_prompts.length)];
  }
}
