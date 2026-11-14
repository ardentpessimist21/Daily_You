// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:async';
import 'dart:io';

import 'package:daily_you/config_provider.dart';
import 'package:daily_you/database/entry_store.dart';
import 'package:daily_you/fork/quick_entry/quick_entry_service.dart';
import 'package:daily_you/providers/entries_provider.dart';
import 'package:daily_you/providers/entry_attachments_provider.dart';
import 'package:daily_you/providers/tags_provider.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The main app's side of Quick entry (Update Q):
/// - reloads entries saved from the quick-entry sheet or the notification
///   (they run in their own engine, so the main app's lists go stale);
/// - keeps the pinned notification up to date ("Add to last entry" only
///   shows when there's an entry today);
/// - opens an entry when the sheet's "Open full editor" asks for it.
class QuickEntryHost with WidgetsBindingObserver {
  QuickEntryHost._();
  static final QuickEntryHost instance = QuickEntryHost._();

  static const MethodChannel _channel =
      MethodChannel('daily_you/quick_entry_host');

  static final Logger _logger = Logger('QuickEntryHost');

  bool _started = false;
  int? _seenRevision;
  Timer? _refreshTimer;

  /// Opens entry [id] in the editor, or a new entry for today when -1.
  Future<void> Function(int id)? onOpenRequest;

  bool get _supported => Platform.isAndroid;

  /// Called once Home is showing (the database is open by then).
  Future<void> start({required Future<void> Function(int id) onOpen}) async {
    onOpenRequest = onOpen;
    if (!_supported || _started) return;
    _started = true;

    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    _seenRevision = prefs.getInt(QuickEntryService.revisionKey);

    WidgetsBinding.instance.addObserver(this);
    EntriesProvider.instance.addListener(_scheduleNotificationRefresh);
    ConfigProvider.instance.addListener(_scheduleNotificationRefresh);
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'openRequest') await _checkOpenRequest();
    });

    await _saveWaitingReplies();
    await refreshNotification();
    await _checkOpenRequest();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(_onResumed());
  }

  Future<void> _onResumed() async {
    await reloadIfChanged();
    await _saveWaitingReplies();
    await refreshNotification();
    await _checkOpenRequest();
  }

  /// Reloads entries and tags when a quick entry was saved elsewhere.
  Future<void> reloadIfChanged() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      final revision = prefs.getInt(QuickEntryService.revisionKey);
      if (revision == _seenRevision) return;
      _seenRevision = revision;
      await EntryStore.instance.load();
      await TagsProvider.instance.load();
      await EntryAttachmentsProvider.instance.load();
    } catch (error, stackTrace) {
      _logger.warning(
          'Reloading after a quick entry failed', error, stackTrace);
    }
  }

  Future<void> _saveWaitingReplies() async {
    try {
      final result = await QuickEntryService.saveWaitingReplies();
      if (result != null) {
        final prefs = await SharedPreferences.getInstance();
        _seenRevision = prefs.getInt(QuickEntryService.revisionKey);
      }
    } catch (error, stackTrace) {
      _logger.warning('Saving waiting replies failed', error, stackTrace);
    }
  }

  void _scheduleNotificationRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer(const Duration(milliseconds: 600), () {
      unawaited(refreshNotification());
    });
  }

  /// Shows, updates or removes the pinned notification.
  Future<void> refreshNotification() async {
    if (!_supported) return;
    final last = QuickEntryService.lastEntryToday();
    try {
      await _channel.invokeMethod('updateNotification', {
        'enabled':
            ConfigProvider.instance.get<bool>(Settings.quickEntryNotification),
        'lastLabel':
            last == null ? null : QuickEntryService.timeLabel(last.timeCreate),
      });
    } catch (error, stackTrace) {
      _logger.warning('Updating the notification failed', error, stackTrace);
    }
  }

  Future<void> _checkOpenRequest() async {
    if (!_supported) return;
    try {
      final id = await _channel.invokeMethod<int>('consumeOpenRequest');
      if (id == null) return;
      await reloadIfChanged();
      await onOpenRequest?.call(id);
    } catch (error, stackTrace) {
      _logger.warning('Opening from Quick entry failed', error, stackTrace);
    }
  }

  /// Adds "Quick note" to the app icon's long-press menu. Called after the
  /// other shortcuts are set, since setting those replaces the list.
  static Future<void> addShortcut() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('addShortcut');
    } catch (_) {}
  }

  /// Android 13+: asks to add the Quick Settings tile. False when the phone
  /// can't ask, so Settings shows how to add it by hand.
  static Future<bool> requestTile() async {
    if (!Platform.isAndroid) return false;
    try {
      return await _channel.invokeMethod<bool>('requestTile') ?? false;
    } catch (_) {
      return false;
    }
  }
}
