// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:async';

import 'package:daily_you/database/attachment_storage.dart';
import 'package:daily_you/widgets/local_image_cache.dart';
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

class LocalImageLoader extends StatefulWidget {
  final String imagePath;
  final int cacheSize;

  const LocalImageLoader({
    super.key,
    required this.imagePath,
    this.cacheSize = LocalImageCache.previewWidth,
  });

  @override
  State<LocalImageLoader> createState() => _LocalImageLoaderState();
}

class _LocalImageLoaderState extends State<LocalImageLoader> {
  Uint8List? _bytes;
  bool _imageNotFound = false;
  int _cacheVersion = AttachmentStorage.instance.cacheVersion.value;

  // While showing the full-size original, waits for the small copy so the
  // original's bytes can be let go (3.7.0.62)
  StreamSubscription<String>? _waitForResize;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _waitForResize?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant LocalImageLoader oldWidget) {
    super.didUpdateWidget(oldWidget);

    final cacheVersion = AttachmentStorage.instance.cacheVersion.value;
    if (oldWidget.imagePath != widget.imagePath ||
        oldWidget.cacheSize != widget.cacheSize ||
        cacheVersion != _cacheVersion) {
      _cacheVersion = cacheVersion;
      _bytes = null;
      _imageNotFound = false;
      _load();
    }
  }

  Future<void> _load() async {
    _waitForResize?.cancel();
    _waitForResize = null;
    final path = widget.imagePath;
    final size = widget.cacheSize;
    final key = LocalImageCache.keyFor(path, size);
    // Listen before asking, so a copy finished in between isn't missed
    var copyReady = false;
    final waiting = LocalImageCache.instance.resized
        .where((k) => k == key)
        .listen((_) => copyReady = true);
    final (:bytes, :resized) =
        await LocalImageCache.instance.getImageBytes(path, size);
    if (!mounted || path != widget.imagePath || size != widget.cacheSize) {
      await waiting.cancel();
      return;
    }
    if (bytes != null && !resized) {
      if (copyReady) {
        await waiting.cancel();
        _load();
        return;
      }
      waiting.onData((_) {
        waiting.cancel();
        if (identical(_waitForResize, waiting)) _waitForResize = null;
        if (mounted) _load();
      });
      _waitForResize = waiting;
    } else {
      await waiting.cancel();
    }
    if (mounted) {
      if (bytes != null) {
        setState(() => _bytes = bytes);
      } else {
        setState(() => _imageNotFound = true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_bytes != null) {
      return Image.memory(
        _bytes!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        cacheWidth: widget.cacheSize,
        // Keeps the picture up while it swaps to the small copy
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) {
          return const Center(
            child: Icon(
              Icons.broken_image_rounded,
              size: 36,
            ),
          );
        },
      );
    } else {
      if (_imageNotFound) {
        // Image not found
        return const Center(
          child: Icon(
            Icons.image_search_rounded,
            size: 36,
          ),
        );
      } else {
        // Placeholder while image loads
        return const SizedBox.expand();
      }
    }
  }
}
