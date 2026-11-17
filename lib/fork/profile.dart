// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:math';

import 'package:daily_you/config_provider.dart';
import 'package:daily_you/fork/home_greeting.dart';
import 'package:daily_you/widgets/settings_group.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

/// Update P: your name and birthday. The name feeds the Home greeting; the
/// birthday turns that day's greeting and reminder into a birthday one.
/// Both stay on the phone (and in backups).
class Profile {
  static const int firstYear = 1950;

  /// The saved birthday, or null when none is set.
  static DateTime? birthday() {
    final raw = ConfigProvider.instance.get<String>(Settings.profileBirthday);
    if (raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  static Future<void> setBirthday(DateTime? day) => ConfigProvider.instance.set(
      Settings.profileBirthday,
      day == null ? '' : DateFormat('yyyy-MM-dd').format(day));

  /// Whether [now] is the birthday (29 Feb counts on 28 Feb in other years).
  static bool isBirthday([DateTime? now]) {
    final day = birthday();
    if (day == null) return false;
    return isBirthdayOn(day, now ?? DateTime.now());
  }

  static bool isBirthdayOn(DateTime day, DateTime today) {
    if (day.month == today.month && day.day == today.day) return true;
    final leap = DateTime(today.year, 3, 0).day == 29;
    return day.month == 2 &&
        day.day == 29 &&
        !leap &&
        today.month == 2 &&
        today.day == 28;
  }

  /// Age reached on this year's birthday.
  static int? ageThisYear([DateTime? now]) {
    final day = birthday();
    if (day == null) return null;
    final age = (now ?? DateTime.now()).year - day.year;
    return age > 0 && age < 130 ? age : null;
  }

  static String ordinal(int n) {
    final rest = n % 100;
    if (rest >= 11 && rest <= 13) return '${n}th';
    return switch (n % 10) {
      1 => '${n}st',
      2 => '${n}nd',
      3 => '${n}rd',
      _ => '${n}th',
    };
  }

  // Birthday greetings for Home, with and without a name.

  static const List<(String, String)> _playful = [
    ('Happy birthday, {n}!', 'Happy birthday!'),
    ("It's your day, {n}", "It's your day"),
    ("Cake o'clock, {n}", "Cake o'clock"),
    ('Another lap around the sun, {n}', 'Another lap around the sun'),
    ('Make a wish, {n}', 'Make a wish'),
  ];
  static (String, String)? _chosen;

  /// Home greeting on the birthday, or null on other days.
  static String? birthdayGreeting(
      {required bool playful, required bool english}) {
    if (!isBirthday() || !english) return null;
    final name = HomeGreeting.name();
    if (!playful) {
      return name.isEmpty ? 'Happy birthday' : 'Happy birthday, $name';
    }
    final (withName, withoutName) =
        _chosen ??= _playful[Random().nextInt(_playful.length)];
    return name.isEmpty ? withoutName : withName.replaceAll('{n}', name);
  }

  /// The daily reminder's text on the birthday, sometimes with the age.
  static String? birthdayReminder({bool english = true}) {
    if (!isBirthday() || !english) return null;
    final name = HomeGreeting.name();
    final random = Random();
    final age = ageThisYear();
    final happy = age != null && random.nextBool()
        ? 'Happy ${ordinal(age)} birthday'
        : 'Happy birthday';
    final who = name.isEmpty ? '' : ', $name';
    const endings = [
      'Write down how your day went.',
      'Save a moment from your day.',
      'How does it feel? Jot it down.',
    ];
    return '$happy$who! 🎂 ${endings[random.nextInt(endings.length)]}';
  }
}

/// Month, day and year, from [Profile.firstYear] to this year.
class BirthdayPicker extends StatefulWidget {
  const BirthdayPicker({super.key, this.initial, required this.onChanged});

  final DateTime? initial;
  final ValueChanged<DateTime?> onChanged;

  @override
  State<BirthdayPicker> createState() => _BirthdayPickerState();
}

class _BirthdayPickerState extends State<BirthdayPicker> {
  int? _month;
  int? _day;
  int? _year;

  @override
  void initState() {
    super.initState();
    _month = widget.initial?.month;
    _day = widget.initial?.day;
    _year = widget.initial?.year;
  }

  int _daysIn(int? month, int? year) =>
      month == null ? 31 : DateTime(year ?? 2000, month + 1, 0).day;

  void _changed() {
    if (_month != null && _day != null && _year != null) {
      widget.onChanged(DateTime(_year!, _month!, _day!));
    } else {
      widget.onChanged(null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final now = DateTime.now();
    final months = List.generate(12, (i) => i + 1);
    final days = List.generate(_daysIn(_month, _year), (i) => i + 1);
    final years =
        List.generate(now.year - Profile.firstYear + 1, (i) => now.year - i);

    InputDecoration box(String label) => InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        );

    return Row(
      children: [
        Expanded(
          flex: 5,
          child: DropdownButtonFormField<int>(
            initialValue: _month,
            isExpanded: true,
            decoration: box('Month'),
            items: [
              for (final m in months)
                DropdownMenuItem(
                  value: m,
                  child:
                      Text(DateFormat.MMMM(locale).format(DateTime(2000, m))),
                ),
            ],
            onChanged: (m) => setState(() {
              _month = m;
              if (_day != null && _day! > _daysIn(_month, _year)) _day = null;
              _changed();
            }),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 3,
          child: DropdownButtonFormField<int>(
            key: ValueKey('day-$_month-$_year'),
            initialValue: _day,
            isExpanded: true,
            decoration: box('Day'),
            items: [
              for (final d in days)
                DropdownMenuItem(value: d, child: Text('$d')),
            ],
            onChanged: (d) => setState(() {
              _day = d;
              _changed();
            }),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 4,
          child: DropdownButtonFormField<int>(
            initialValue: _year,
            isExpanded: true,
            menuMaxHeight: 320,
            decoration: box('Year'),
            items: [
              for (final y in years)
                DropdownMenuItem(value: y, child: Text('$y')),
            ],
            onChanged: (y) => setState(() {
              _year = y;
              if (_day != null && _day! > _daysIn(_month, _year)) _day = null;
              _changed();
            }),
          ),
        ),
      ],
    );
  }
}

/// First run on a new journal: your name, then (skippable) your birthday.
class ProfileSetupPage extends StatefulWidget {
  const ProfileSetupPage({super.key});

  /// Shows the screens once, when a new journal was just made.
  static Future<void> showIfPending(BuildContext context) async {
    final config = ConfigProvider.instance;
    if (!config.get<bool>(Settings.profileSetupPending)) return;
    await config.set(Settings.profileSetupPending, false);
    if (!context.mounted) return;
    await Navigator.of(context).push(MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => const ProfileSetupPage(),
    ));
  }

  @override
  State<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends State<ProfileSetupPage> {
  final TextEditingController _name = TextEditingController(
      text: ConfigProvider.instance.get<String>(Settings.homeGreetingName));
  bool _onBirthday = false;
  DateTime? _birthday = Profile.birthday();

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _saveName() async {
    await ConfigProvider.instance
        .set(Settings.homeGreetingName, _name.text.trim());
    if (mounted) setState(() => _onBirthday = true);
  }

  Future<void> _finish({required bool saveBirthday}) async {
    if (saveBirthday && _birthday != null) {
      await Profile.setBirthday(_birthday);
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyMedium
        ?.copyWith(color: theme.colorScheme.onSurfaceVariant);

    final nameStep = Column(
      key: const ValueKey('name'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(Icons.waving_hand_outlined,
            size: 40, color: theme.colorScheme.primary),
        const SizedBox(height: 16),
        Text('What should we call you?', style: theme.textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text('Daily You greets you by name on Home.', style: muted),
        const SizedBox(height: 24),
        TextField(
          controller: _name,
          autofocus: true,
          maxLength: HomeGreeting.maxNameLength,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Your name',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (_) => _saveName(),
        ),
        const Spacer(),
        Row(
          children: [
            TextButton(
              onPressed: () => setState(() => _onBirthday = true),
              child: const Text('Skip'),
            ),
            const Spacer(),
            FilledButton(onPressed: _saveName, child: const Text('Continue')),
          ],
        ),
      ],
    );

    final birthdayStep = Column(
      key: const ValueKey('birthday'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(Icons.cake_outlined, size: 40, color: theme.colorScheme.primary),
        const SizedBox(height: 16),
        Text('When\'s your birthday?', style: theme.textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(
            'So Daily You can celebrate your day with you. It stays on your phone.',
            style: muted),
        const SizedBox(height: 24),
        BirthdayPicker(
          initial: _birthday,
          onChanged: (day) => setState(() => _birthday = day),
        ),
        const Spacer(),
        Row(
          children: [
            TextButton(
              onPressed: () => _finish(saveBirthday: false),
              child: const Text('Skip'),
            ),
            const Spacer(),
            FilledButton(
              onPressed:
                  _birthday == null ? null : () => _finish(saveBirthday: true),
              child: const Text('Done'),
            ),
          ],
        ),
      ],
    );

    return PopScope(
      canPop: _onBirthday ? true : false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !_onBirthday) setState(() => _onBirthday = true);
      },
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _onBirthday ? birthdayStep : nameStep,
            ),
          ),
        ),
      ),
    );
  }
}

/// Settings › Profile: Name and Birthday.
class ProfileSettingsPage extends StatelessWidget {
  const ProfileSettingsPage({super.key});

  Future<void> _editName(BuildContext context) async {
    final controller = TextEditingController(
        text: ConfigProvider.instance.get<String>(Settings.homeGreetingName));
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Name'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: HomeGreeting.maxNameLength,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(hintText: 'Your name'),
          onSubmitted: (value) => Navigator.pop(dialogContext, value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child:
                Text(MaterialLocalizations.of(dialogContext).cancelButtonLabel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text),
            child: Text(MaterialLocalizations.of(dialogContext).okButtonLabel),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name != null) {
      await ConfigProvider.instance.set(Settings.homeGreetingName, name.trim());
    }
  }

  Future<void> _editBirthday(BuildContext context) async {
    DateTime? picked = Profile.birthday();
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Birthday'),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                  'So Daily You can celebrate your day with you. It stays on your phone.'),
              const SizedBox(height: 16),
              BirthdayPicker(initial: picked, onChanged: (day) => picked = day),
            ],
          ),
        ),
        actions: [
          if (Profile.birthday() != null)
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, 'clear'),
              child: const Text('Remove'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child:
                Text(MaterialLocalizations.of(dialogContext).cancelButtonLabel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, 'save'),
            child: Text(MaterialLocalizations.of(dialogContext).okButtonLabel),
          ),
        ],
      ),
    );
    if (result == 'clear') await Profile.setBirthday(null);
    if (result == 'save' && picked != null) await Profile.setBirthday(picked);
  }

  @override
  Widget build(BuildContext context) {
    final config = Provider.of<ConfigProvider>(context);
    final name = config.get<String>(Settings.homeGreetingName);
    final birthday = Profile.birthday();
    final locale = Localizations.localeOf(context).toString();

    return Scaffold(
      appBar: AppBar(title: const Text('Profile'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.only(top: 8, bottom: 16),
        children: [
          SettingsGroup(children: [
            ListTile(
              leading: const Icon(Icons.person_outline_rounded),
              title: const Text('Name',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              subtitle: Text(name.isEmpty ? 'Used in the Home greeting' : name),
              trailing: const Icon(Icons.edit_rounded),
              onTap: () => _editName(context),
            ),
            ListTile(
              leading: const Icon(Icons.cake_outlined),
              title: const Text('Birthday',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              subtitle: Text(birthday == null
                  ? 'For a birthday greeting and reminder'
                  : DateFormat.yMMMMd(locale).format(birthday)),
              trailing: const Icon(Icons.edit_rounded),
              onTap: () => _editBirthday(context),
            ),
          ]),
        ],
      ),
    );
  }
}
