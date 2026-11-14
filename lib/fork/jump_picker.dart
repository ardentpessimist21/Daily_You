// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:ui' show PlatformDispatcher;

import 'package:daily_you/fork/date_template_box.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:daily_you/time_manager.dart';
import 'package:daily_you/widgets/app_dialog.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

/// Jump to month (3.7.0.49): one picker for the Home calendar, the Gallery
/// and the share screen.
///
/// - Months: a 3×4 grid with each month's entry count. Swipe sideways (or
///   tap a faint neighbouring year) to change year.
/// - Years: tap the year for a scrolling grid of years with their counts.
/// - Date: the ✏️ in the header swaps the grid for a date box; 📅 goes back.
///
/// The title follows the view: Jump to month / year / date.

/// What the picker returned: a month, or a typed [day] inside [month].
class JumpTarget {
  JumpTarget.month(int year, int month)
      : month = DateTime(year, month),
        day = null;

  JumpTarget.day(DateTime date)
      : month = DateTime(date.year, date.month),
        day = DateTime(date.year, date.month, date.day);

  final DateTime month;

  /// Set only when a date was typed.
  final DateTime? day;
}

/// The order a typed date is read in, taken from a locale's short date
/// pattern ("M/d/y", "dd/MM/y", "y-MM-dd"...).
class JumpDateFormat {
  JumpDateFormat(String pattern)
      : _order = _orderOf(pattern),
        hint = _hintOf(pattern),
        separator = _separatorOf(pattern);

  /// The phone's regional format when it is in the app's language (so an
  /// Australian phone reads dd/mm/yyyy), else the app language's own.
  factory JumpDateFormat.of(BuildContext context) {
    final app = TimeManager.currentLocale(context);
    var tag = app;
    final device = PlatformDispatcher.instance.locale;
    final country = device.countryCode;
    if (country != null &&
        country.isNotEmpty &&
        device.languageCode == Localizations.localeOf(context).languageCode) {
      final regional = '${device.languageCode}_$country';
      if (DateFormat.localeExists(regional)) tag = regional;
    }
    try {
      return JumpDateFormat(DateFormat.yMd(tag).pattern ?? 'M/d/y');
    } catch (_) {
      return JumpDateFormat('M/d/y');
    }
  }

  /// 'd', 'M' and 'y' in the order they are typed.
  final List<String> _order;

  /// The same order, for the date template box (3.7.0.50).
  List<String> get order => List.unmodifiable(_order);

  /// What goes between the parts: '/', '-', '.'...
  final String separator;

  static String _separatorOf(String pattern) {
    final match = RegExp(r'[^dMy\s]').firstMatch(pattern);
    return match?.group(0) ?? '/';
  }

  /// The parts typed into the template box, in [order], as text [parse]
  /// reads.
  String join(Map<String, String> parts) =>
      _order.map((part) => parts[part] ?? '').join(separator);

  /// Shown in the box and in the "Enter a date like…" message.
  final String hint;

  static List<String> _orderOf(String pattern) {
    final order = <String>[];
    for (final char in pattern.split('')) {
      if ((char == 'd' || char == 'M' || char == 'y') &&
          !order.contains(char)) {
        order.add(char);
      }
    }
    for (final part in const ['M', 'd', 'y']) {
      if (!order.contains(part)) order.add(part);
    }
    return order;
  }

  static String _hintOf(String pattern) => pattern
      .replaceAll(RegExp('d+'), 'dd')
      .replaceAll(RegExp('M+'), 'mm')
      .replaceAll(RegExp('y+'), 'yyyy');

  /// The date typed as three numbers with anything between them, or null
  /// when it isn't a real date (31/02, a two-digit year...).
  DateTime? parse(String text) {
    final numbers = RegExp(r'\d+')
        .allMatches(text)
        .map((match) => int.tryParse(match.group(0)!))
        .toList();
    if (numbers.length != 3 || numbers.contains(null)) return null;
    final year = numbers[_order.indexOf('y')]!;
    final month = numbers[_order.indexOf('M')]!;
    final day = numbers[_order.indexOf('d')]!;
    if (year < 1000 || year > 9999 || month < 1 || month > 12 || day < 1) {
      return null;
    }
    final date = DateTime(year, month, day);
    // DateTime rolls 31 Feb over into March
    if (date.month != month || date.day != day) return null;
    return date;
  }
}

class JumpPicker {
  JumpPicker._();

