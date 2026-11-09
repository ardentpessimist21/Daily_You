// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/config_provider.dart';
import 'package:daily_you/utils/backup_restore_utils.dart';
import 'package:daily_you/database/attachment_storage.dart';
import 'package:daily_you/models/attachment.dart';
import 'package:daily_you/providers/entries_provider.dart';
import 'package:daily_you/storage/external_sync.dart';
import 'package:daily_you/storage/external_sync_settings.dart';
import 'package:daily_you/storage/storage_picker.dart';
import 'package:daily_you/storage/sync_progress.dart';
import 'package:daily_you/utils/file_size_format.dart';
import 'package:daily_you/utils/operation_outcome.dart';
import 'package:daily_you/widgets/app_dialog.dart';
import 'package:daily_you/widgets/attachment_type_presentation.dart';
import 'package:daily_you/widgets/database_overwrite_dialog.dart';
import 'package:daily_you/widgets/external_sync_dialog.dart';
import 'package:daily_you/widgets/failure_dialog.dart';
import 'package:daily_you/widgets/media_quality_dialog.dart';
import 'package:daily_you/widgets/settings_icon_action.dart';
import 'package:daily_you/widgets/settings_toggle.dart';
import 'package:daily_you/widgets/sync_progress_dialog.dart';
import 'package:daily_you/widgets/settings_group.dart';
import 'package:material_ui/material_ui.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:provider/provider.dart';

class StorageSettings extends StatefulWidget {
  const StorageSettings({super.key});

  @override
  State<StorageSettings> createState() => _StorageSettingsState();
}

class _StorageSettingsState extends State<StorageSettings> {
  late Map<AttachmentType, Future<int>> _usage;

  @override
  void initState() {
    super.initState();
    _usage = _loadUsage();
  }

  Map<AttachmentType, Future<int>> _loadUsage() => {
        for (final type in AttachmentType.values)
          type: AttachmentStorage.instance.internalSizeBytes(type),
      };

  void _refreshUsage() {
    if (mounted) setState(() => _usage = _loadUsage());
  }

  Future<void> _editSync({ExternalSyncSettings? draft}) async {
    final saved = ExternalSyncSettings.load();
    final desired = await showAppDialog<ExternalSyncSettings>(
        context: context,
        builder: (_) => ExternalSyncDialog(initial: saved, draft: draft));
    if (desired != null && mounted) await _applySync(saved, desired);
  }

  Future<void> _toggleSync(bool enabled) async {
    if (!enabled) {
      await _applySync(
          ExternalSyncSettings.load(), const ExternalSyncSettings());
      return;
    }

    final uri = (await StoragePicker.pickDirectoryWithAccess())?.uri;
    if (uri == null || !mounted) return;
    if (!await confirmDatabaseOverwrite(context, uri)) return;
    if (!mounted) return;
    await _editSync(draft: ExternalSyncSettings.withDefaults(uri));
  }

  Future<void> _applySync(
      ExternalSyncSettings saved, ExternalSyncSettings desired) async {
    final sync = ExternalSync(saved, desired);
    if (!sync.hasWork) {
      await sync.run((_) {});
      return;
    }

    final navigator = Navigator.of(context);
    final progress = ValueNotifier(SyncProgress(sync.items.first));
    showSyncProgressDialog(context, progress);
    final OperationOutcome outcome;
    try {
      outcome = await sync.run((value) => progress.value = value);
    } finally {
      navigator.pop();
    }
    if (!mounted) return;
    _refreshUsage();

    if (outcome.failed) {
      await showFailureDialog(context,
          description: AppLocalizations.of(context)!.syncErrorDescription,
          error: outcome.error);
    }
  }

