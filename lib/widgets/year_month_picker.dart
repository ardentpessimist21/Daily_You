// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/fork/year_month_range.dart';
import 'package:daily_you/time_manager.dart';
import 'package:daily_you/widgets/app_dialog.dart';
import 'package:material_ui/material_ui.dart';
import 'package:intl/intl.dart';
import 'package:shamsi_date/shamsi_date.dart';

Future<DateTime?> showYearMonthPicker(
  BuildContext context, {
  DateTime? initialDate,
  bool isJalali = false,
  int? firstYear,
  DateTime? lastDate,
}) {
  final now = DateTime.now();
  final locale = Localizations.localeOf(context).toString();
  final last = lastDate ?? now;
  final first = firstYear ?? YearMonthRange.fallbackFirstYear;

  if (isJalali) {
    final lastJ = Jalali.fromDateTime(last);
    final range = YearMonthRange(
      firstYear: Jalali.fromDateTime(DateTime(first, 1, 1)).year,
      lastYear: lastJ.year,
      lastMonth: lastJ.month,
    );
    return _showJalaliPicker(context,
        initialDate: initialDate, locale: locale, range: range);
  } else {
    final range = YearMonthRange(
        firstYear: first, lastYear: last.year, lastMonth: last.month);
    return _showGregorianPicker(context,
        initialDate: initialDate, now: now, locale: locale, range: range);
  }
}

Future<DateTime?> _showGregorianPicker(
  BuildContext context, {
  required DateTime? initialDate,
  required DateTime now,
  required String locale,
  required YearMonthRange range,
}) {
  var (selectedYear, selectedMonth) =
      range.clamp((initialDate ?? now).year, (initialDate ?? now).month);

  List<String> localizedMonths() {
    final formatter = DateFormat.MMMM(locale);
    return List.generate(
        12, (i) => formatter.format(DateTime(now.year, i + 1, 1)));
  }

  final months = localizedMonths();
  final years = range.years;

  return showAppDialog<DateTime>(
    context: context,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (BuildContext context, setState) => AlertDialog(
          content: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              DropdownButton<int>(
                underline: Container(),
                elevation: 1,
                isDense: false,
                isExpanded: false,
                alignment: AlignmentDirectional.centerEnd,
                borderRadius: BorderRadius.circular(20),
                value: selectedYear,
                items: years
                    .map((y) => DropdownMenuItem<int>(
                          value: y,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: y == selectedYear
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                                y.toString()),
                          ),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      (selectedYear, selectedMonth) =
                          range.clamp(value, selectedMonth);
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              DropdownButton<int>(
                underline: Container(),
                elevation: 1,
                isDense: false,
                isExpanded: false,
                alignment: AlignmentDirectional.centerEnd,
                borderRadius: BorderRadius.circular(20),
                value: selectedMonth,
                items: List.generate(
                  range.monthCount(selectedYear),
                  (i) => DropdownMenuItem<int>(
                    value: i + 1,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: i + 1 == selectedMonth
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                          months[i]),
                    ),
                  ),
                ),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      selectedMonth = value;
                    });
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(
                    context, DateTime(selectedYear, selectedMonth, 1));
              },
              child: Text(MaterialLocalizations.of(context).okButtonLabel),
            ),
          ],
        ),
      );
    },
  );
}

Future<DateTime?> _showJalaliPicker(
  BuildContext context, {
  required DateTime? initialDate,
  required String locale,
  required YearMonthRange range,
}) {
  final nowJ = Jalali.now();
  final initJ = initialDate != null ? Jalali.fromDateTime(initialDate) : nowJ;

  var (selectedYear, selectedMonth) = range.clamp(initJ.year, initJ.month);

  final years = range.years;

  final months =
      List.generate(12, (i) => TimeManager.jalaliMonthName(i + 1, locale));

  return showAppDialog<DateTime>(
    context: context,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (BuildContext context, setState) => AlertDialog(
          content: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              DropdownButton<int>(
                underline: Container(),
                elevation: 1,
                isDense: false,
                isExpanded: false,
                alignment: AlignmentDirectional.centerEnd,
                borderRadius: BorderRadius.circular(20),
                value: selectedYear,
                items: years
                    .map((y) => DropdownMenuItem<int>(
                          value: y,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: y == selectedYear
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                                y.toString()),
                          ),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      (selectedYear, selectedMonth) =
                          range.clamp(value, selectedMonth);
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              DropdownButton<int>(
                underline: Container(),
                elevation: 1,
                isDense: false,
                isExpanded: false,
                alignment: AlignmentDirectional.centerEnd,
                borderRadius: BorderRadius.circular(20),
                value: selectedMonth,
                items: List.generate(
                  range.monthCount(selectedYear),
                  (i) => DropdownMenuItem<int>(
                    value: i + 1,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: i + 1 == selectedMonth
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                          months[i]),
                    ),
                  ),
                ),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      selectedMonth = value;
                    });
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context,
                    Jalali(selectedYear, selectedMonth, 1).toDateTime());
              },
              child: Text(MaterialLocalizations.of(context).okButtonLabel),
            ),
          ],
        ),
      );
    },
  );
}
