// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/config_provider.dart';
import 'package:daily_you/custom_locale_delegates.dart';
import 'package:daily_you/fork/locations.dart';
import 'package:daily_you/fork/places.dart';
import 'package:daily_you/fork/search_text.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:daily_you/models/entry.dart';
import 'package:daily_you/models/tag.dart';
import 'package:daily_you/models/tag_category.dart';
import 'package:daily_you/providers/entries_provider.dart';
import 'package:daily_you/providers/entry_attachments_provider.dart';
import 'package:daily_you/providers/tags_provider.dart';
import 'package:daily_you/widgets/large_entry_card_widget.dart';
import 'package:daily_you/widgets/tag_attachment_source.dart';
import 'package:daily_you/widgets/tag_picker_dialog.dart';
import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../support/config_provider_harness.dart';

final _t0 = DateTime(2026, 1, 1);

Tag _tag(int id, String name, {int? category}) => Tag(
    id: id,
    name: name,
    tagType: TagType.label,
    categoryId: category,
    sortOrder: id,
    timeCreate: _t0,
    timeModified: _t0);

void _seed() {
  TagsProvider.instance.categories = [
    TagCategory(
        id: 1,
        name: 'Weather',
        sortOrder: 0,
        timeCreate: _t0,
        timeModified: _t0),
    TagCategory(
        id: 2,
        name: 'Events',
        sortOrder: 1,
        timeCreate: _t0,
        timeModified: _t0),
  ];
  TagsProvider.instance.tags = [
    _tag(1, 'Cloudy', category: 1),
    _tag(2, 'Storm', category: 1),
    _tag(3, 'History', category: 2),
    _tag(4, 'Movie', category: 2),
  ];
  TagsProvider.instance.debugSetEntryTags([]);
}

Entry _entry(int id, String text) => Entry(
    id: id,
    text: text,
    timeCreate: DateTime(2026, 11, 7, 12, 30),
    timeModified: DateTime(2026, 11, 7, 12, 41));

Widget _app(Widget home) => MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: ConfigProvider.instance),
        ChangeNotifierProvider.value(value: EntriesProvider.instance),
        ChangeNotifierProvider.value(value: EntryAttachmentsProvider.instance),
        ChangeNotifierProvider.value(value: TagsProvider.instance),
      ],
      child: MaterialApp(
        localizationsDelegates: <LocalizationsDelegate<dynamic>>[
          AppLocalizations.delegate,
          ...appLocalizationsDelegates,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: home,
      ),
    );