  void _showDeleteAllLogsDialog(
      BuildContext context, String requiredText, VoidCallback onConfirm) {
    ThemeData theme = Theme.of(context);
    final TextEditingController controller = TextEditingController();
    final ValueNotifier<bool> isButtonEnabled = ValueNotifier(false);

    showAppDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.settingsDeleteAllLogsTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppLocalizations.of(context)!
                  .settingsDeleteAllLogsDescription),
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(AppLocalizations.of(context)!
                    .settingsDeleteAllLogsPrompt(requiredText)),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8.0, right: 8.0),
                    child: TextField(
                      decoration: InputDecoration(
                          hintStyle: TextStyle(fontStyle: FontStyle.italic),
                          hintText: requiredText,
                          border: InputBorder.none),
                      controller: controller,
                      onChanged: (value) {
                        isButtonEnabled.value = value.toLowerCase().trim() ==
                            requiredText.toLowerCase().trim();
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
            ),
            ValueListenableBuilder<bool>(
              valueListenable: isButtonEnabled,
              builder: (context, isEnabled, child) {
                return TextButton(
                  onPressed: isEnabled
                      ? () {
                          Navigator.of(context).pop();
                          onConfirm();
                        }
                      : null,
                  child: Text(
                      style: TextStyle(
                          color: isEnabled ? null : theme.disabledColor),
                      MaterialLocalizations.of(context).deleteButtonTooltip),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteAllLogs(BuildContext context) async {
    ValueNotifier<String> statusNotifier = ValueNotifier<String>("");

    BackupRestoreUtils.showLoadingStatus(context, statusNotifier);

    try {
      await EntriesProvider.instance.deleteAll((status) {
        statusNotifier.value = status;
      });

      await AttachmentStorage.instance.garbageCollectAttachments();
    } finally {
      if (context.mounted) Navigator.of(context).pop();
      _refreshUsage();
    }
  }

  String _formatBytes(int bytes) =>
      formatFileSize(bytes, AppLocalizations.of(context)!.localeName);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    Provider.of<ConfigProvider>(context);
    final syncSettings = ExternalSyncSettings.load();
    final syncedFolder = syncSettings.logFolderUri;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settingsStorageTitle),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.only(top: 8, bottom: 8),
        children: [
          SettingsGroup(children: [
            SettingsToggle(
              title: l10n.settingsExternalSyncTitle,
              leading: Icons.sync_rounded,
              hint: syncedFolder == null
                  ? null
                  : StoragePicker.displayName(syncedFolder),
              value: syncSettings.isOn,
              onChanged: _toggleSync,
              secondaryIcon:
                  syncSettings.isOn ? const Icon(Icons.edit_rounded) : null,
              onSecondaryPressed: _editSync,
            ),
          ]),
          SettingsGroup(title: l10n.settingsStorageUsage, children: [
            _StorageUsageCard(usage: _usage, format: _formatBytes),
            SettingsIconAction(
              title: l10n.settingsMediaQualityTitle,
              leading: Icons.high_quality_outlined,
              icon: const Icon(Icons.chevron_right_rounded),
              onPressed: () => showAppDialog(
                  context: context, builder: (_) => const MediaQualityDialog()),
            ),
          ]),
          SettingsGroup(children: [
            SettingsIconAction(
                title: AppLocalizations.of(context)!.settingsDeleteAllLogsTitle,
                leading: Icons.delete_forever_outlined,
                icon: Icon(Icons.delete_forever_rounded),
                onPressed: () => _showDeleteAllLogsDialog(
                    context,
                    AppLocalizations.of(context)!.settingsDeleteAllLogsTitle,
                    () => _deleteAllLogs(context))),
          ]),
        ],
      ),
    );
  }
}

/// Storage Usage (3.7.0.46): the total, a bar split by type, and one line
/// per type with its colour, icon and size.
class _StorageUsageCard extends StatelessWidget {
  const _StorageUsageCard({required this.usage, required this.format});

  final Map<AttachmentType, Future<int>> usage;
  final String Function(int bytes) format;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    final types = AttachmentType.values;
    Color colorOf(AttachmentType type) => [
          colors.primary,
          colors.tertiary,
          colors.secondary
        ][types.indexOf(type) % 3];
    return FutureBuilder<List<int>>(
      future: Future.wait([for (final type in types) usage[type]!]),
      builder: (context, snapshot) {
        final sizes = snapshot.data;
        final total = sizes?.fold<int>(0, (sum, size) => sum + size) ?? 0;
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    sizes == null ? '…' : format(total),
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 8),
                  Text(l10n.settingsStorageTotal,
                      style: TextStyle(color: colors.onSurfaceVariant)),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: SizedBox(
                  height: 10,
                  child: total == 0
                      ? ColoredBox(color: colors.surfaceContainerHighest)
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (var i = 0; i < types.length; i++)
                              if (sizes![i] > 0)
                                Expanded(
                                  // At least a sliver, so small types show
                                  flex:
                                      (sizes[i] * 1000 ~/ total).clamp(8, 1000),
                                  child: ColoredBox(color: colorOf(types[i])),
                                ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 8),
              for (var i = 0; i < types.length; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                            color: colorOf(types[i]), shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 12),
                      Icon(types[i].icon,
                          size: 20, color: colors.onSurfaceVariant),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(types[i].label(l10n),
                            overflow: TextOverflow.ellipsis),
                      ),
                      Text(sizes == null ? '' : format(sizes[i]),
                          style: TextStyle(
                              color: colors.onSurfaceVariant,
                              fontFeatures: const [
                                FontFeature.tabularFigures()
                              ])),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
