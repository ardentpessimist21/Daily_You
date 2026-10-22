// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/fork/locations.dart';
import 'package:daily_you/fork/hyphenation.dart';
import 'package:daily_you/fork/search_highlight.dart';
import 'package:daily_you/models/attachment.dart';
import 'package:daily_you/time_manager.dart';
import 'package:daily_you/widgets/entry_card_header_row.dart';
import 'package:daily_you/widgets/attachment_grid.dart';
import 'package:daily_you/widgets/scaled_markdown.dart';
import 'package:material_ui/material_ui.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:daily_you/models/entry.dart';

class LargeCard extends StatelessWidget {
  const LargeCard({super.key, this.media, this.header, this.body, this.footer});

  final Widget? media;
  final Widget? header;
  final Widget? body;

  /// Shown under the body, e.g. the Timeline's 📍 button.
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return Card.filled(
      color: Theme.of(context).colorScheme.surfaceContainer,
      clipBehavior: Clip.antiAlias,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (media != null)
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: media,
              ),
            ),
          if (header != null || body != null)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (header != null)
                    Padding(
                      padding: const EdgeInsets.all(2.0),
                      child: header,
                    )
                  else
                    const SizedBox(height: 8),
                  if (body != null)
                    Expanded(
                      child: ShaderMask(
                        shaderCallback: (Rect bounds) {
                          return const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.black, Colors.transparent],
                            stops: [0.8, 0.95],
                          ).createShader(bounds);
                        },
                        blendMode: BlendMode.dstIn,
                        child: ClipRect(
                          clipBehavior: Clip.hardEdge,
                          child: Padding(
                            padding:
                                const EdgeInsets.only(left: 8.0, right: 8.0),
                            child: IgnorePointer(child: body),
                          ),
                        ),
                      ),
                    ),
                  if (footer != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 2, 8, 8),
                      child: footer,
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  static Widget markdownBody(String text, {String? searchQuery}) => OverflowBox(
        alignment: AlignmentDirectional.topStart,
        maxHeight: double.infinity,
        child: ScaledMarkdown(
          data: searchQuery == null || searchQuery.isEmpty
              ? text
              : SearchHighlight.preview(text, searchQuery),
          maxCharacters: 500,
          scaleFactor: 0.95,
          searchQuery: searchQuery,
        ),
      );
}

/// Shows an entry's whole text, with any photos above it, instead of the
/// clipped preview drawn by [LargeEntryCardWidget]. The card grows to fit.
class FullEntryCardWidget extends StatelessWidget {
  const FullEntryCardWidget({
    super.key,
    this.title,
    required this.entry,
    required this.attachments,
    this.locationsEnabled = true,
  });

  final Entry entry;
  final List<EntryAttachment> attachments;
  final String? title;

  /// False while selecting, so tapping the 📍 button selects the card.
  final bool locationsEnabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final time = TimeManager.formatDate(entry.timeCreate, context);
    final (body, places) = EntryLocations.split(entry.text);
    final showPlaces = places.isNotEmpty && EntryLocations.showButtons;
    final justify = JustifyText.enabled;
    return Card.filled(
      color: theme.colorScheme.surfaceContainer,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(2.0),
            child: EntryCardHeaderRow(
              entry: entry,
              title: title == null ? time : title!,
              titlePadding: const EdgeInsets.only(left: 4.0),
              titleStyle: TextStyle(
                color: theme.textTheme.labelSmall?.color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (attachments.isNotEmpty)
            Padding(
              padding: EdgeInsets.fromLTRB(
                  8.0, 0, 8.0, body.isEmpty && !showPlaces ? 8.0 : 0),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: AttachmentGrid(attachments: attachments),
                ),
              ),
            ),
          // A day with only photos or places needs no "Write something…"
          if (body.isNotEmpty || (attachments.isEmpty && !showPlaces))
            Padding(
              padding: EdgeInsets.fromLTRB(justify ? 6.0 : 8.0, 4.0,
                  justify ? 6.0 : 8.0, showPlaces ? 6.0 : 12.0),
              child: body.isNotEmpty
                  ? IgnorePointer(
                      child: ScaledMarkdown(
                          data: body, scaleFactor: 0.95, justify: justify),
                    )
                  : Text(
                      AppLocalizations.of(context)!.writeSomethingHint,
                      style:
                          TextStyle(color: theme.disabledColor, fontSize: 16),
                    ),
            ),
          if (showPlaces)
            Padding(
              padding:
                  EdgeInsets.fromLTRB(8.0, body.isEmpty ? 8.0 : 0, 8.0, 10.0),
              child: TimelineLocationButton(
                  places: places, enabled: locationsEnabled),
            ),
        ],
      ),
    );
  }
}

class LargeEntryCardWidget extends StatelessWidget {
  const LargeEntryCardWidget({
    super.key,
    this.title,
    required this.entry,
    required this.attachments,
    this.hideImage = false,
    this.searchQuery,
    this.showLocations = false,
    this.locationsEnabled = true,
  });

  final Entry entry;
  final List<EntryAttachment> attachments;
  final String? title;
  final bool hideImage;

  /// Shows the 📍 button under the text (the Timeline does).
  final bool showLocations;

  /// False while selecting, so tapping the 📍 button selects the card.
  final bool locationsEnabled;

  /// Gallery search text: matches are highlighted and counted.
  final String? searchQuery;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final time = TimeManager.formatDate(entry.timeCreate, context);
    final (body, places) = EntryLocations.split(entry.text);
    final matches = SearchHighlight.count(body, searchQuery ?? '');
    final card = LargeCard(
      media: attachments.isNotEmpty && !hideImage
          ? AttachmentGrid(attachments: attachments)
          : null,
      header: EntryCardHeaderRow(
        entry: entry,
        title: title == null ? time : title!,
        titlePadding: const EdgeInsets.only(left: 4.0),
        titleStyle: TextStyle(
          color: theme.textTheme.labelSmall?.color,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: body.isNotEmpty
          ? LargeCard.markdownBody(body, searchQuery: searchQuery)
          // A day with only photos or places needs no "Write something…"
          : (attachments.isNotEmpty && !hideImage) ||
                  (showLocations &&
                      places.isNotEmpty &&
                      EntryLocations.showButtons)
              ? null
              : Text(
                  AppLocalizations.of(context)!.writeSomethingHint,
                  style: TextStyle(color: theme.disabledColor, fontSize: 16),
                ),
      footer: showLocations && places.isNotEmpty && EntryLocations.showButtons
          ? TimelineLocationButton(places: places, enabled: locationsEnabled)
          : null,
    );
    if (matches == 0) return card;
    return Stack(children: [
      card,
      PositionedDirectional(
        end: 10,
        bottom: 10,
        child: SearchMatchBadge(count: matches),
      ),
    ]);
  }
}