Future<void> _open(WidgetTester tester, TagPickerDialog dialog) async {
  await tester.pumpWidget(_app(Builder(
    builder: (context) => Scaffold(
      body: TextButton(
        onPressed: () => showDialog(context: context, builder: (_) => dialog),
        child: const Text('open'),
      ),
    ),
  )));
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

const _jollibee = Place('Jollibee', 'https://maps.app.goo.gl/j', 'after shift');
const _home = Place('Home', 'geo:1,2');

void main() {
  group('Gallery place search', () {
    useTemporaryConfig();
    final text =
        EntryLocations.join('Quick lunch between shifts', [_jollibee, _home]);

    test('finds entries by place name and description', () {
      expect(SearchText.matches(text, 'jolli'), isTrue);
      expect(SearchText.matches(text, 'AFTER SHIFT'), isTrue);
      expect(SearchText.matches(text, 'lunch'), isTrue);
      expect(SearchText.matches(text, 'library'), isFalse);
      // The map link is not searched
      expect(SearchText.matches(text, 'goo.gl'), isFalse);
    });

    test('says which place matched, and where', () {
      final byName = SearchText.placeMatch(text, 'bee')!;
      expect(byName.place.name, 'Jollibee');
      expect(byName.name, (5, 8));
      expect(byName.description, isNull);
      expect(byName.more, 1);

      final byDescription = SearchText.placeMatch(text, 'shift')!;
      expect(byDescription.name, isNull);
      expect(byDescription.description, (6, 11));

      // A word only in the text is not a place match
      expect(SearchText.placeMatch(text, 'lunch'), isNull);
    });

    testWidgets('the Gallery card shows the matched place', (tester) async {
      final entry = _entry(1, text);
      await tester.pumpWidget(_app(Scaffold(
        body: SizedBox(
          height: 200,
          child: LargeEntryCardWidget(
              entry: entry, attachments: const [], searchQuery: 'after'),
        ),
      )));
      await tester.pumpAndSettle();
      expect(find.byType(LocationChip), findsOneWidget);
      expect(find.text('Jollibee · after shift  +1'), findsOneWidget);

      // No search: no chip on Gallery cards
      await tester.pumpWidget(_app(Scaffold(
        body: SizedBox(
          height: 200,
          child: LargeEntryCardWidget(entry: entry, attachments: const []),
        ),
      )));
      await tester.pumpAndSettle();
      expect(find.byType(LocationChip), findsNothing);
    });
  });

  group('Location pills', () {
    useTemporaryConfig();

    testWidgets('entry view pill shows the description, no Maps icon',
        (tester) async {
      await tester.pumpWidget(_app(
          const Scaffold(body: LocationButtons(places: [_jollibee, _home]))));
      await tester.pumpAndSettle();
      expect(find.byType(PlacePill), findsNWidgets(2));
      expect(find.text('after shift'), findsOneWidget);
      expect(find.byIcon(Icons.open_in_new_rounded), findsNothing);
    });

    testWidgets('Timeline chip shows the name only and takes no taps',
        (tester) async {
      await tester.pumpWidget(_app(const Scaffold(
          body: TimelineLocationButton(places: [_jollibee, _home]))));
      await tester.pumpAndSettle();
      expect(find.text('Jollibee  +1'), findsOneWidget);
      expect(find.textContaining('after shift'), findsNothing);
      expect(find.byType(InkWell), findsNothing);
    });
  });

  group('Add Tags', () {
    useTemporaryConfig();
    setUp(_seed);

    testWidgets('a tag already added shows as Added, not No Results',
        (tester) async {
      final source = TagAttachmentSource(initialTagIds: const [1]);
      await _open(
          tester, TagPickerDialog(mode: TagPickerMode.attach, source: source));
      await tester.enterText(find.byType(TextField), 'cloud');
      await tester.pumpAndSettle();
      expect(find.text('No Results…'), findsNothing);
      expect(find.text('Added'), findsOneWidget);
      // Tapping it takes it off
      await tester.tap(find.text('Added'));
      await tester.pumpAndSettle();
      expect(source.attachedTagIds, isEmpty);
    });

    testWidgets('✓ adds the best match and keeps typing', (tester) async {
      final source = TagAttachmentSource(initialTagIds: const [2]);
      await _open(
          tester, TagPickerDialog(mode: TagPickerMode.attach, source: source));
      await tester.tap(find.byType(TextField));
      await tester.enterText(find.byType(TextField), 'stor');
      await tester.pumpAndSettle();
      // Storm is added already, so History is the best match
      expect(find.byIcon(Icons.keyboard_return_rounded), findsOneWidget);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(source.attachedTagIds, [2, 3]);
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.controller!.text, isEmpty);
      expect(field.focusNode!.hasFocus, isTrue);
    });

    testWidgets('✓ with nothing new to add adds nothing', (tester) async {
      final source = TagAttachmentSource(initialTagIds: const [1]);
      await _open(
          tester, TagPickerDialog(mode: TagPickerMode.attach, source: source));
      await tester.tap(find.byType(TextField));
      await tester.enterText(find.byType(TextField), 'cloudy');
      await tester.pumpAndSettle();
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(source.attachedTagIds, [1]);
    });

    testWidgets('typing folds the added tags into one line', (tester) async {
      final source = TagAttachmentSource(initialTagIds: const [1, 4]);
      await _open(
          tester, TagPickerDialog(mode: TagPickerMode.attach, source: source));
      expect(find.text('2 added'), findsNothing);
      await tester.tap(find.byType(TextField));
      await tester.pumpAndSettle();
      expect(find.text('2 added'), findsOneWidget);
      // The search bar stays above the list
      final search = tester.getTopLeft(find.byType(TextField)).dy;
      final movie = tester.getTopLeft(find.text('Movie').first).dy;
      expect(search, lessThan(movie));
    });

    testWidgets('the sort button shows the sort that is on', (tester) async {
      await _open(
          tester,
          TagPickerDialog(
              mode: TagPickerMode.attach, source: TagAttachmentSource()));
      expect(find.byIcon(Icons.bar_chart_rounded), findsOneWidget);
      await tester.tap(find.byIcon(Icons.bar_chart_rounded));
      await tester.pumpAndSettle();
      await tester.tap(find.text('My Order'));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.reorder_rounded), findsOneWidget);
      EasyDebounce.cancelAll();
    });
  });
}
