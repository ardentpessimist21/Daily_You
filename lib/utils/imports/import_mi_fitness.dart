// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:convert';

import 'package:daily_you/models/entry.dart';
import 'package:daily_you/storage/storage_picker.dart';
import 'package:daily_you/utils/imports/import_helpers.dart';
import 'package:daily_you/utils/imports/mi_fitness_gpx.dart';
import 'package:daily_you/utils/operation_outcome.dart';

/// Imports one workout exported from Mi Fitness as a GPX file, adding a
/// journal entry at the time the workout started.
Future<OperationOutcome> importFromMiFitness(
    Function(String) updateStatus) async {
  updateStatus("0%");

  var outcome = const OperationOutcome.succeeded();

  try {
    final selectedFile = await StoragePicker.pickFile(
        allowedExtensions: [
          'gpx'
        ],
        // Android file managers label .gpx files inconsistently.
        mimeTypes: [
          'application/gpx+xml',
          'application/xml',
          'text/xml',
          'application/octet-stream',
        ]);
    if (selectedFile == null) return const OperationOutcome.cancelled();

    final bytes = await selectedFile.readBytes();
    if (bytes == null) return const OperationOutcome.failed();

    final workout = parseGpxWorkout(utf8.decode(bytes, allowMalformed: true));

    await addImportedEntries([
      ImportedEntry(Entry(
        text: workoutEntryText(workout),
        timeCreate: workout.start,
        timeModified: DateTime.now(),
      )),
    ], updateStatus);
  } catch (error) {
    outcome = OperationOutcome.failed(error);
  }

  return finishImport(updateStatus, outcome);
}
