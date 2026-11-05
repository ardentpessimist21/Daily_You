// HC Probe: a read-only look at what Health Connect holds, so Daily You's
// Health Connect plan can be based on real data. It never writes anything.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:health/health.dart';
import 'package:intl/intl.dart';

void main() => runApp(const ProbeApp());

class ProbeApp extends StatelessWidget {
  const ProbeApp({super.key});
  @override
  Widget build(BuildContext context) {
    final seed = const Color(0xFF3D6BB3);
    return MaterialApp(
      title: 'HC Probe',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: seed, useMaterial3: true),
      darkTheme: ThemeData(
          colorSchemeSeed: seed,
          brightness: Brightness.dark,
          useMaterial3: true),
      home: const ProbePage(),
    );
  }
}

/// Everything the probe reads. All of these are Android Health Connect types.
const readTypes = <HealthDataType>[
  HealthDataType.WORKOUT,
  HealthDataType.STEPS,
  HealthDataType.DISTANCE_DELTA,
  HealthDataType.SLEEP_SESSION,
  HealthDataType.SLEEP_ASLEEP,
  HealthDataType.SLEEP_LIGHT,
  HealthDataType.SLEEP_DEEP,
  HealthDataType.SLEEP_REM,
  HealthDataType.SLEEP_AWAKE,
  HealthDataType.HEART_RATE,
  HealthDataType.RESTING_HEART_RATE,
  HealthDataType.BLOOD_OXYGEN,
  HealthDataType.WEIGHT,
  HealthDataType.ACTIVE_ENERGY_BURNED,
  HealthDataType.TOTAL_CALORIES_BURNED,
  HealthDataType.FLIGHTS_CLIMBED,
];

const sleepStages = <HealthDataType>[
  HealthDataType.SLEEP_ASLEEP,
  HealthDataType.SLEEP_LIGHT,
  HealthDataType.SLEEP_DEEP,
  HealthDataType.SLEEP_REM,
  HealthDataType.SLEEP_AWAKE,
];

class ProbePage extends StatefulWidget {
  const ProbePage({super.key});
  @override
  State<ProbePage> createState() => _ProbePageState();
}

class _ProbePageState extends State<ProbePage> {
  final health = Health();
  final dayFmt = DateFormat('EEE d MMM yyyy');
  final timeFmt = DateFormat('h:mm a');

  String status = 'Checking Health Connect…';
  bool ready = false;
  bool? granted;
  bool historyAvailable = false;
  bool historyGranted = false;
  bool loading = false;
  int rangeDays = 30;