  /// Opens the picker over [entryDates].
  ///
  /// [selected] is the month being looked at, shown highlighted. Years run
  /// from the first entry's year to the last one's, stretched by [firstYear]
  /// and [lastYear] when given.
  ///
  /// With [allowEmpty] (the share screen, where any day can take a new
  /// entry) months and years without entries can be picked too, and a typed
  /// date only has to fall between [firstDate] and [lastDate].
  static Future<JumpTarget?> show(
    BuildContext context, {
    required Iterable<DateTime> entryDates,
    required DateTime selected,
    int? firstYear,
    int? lastYear,
    bool allowEmpty = false,
    DateTime? firstDate,
    DateTime? lastDate,
    JumpDateFormat? dateFormat,
  }) {
    final months = <(int, int), int>{};
    final years = <int, int>{};
    final days = <(int, int, int)>{};
    for (final date in entryDates) {
      months.update((date.year, date.month), (count) => count + 1,
          ifAbsent: () => 1);
      years.update(date.year, (count) => count + 1, ifAbsent: () => 1);
      days.add((date.year, date.month, date.day));
    }
    int? entryFirst;
    int? entryLast;
    for (final year in years.keys) {
      if (entryFirst == null || year < entryFirst) entryFirst = year;
      if (entryLast == null || year > entryLast) entryLast = year;
    }
    var first = firstYear ?? entryFirst ?? selected.year;
    var last = lastYear ?? entryLast ?? selected.year;
    if (entryLast != null && entryLast > last) last = entryLast;
    if (first > last) first = last;
    return showAppDialog<JumpTarget>(
      context: context,
      builder: (context) => JumpPickerDialog(
        monthCounts: months,
        yearCounts: years,
        entryDays: days,
        firstYear: first,
        lastYear: last,
        selected: selected,
        allowEmpty: allowEmpty,
        firstDate: firstDate,
        lastDate: lastDate,
        dateFormat: dateFormat,
      ),
    );
  }
}

enum _JumpView { months, years, date }

class JumpPickerDialog extends StatefulWidget {
  const JumpPickerDialog({
    super.key,
    required this.monthCounts,
    required this.yearCounts,
    required this.entryDays,
    required this.firstYear,
    required this.lastYear,
    required this.selected,
    this.allowEmpty = false,
    this.firstDate,
    this.lastDate,
    this.dateFormat,
  });

  final Map<(int, int), int> monthCounts;
  final Map<int, int> yearCounts;
  final Set<(int, int, int)> entryDays;
  final int firstYear;
  final int lastYear;
  final DateTime selected;
  final bool allowEmpty;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final JumpDateFormat? dateFormat;

  @override
  State<JumpPickerDialog> createState() => _JumpPickerDialogState();
}

class _JumpPickerDialogState extends State<JumpPickerDialog> {
  static const double _gap = 8;
  static const double _tileAspect = 1.5;

  late int _year = widget.selected.year.clamp(widget.firstYear, widget.lastYear);
  late PageController _pages =
      PageController(initialPage: _year - widget.firstYear);
  final ScrollController _yearScroll = ScrollController();
  /// The typed date, as text [JumpDateFormat.parse] reads.
  String _dateText = '';

  _JumpView _view = _JumpView.months;
  String? _dateError;

  @override
  void dispose() {
    _pages.dispose();
    _yearScroll.dispose();
    super.dispose();
  }

