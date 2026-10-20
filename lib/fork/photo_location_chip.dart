// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/fork/places.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:daily_you/models/attachment.dart';
import 'package:daily_you/utils/text_editing.dart';
import 'package:material_ui/material_ui.dart';

/// "📍 Add this photo's location", shown in the editor when an attached
/// photo has a location saved in it and the entry doesn't mention it yet.
class PhotoLocationChip extends StatefulWidget {
  const PhotoLocationChip({
    super.key,
    required this.attachments,
    required this.controller,
  });

  final List<EntryAttachment> attachments;
  final TextEditingController controller;

  @override
  State<PhotoLocationChip> createState() => _PhotoLocationChipState();
}

class _PhotoLocationChipState extends State<PhotoLocationChip> {
  (double, double)? _location;
  String _checkedFor = '';

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
    _lookUp();
  }

  @override
  void didUpdateWidget(PhotoLocationChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onTextChanged);
      widget.controller.addListener(_onTextChanged);
    }
    _lookUp();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    if (_location != null && mounted) setState(() {});
  }

  Future<void> _lookUp() async {
    final photos = widget.attachments
        .where((attachment) => attachment.type == AttachmentType.image)
        .toList();
    final key = photos.map((photo) => photo.filePath).join('|');
    if (key == _checkedFor) return;
    _checkedFor = key;
    (double, double)? found;
    for (final photo in photos) {
      found = await Places.photoLocation(photo);
      if (found != null) break;
    }
    if (mounted && _checkedFor == key) setState(() => _location = found);
  }

  @override
  Widget build(BuildContext context) {
    final location = _location;
    if (location == null) return const SizedBox.shrink();
    final markdown = Places.coordinates(location.$1, location.$2);
    final address = Places.fromShared(
            markdown.substring(markdown.indexOf('](') + 2, markdown.length - 1))
        ?.$2;
    if (address != null && widget.controller.text.contains(address)) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 4),
      child: Center(
        child: ActionChip(
          avatar: const Icon(Icons.place_rounded, size: 18),
          label: Text(AppLocalizations.of(context)!.placeFromPhoto),
          onPressed: () {
            final text = widget.controller.text;
            final spacer = text.isEmpty || text.endsWith('\n') ? '' : '\n';
            widget.controller.selection =
                TextSelection.collapsed(offset: text.length);
            insertAtCursor(widget.controller, '$spacer$markdown');
          },
        ),
      ),
    );
  }
}