  // Results
  Map<HealthDataType, List<HealthDataPoint>> byType = {};
  Map<HealthDataType, String> errors = {};
  List<MapEntry<DateTime, int?>> stepsByDay = [];
  DateTime? oldestFound;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      await health.configure();
      final s = await health.getHealthConnectSdkStatus();
      if (s != HealthConnectSdkStatus.sdkAvailable) {
        setState(() => status = s == HealthConnectSdkStatus
                .sdkUnavailableProviderUpdateRequired
            ? 'Health Connect needs an update.'
            : 'Health Connect isn\'t available on this phone.');
        return;
      }
      ready = true;
      await _refreshPermissions();
      setState(() => status = 'Health Connect is available.');
    } catch (e) {
      setState(() => status = 'Couldn\'t start: $e');
    }
  }

  Future<void> _refreshPermissions() async {
    try {
      granted = await health.hasPermissions(readTypes,
          permissions: List.filled(readTypes.length, HealthDataAccess.READ));
    } catch (_) {
      granted = null;
    }
    try {
      historyAvailable = await health.isHealthDataHistoryAvailable();
      historyGranted =
          historyAvailable && await health.isHealthDataHistoryAuthorized();
    } catch (_) {}
    if (mounted) setState(() {});
  }

  Future<void> _requestAccess() async {
    try {
      await health.requestAuthorization(readTypes,
          permissions: List.filled(readTypes.length, HealthDataAccess.READ));
    } catch (e) {
      _snack('Access request failed: $e');
    }
    await _refreshPermissions();
  }

  Future<void> _requestHistory() async {
    try {
      await health.requestHealthDataHistoryAuthorization();
    } catch (e) {
      _snack('Past data request failed: $e');
    }
    await _refreshPermissions();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      byType = {};
      errors = {};
      stepsByDay = [];
      oldestFound = null;
    });
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: rangeDays - 1));

    // One type at a time, so one failing type doesn't hide the others.
    for (final t in readTypes) {
      try {
        final pts = await health.getHealthDataFromTypes(
            types: [t], startTime: start, endTime: now);
        pts.sort((a, b) => b.dateFrom.compareTo(a.dateFrom));
        byType[t] = pts;
        for (final p in pts) {
          if (oldestFound == null || p.dateFrom.isBefore(oldestFound!)) {
            oldestFound = p.dateFrom;
          }
        }
      } catch (e) {
        errors[t] = '$e';
      }
      if (mounted) setState(() {});
    }

    // Daily step totals (Health Connect removes double counts between apps).
    final days = rangeDays > 60 ? 60 : rangeDays;
    final today = DateTime(now.year, now.month, now.day);
    for (var i = 0; i < days; i++) {
      final d = today.subtract(Duration(days: i));
      int? total;
      try {
        total = await health.getTotalStepsInInterval(
            d, i == 0 ? now : d.add(const Duration(days: 1)));
      } catch (_) {}
      stepsByDay.add(MapEntry(d, total));
    }
    setState(() => loading = false);
  }

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  // ---------- formatting helpers ----------

  String _dur(Duration d) {
    final h = d.inHours, m = d.inMinutes.remainder(60);
    return h > 0 ? '${h}h ${m}m' : '${m}m';
  }

  String _km(num? metres) =>
      metres == null ? '—' : '${(metres / 1000).toStringAsFixed(2)} km';

  String _num(HealthValue v) {
    if (v is NumericHealthValue) {
      final n = v.numericValue;
      return n % 1 == 0 ? '$n' : n.toStringAsFixed(1);
    }
    return v.toString();
  }

  String _workoutType(HealthDataPoint p) {
    final v = p.value;
    if (v is WorkoutHealthValue) {
      return v.workoutActivityType.name
          .replaceAll('_', ' ')
          .toLowerCase()
          .replaceFirstMapped(RegExp(r'^\w'), (m) => m[0]!.toUpperCase());
    }
    return 'Workout';
  }

  String _sources(List<HealthDataPoint> pts) {
    final counts = <String, int>{};
    for (final p in pts) {
      final name = p.sourceName.isNotEmpty ? p.sourceName : p.sourceId;
      counts[name] = (counts[name] ?? 0) + 1;
    }
    return counts.entries.map((e) => '${e.key} (${e.value})').join(', ');
  }

  String _typeName(HealthDataType t) => t.name
      .replaceAll('_', ' ')
      .toLowerCase()
      .replaceFirstMapped(RegExp(r'^\w'), (m) => m[0]!.toUpperCase());

  // ---------- report ----------

  String _report() {
    final b = StringBuffer();
    b.writeln('HC Probe report — ${dayFmt.format(DateTime.now())}');
    b.writeln('Range: last $rangeDays days');
    b.writeln('Access: ${granted == true ? 'granted' : granted == false ? 'not fully granted' : 'unknown'}'
        ' · Past data: ${!historyAvailable ? 'not supported' : historyGranted ? 'granted' : 'not granted'}');
    if (oldestFound != null) {
      b.writeln('Oldest record found: ${dayFmt.format(oldestFound!)}');
    }
    b.writeln();
    b.writeln('DATA TYPES');
    for (final t in readTypes) {
      final pts = byType[t];
      if (errors.containsKey(t)) {
        b.writeln('- ${_typeName(t)}: error (${errors[t]})');
      } else if (pts == null || pts.isEmpty) {
        b.writeln('- ${_typeName(t)}: none');
      } else {
        b.writeln('- ${_typeName(t)}: ${pts.length} · from ${_sources(pts)}');
      }
    }
    final w = byType[HealthDataType.WORKOUT] ?? [];
    if (w.isNotEmpty) {
      b.writeln();
      b.writeln('WORKOUTS (latest 15)');
      for (final p in w.take(15)) {
        final v = p.value is WorkoutHealthValue
            ? p.value as WorkoutHealthValue
            : null;
        b.writeln('- ${dayFmt.format(p.dateFrom)} · ${_workoutType(p)} · '
            '${timeFmt.format(p.dateFrom)}–${timeFmt.format(p.dateTo)} '
            '(${_dur(p.dateTo.difference(p.dateFrom))}) · '
            'distance ${_km(v?.totalDistance)} · steps ${v?.totalSteps ?? '—'} · '
            'kcal ${v?.totalEnergyBurned ?? '—'} · ${p.sourceName}');
      }
    }
    final s = byType[HealthDataType.SLEEP_SESSION] ?? [];
    if (s.isNotEmpty) {
      b.writeln();
      b.writeln('SLEEP (latest 10)');
      for (final p in s.take(10)) {
        b.writeln('- ${dayFmt.format(p.dateTo)} · '
            '${timeFmt.format(p.dateFrom)}–${timeFmt.format(p.dateTo)} '
            '(${_dur(p.dateTo.difference(p.dateFrom))}) · ${_stageLine(p)} · ${p.sourceName}');
      }
    }
    if (stepsByDay.isNotEmpty) {
      b.writeln();
      b.writeln('STEPS PER DAY (latest 14)');
      for (final e in stepsByDay.take(14)) {
        b.writeln('- ${dayFmt.format(e.key)}: ${e.value ?? '—'}');
      }
    }
    return b.toString();
  }

  /// Minutes in each sleep stage that fall inside this session.
  String _stageLine(HealthDataPoint session) {
    final parts = <String>[];
    for (final t in sleepStages) {
      var mins = 0;
      for (final p in byType[t] ?? const <HealthDataPoint>[]) {
        if (!p.dateFrom.isBefore(session.dateFrom) &&
            !p.dateTo.isAfter(session.dateTo)) {
          mins += p.dateTo.difference(p.dateFrom).inMinutes;
        }
      }
      if (mins > 0) {
        parts.add('${_typeName(t).replaceFirst('Sleep ', '')} ${_dur(Duration(minutes: mins))}');
      }
    }
    return parts.isEmpty ? 'no stages' : parts.join(', ');
  }

  // ---------- UI ----------

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hasData = byType.isNotEmpty;
    return Scaffold(
      appBar: AppBar(
        title: const Text('HC Probe'),
        actions: [
          if (hasData && !loading)
            IconButton(
              tooltip: 'Copy report',
              icon: const Icon(Icons.copy_all_outlined),
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: _report()));
                _snack('Report copied. Paste it into the chat.');
              },
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(status, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text('Read-only. Nothing is saved or written.',
                      style: TextStyle(color: cs.onSurfaceVariant)),
                  if (ready) ...[
                    const SizedBox(height: 12),
                    _permRow('Access to health data', granted == true,
                        'Grant access', _requestAccess),
                    _permRow(
                        'Past data (older than 30 days)',
                        historyGranted,
                        historyAvailable ? 'Allow' : null,
                        _requestHistory,
                        note: historyAvailable ? null : 'Not supported here'),
                  ] else ...[
                    const SizedBox(height: 12),
                    FilledButton.tonal(
                        onPressed: () => health.installHealthConnect(),
                        child: const Text('Get Health Connect')),
                  ],
                ],
              ),
            ),
          ),
          if (ready) ...[
            const SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final d in [7, 30, 90, 365])
                ChoiceChip(
                  label: Text(d == 365 ? '1 year' : '$d days'),
                  selected: rangeDays == d,
                  onSelected: loading ? null : (_) => setState(() => rangeDays = d),
                ),
            ]),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: loading ? null : _load,
              icon: loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.search),
              label: Text(loading ? 'Reading…' : 'Read data'),
            ),
          ],
          if (hasData) ...[
            const SizedBox(height: 20),
            _header('What\'s in Health Connect'),
            if (oldestFound != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text('Oldest record found: ${dayFmt.format(oldestFound!)}',
                    style: TextStyle(color: cs.onSurfaceVariant)),
              ),
            for (final t in readTypes) _typeTile(t),
            _header('Workouts'),
            ..._workoutTiles(),
            _header('Sleep'),
            ..._sleepTiles(),
            _header('Steps per day'),
            for (final e in stepsByDay.take(30))
              ListTile(
                dense: true,
                title: Text(dayFmt.format(e.key)),
                trailing: Text(e.value == null ? '—' : NumberFormat.decimalPattern().format(e.value),
                    style: const TextStyle(fontFeatures: [FontFeature.tabularFigures()])),
              ),
          ],
        ],
      ),
    );
  }

  Widget _permRow(String label, bool ok, String? action, VoidCallback onTap,
      {String? note}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Icon(ok ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 20,
            color: ok
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline),
        const SizedBox(width: 10),
        Expanded(child: Text(note == null ? label : '$label · $note')),
        if (!ok && action != null)
          TextButton(onPressed: onTap, child: Text(action)),
      ]),
    );
  }

  Widget _header(String t) => Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 6),
        child: Text(t, style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w700)),
      );

  Widget _typeTile(HealthDataType t) {
    final pts = byType[t];
    final err = errors[t];
    final cs = Theme.of(context).colorScheme;
    String sub;
    if (err != null) {
      sub = 'Error: $err';
    } else if (pts == null) {
      sub = '…';
    } else if (pts.isEmpty) {
      sub = 'No records';
    } else {
      final latest = pts.first;
      sub = 'Latest ${dayFmt.format(latest.dateFrom)}'
          '${t == HealthDataType.WORKOUT || t.name.startsWith('SLEEP') ? '' : ' · ${_num(latest.value)} ${latest.unitString.toLowerCase()}'}'
          '\nFrom ${_sources(pts)}';
    }
    final count = pts?.length ?? 0;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(_typeName(t)),
      subtitle: Text(sub,
          style: TextStyle(color: err != null ? cs.error : cs.onSurfaceVariant)),
      trailing: Text('$count',
          style: TextStyle(
              fontWeight: FontWeight.w700,
              color: count > 0 ? cs.primary : cs.outline)),
    );
  }

  List<Widget> _workoutTiles() {
    final w = byType[HealthDataType.WORKOUT] ?? [];
    if (w.isEmpty) return [const Text('No workouts in this range.')];
    return [
      for (final p in w.take(30))
        Card(
          child: ListTile(
            leading: const Icon(Icons.directions_walk),
            title: Text('${_workoutType(p)} · ${_km(p.value is WorkoutHealthValue ? (p.value as WorkoutHealthValue).totalDistance : null)}'),
            subtitle: Text('${dayFmt.format(p.dateFrom)}\n'
                '${timeFmt.format(p.dateFrom)}–${timeFmt.format(p.dateTo)} · '
                '${_dur(p.dateTo.difference(p.dateFrom))}'
                '${p.value is WorkoutHealthValue && (p.value as WorkoutHealthValue).totalSteps != null ? ' · ${(p.value as WorkoutHealthValue).totalSteps} steps' : ''}'
                '\n${p.sourceName}'),
            isThreeLine: true,
          ),
        ),
    ];
  }

  List<Widget> _sleepTiles() {
    final s = byType[HealthDataType.SLEEP_SESSION] ?? [];
    if (s.isEmpty) return [const Text('No sleep sessions in this range.')];
    return [
      for (final p in s.take(30))
        Card(
          child: ListTile(
            leading: const Icon(Icons.bedtime_outlined),
            title: Text('${_dur(p.dateTo.difference(p.dateFrom))} · night ending ${DateFormat('EEE d MMM').format(p.dateTo)}'),
            subtitle: Text('${timeFmt.format(p.dateFrom)}–${timeFmt.format(p.dateTo)}\n'
                '${_stageLine(p)} · ${p.sourceName}'),
            isThreeLine: true,
          ),
        ),
    ];
  }
}