  void _stepYear(int year) {
    if (year < widget.firstYear || year > widget.lastYear) return;
    _pages.animateToPage(year - widget.firstYear,
        duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
  }

  void _showYears() {
    setState(() => _view = _JumpView.years);
    // Open with the year being looked at in the middle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_yearScroll.hasClients) return;
      final position = _yearScroll.position;
      final count = widget.lastYear - widget.firstYear + 1;
      final rows = (count / 3).ceil();
      if (rows == 0) return;
      final content = position.maxScrollExtent + position.viewportDimension;
      final rowExtent = (content + _gap) / rows;
      final row = (_year - widget.firstYear) ~/ 3;
      final target = row * rowExtent -
          (position.viewportDimension - (rowExtent - _gap)) / 2;
      _yearScroll.jumpTo(target.clamp(0.0, position.maxScrollExtent));
    });
  }

  /// Back to the month grid, opened on [year].
  void _showMonths(int year) {
    final old = _pages;
    setState(() {
      _year = year;
      _dateError = null;
      _pages = PageController(initialPage: year - widget.firstYear);
      _view = _JumpView.months;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => old.dispose());
  }

  void _pickYear(int year) => _showMonths(year);

  void _toggleDate() {
    if (_view == _JumpView.date) {
      _showMonths(_year);
    } else {
      setState(() {
        _dateError = null;
        _dateText = '';
        _view = _JumpView.date;
      });
    }
  }

  void _submitDate() {
    final l10n = AppLocalizations.of(context)!;
    final format = widget.dateFormat ?? JumpDateFormat.of(context);
    final date = format.parse(_dateText);
    String? error;
    if (date == null) {
      error = l10n.jumpDateInvalid(format.hint);
    } else if (_outOfRange(date)) {
      error = l10n.jumpDateOutOfRange;
    } else if (!widget.allowEmpty &&
        (widget.monthCounts[(date.year, date.month)] ?? 0) == 0) {
      error = l10n
          .jumpNoEntriesInMonth(TimeManager.formatMonthYear(date, context));
    }
    if (error != null) {
      setState(() => _dateError = error);
      return;
    }
    Navigator.pop(context, JumpTarget.day(date!));
  }

  bool _outOfRange(DateTime date) {
    final first = widget.firstDate ?? DateTime(widget.firstYear);
    final last = widget.lastDate ?? DateTime(widget.lastYear, 12, 31);
    final firstDay = DateTime(first.year, first.month, first.day);
    final lastDay = DateTime(last.year, last.month, last.day);
    return date.isBefore(firstDay) || date.isAfter(lastDay);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final typing = _view == _JumpView.date;
    final title = switch (_view) {
      _JumpView.months => l10n.galleryJumpToMonth,
      _JumpView.years => l10n.jumpToYearTitle,
      _JumpView.date => l10n.jumpToDateTitle,
    };

    return AlertDialog(
      titlePadding: const EdgeInsets.fromLTRB(24, 16, 12, 0),
      title: Row(
        children: [
          Expanded(child: Text(title)),
          IconButton(
            tooltip: typing ? l10n.jumpBackToMonths : l10n.jumpTypeDate,
            icon: Icon(typing
                ? Icons.calendar_month_rounded
                : Icons.edit_outlined),
            onPressed: _toggleDate,
          ),
        ],
      ),
      contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      content: SizedBox(
        width: 320,
        child: switch (_view) {
          _JumpView.months => _buildMonths(context),
          _JumpView.years => _buildYears(context),
          _JumpView.date => _buildDate(context),
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
        if (typing)
          TextButton(
            onPressed: _submitDate,
            child: Text(MaterialLocalizations.of(context).okButtonLabel),
          ),
      ],
    );
  }

  // ---- Months ----------------------------------------------------------

  Widget _buildMonths(BuildContext context) {
    final count = widget.lastYear - widget.firstYear + 1;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildYearRow(context),
        const SizedBox(height: 8),
        LayoutBuilder(builder: (context, constraints) {
          final tileWidth = (constraints.maxWidth - _gap * 2) / 3;
          final height = tileWidth / _tileAspect * 4 + _gap * 3;
          return SizedBox(
            height: height,
            child: PageView.builder(
              key: const ValueKey('jump-months'),
              controller: _pages,
              // A small bounce at the first and last year
              physics: const BouncingScrollPhysics(),
              itemCount: count,
              onPageChanged: (page) =>
                  setState(() => _year = widget.firstYear + page),
              itemBuilder: (context, page) =>
                  _buildMonthGrid(context, widget.firstYear + page),
            ),
          );
        }),
      ],
    );
  }

  /// "2025 · 2026 ▾ · 2027": the year opens the year grid; the faint
  /// neighbours show there is more to swipe to and step a year when tapped.
  Widget _buildYearRow(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final faint = TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: colorScheme.onSurface.withValues(alpha: 0.38),
    );

    Widget neighbour(int year, Alignment alignment) {
      final inRange = year >= widget.firstYear && year <= widget.lastYear;
      return Expanded(
        child: Align(
          alignment: alignment,
          child: inRange
              ? InkWell(
                  key: ValueKey('jump-neighbour-$year'),
                  borderRadius: BorderRadius.circular(999),
                  onTap: () => _stepYear(year),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Text('$year', style: faint),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      );
    }

    return Row(
      children: [
        neighbour(_year - 1, Alignment.centerRight),
        InkWell(
          key: const ValueKey('jump-year'),
          borderRadius: BorderRadius.circular(999),
          onTap: _showYears,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 6, 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('$_year',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w600)),
                const Icon(Icons.arrow_drop_down_rounded, size: 22),
              ],
            ),
          ),
        ),
        neighbour(_year + 1, Alignment.centerLeft),
      ],
    );
  }

  Widget _buildMonthGrid(BuildContext context, int year) {
    final l10n = AppLocalizations.of(context)!;
    final monthFormat = DateFormat.MMM(TimeManager.currentLocale(context));
    return GridView.count(
      crossAxisCount: 3,
      padding: EdgeInsets.zero,
      mainAxisSpacing: _gap,
      crossAxisSpacing: _gap,
      childAspectRatio: _tileAspect,
      physics: const NeverScrollableScrollPhysics(),
      children: List.generate(12, (index) {
        final month = index + 1;
        final count = widget.monthCounts[(year, month)] ?? 0;
        final name = monthFormat.format(DateTime(year, month));
        return _tile(
          context,
          key: ValueKey('jump-month-$year-$month'),
          label: name,
          count: count,
          selected: widget.selected.year == year &&
              widget.selected.month == month,
          semantics: '$name, ${l10n.galleryMonthEntries(count)}',
          onTap: () =>
              Navigator.pop(context, JumpTarget.month(year, month)),
        );
      }),
    );
  }

  // ---- Years -----------------------------------------------------------

  Widget _buildYears(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final years = [
      for (var year = widget.firstYear; year <= widget.lastYear; year++) year
    ];
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 300),
      // The edges fade to show there are more years to scroll to
      child: ShaderMask(
        shaderCallback: (rect) => const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black,
            Colors.black,
            Colors.transparent
          ],
          stops: [0, 0.06, 0.94, 1],
        ).createShader(rect),
        blendMode: BlendMode.dstIn,
        child: GridView.count(
          key: const ValueKey('jump-years'),
          controller: _yearScroll,
          crossAxisCount: 3,
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 10),
          mainAxisSpacing: _gap,
          crossAxisSpacing: _gap,
          childAspectRatio: _tileAspect,
          children: [
            for (final year in years)
              _tile(
                context,
                key: ValueKey('jump-year-$year'),
                label: '$year',
                count: widget.yearCounts[year] ?? 0,
                selected: widget.selected.year == year,
                semantics:
                    '$year, ${l10n.galleryMonthEntries(widget.yearCounts[year] ?? 0)}',
                onTap: () => _pickYear(year),
              ),
          ],
        ),
      ),
    );
  }

  // ---- Date ------------------------------------------------------------

  Widget _buildDate(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final format = widget.dateFormat ?? JumpDateFormat.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      // A fixed template whose parts fill in place (3.7.0.50)
      child: DateTemplateBox(
        key: const ValueKey('jump-date'),
        order: format.order,
        separator: format.separator,
        label: l10n.jumpEnterDate,
        errorText: _dateError,
        onChanged: (parts) {
          _dateText = format.join(parts);
          if (_dateError != null) setState(() => _dateError = null);
        },
        onSubmitted: _submitDate,
      ),
    );
  }

  // ---- Shared tile -----------------------------------------------------

  /// A month or year tile: its name over its entry count with the small
  /// notes icon. Empty ones are dimmed and, unless [allowEmpty], can't be
  /// tapped.
  Widget _tile(
    BuildContext context, {
    required Key key,
    required String label,
    required int count,
    required bool selected,
    required String semantics,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasEntries = count > 0;
    final enabled = hasEntries || widget.allowEmpty;
    final background = selected
        ? colorScheme.primary
        : hasEntries
            ? colorScheme.secondaryContainer
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5);
    final foreground = selected
        ? colorScheme.onPrimary
        : hasEntries
            ? colorScheme.onSecondaryContainer
            : enabled
                ? colorScheme.onSurfaceVariant
                : Theme.of(context).disabledColor;
    return Material(
      key: key,
      color: background,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: enabled ? onTap : null,
        child: Semantics(
          button: enabled,
          label: semantics,
          excludeSemantics: true,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(label,
                  style:
                      TextStyle(color: foreground, fontWeight: FontWeight.w600)),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (hasEntries) ...[
                    Icon(Icons.description_outlined,
                        size: 12, color: foreground),
                    const SizedBox(width: 3),
                  ],
                  Text(hasEntries ? '$count' : '–',
                      style: TextStyle(color: foreground, fontSize: 12)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
