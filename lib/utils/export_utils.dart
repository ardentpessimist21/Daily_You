// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:io';

import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:daily_you/models/attachment.dart';
import 'package:daily_you/storage/local_file_store.dart';
import 'package:daily_you/storage/storage_picker.dart';
import 'package:daily_you/time_manager.dart';
import 'package:daily_you/utils/exports/export_snapshot.dart';
import 'package:daily_you/utils/exports/export_writers.dart';
import 'package:daily_you/utils/operation_outcome.dart';
import 'package:daily_you/utils/zip_utils.dart';
import 'package:daily_you/widgets/app_dialog.dart';
import 'package:daily_you/widgets/attachment_type_presentation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

/// The export formats (Update D: CSV, JSON and Day One join Markdown).
enum ExportFormat { markdown, csv, json, dayOne }

class ExportFormatOption {
  const ExportFormatOption(this.format, this.name, this.write,
      {this.documentName, this.documentMimeType, this.alwaysZip = false});

  final ExportFormat format;
  final String Function(AppLocalizations localizations) name;
  final ExportWriter write;

  /// With no attachments, this one file is saved on its own, not zipped.
  final String? documentName;
  final String? documentMimeType;

  /// Zipped even without attachments (Markdown's many notes, Day One).
  final bool alwaysZip;
}

class ExportUtils {
  ExportUtils._();

  static final List<ExportFormatOption> options = [
    ExportFormatOption(
        ExportFormat.markdown, (l10n) => l10n.formatMarkdown, writeMarkdown,
        alwaysZip: true),
    ExportFormatOption(ExportFormat.csv, (l10n) => l10n.formatCsv, writeCsv,
        documentName: csvDocumentName, documentMimeType: 'text/csv'),
    ExportFormatOption(ExportFormat.json, (l10n) => l10n.formatJson, writeJson,
        documentName: jsonDocumentName, documentMimeType: 'application/json'),
    ExportFormatOption(
        ExportFormat.dayOne, (l10n) => l10n.formatDayOne, writeDayOne,
        alwaysZip: true),
  ];

  static ExportFormatOption optionFor(ExportFormat format) =>
      options.firstWhere((option) => option.format == format);

  /// Asks which attachment types to include and where to save, then writes
  /// [option]'s export there: one file, or a .zip with the attachments.
  static Future<OperationOutcome> export(BuildContext context,
      ExportFormatOption option, void Function(String) updateStatus) async {
    final localizations = AppLocalizations.of(context)!;
    final locale = TimeManager.currentLocale(context);

    final includedTypes = await pickIncludedTypes(context);
    if (includedTypes == null) return const OperationOutcome.cancelled();

    updateStatus("(1/2) 0%");

    PickedDirectory? folder;
    try {
      folder = await StoragePicker.pickDirectory();
    } catch (error) {
      return OperationOutcome.failed(error);
    }
    if (folder == null) return const OperationOutcome.cancelled();

    Directory? staging;
    try {
      staging = await (await getTemporaryDirectory()).createTemp('export_');
      final documents =
          await Directory(join(staging.path, 'documents')).create();
      final snapshot = await buildExportSnapshot(
          locale: locale,
          includedTypes: includedTypes,
          onProgress: (fraction) =>
              updateStatus("(1/2) ${(fraction * 100).round()}%"));
      final sources =
          await option.write(snapshot, LocalFileStore(documents.path));

      final single =
          sources.isEmpty && !option.alwaysZip ? option.documentName : null;
      final stamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final exportName = single == null
          ? 'daily_you_${option.format.name}_export_$stamp.zip'
          : 'daily_you_${option.format.name}_export_$stamp${extension(single)}';

      final String exportPath;
      if (single == null) {
        exportPath = join(staging.path, exportName);
        final written = documents.listSync();
        await ZipUtils.compress(
            exportPath,
            [for (final file in written.whereType<File>()) file.path],
            [for (final dir in written.whereType<Directory>()) dir.path],
            filesByArchivePath: sources,
            onProgress: (percent) => updateStatus("(2/2) ${percent.round()}%"));
      } else {
        exportPath = join(documents.path, single);
      }

      updateStatus(localizations.tranferStatus("0"));
      await folder.copyFileInto(exportPath, exportName,
          mimeType:
              single == null ? 'application/zip' : option.documentMimeType!,
          onProgress: (percent) =>
              updateStatus(localizations.tranferStatus("${percent.round()}")));
      return const OperationOutcome.succeeded();
    } catch (error) {
      return OperationOutcome.failed(error);
    } finally {
      updateStatus(localizations.cleanUpStatus);
      if (staging != null && await staging.exists()) {
        await staging.delete(recursive: true);
      }
    }
  }

  /// Which attachment types go in; null if cancelled.
  static Future<Set<AttachmentType>?> pickIncludedTypes(
      BuildContext context) async {
    final included = {...AttachmentType.values};
    return showAppDialog<Set<AttachmentType>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setLocalState) => AlertDialog(
          title: Text(AppLocalizations.of(dialogContext)!.exportIncludeTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final type in AttachmentType.values)
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: included.contains(type),
                  title: Text(type.label(AppLocalizations.of(dialogContext)!)),
                  onChanged: (value) => setLocalState(() {
                    if (value ?? false) {
                      included.add(type);
                    } else {
                      included.remove(type);
                    }
                  }),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                  MaterialLocalizations.of(dialogContext).cancelButtonLabel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, included),
              child: Text(AppLocalizations.of(dialogContext)!.settingsExport),
            ),
          ],
        ),
      ),
    );
  }
}
