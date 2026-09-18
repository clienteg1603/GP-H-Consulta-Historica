import '../models/animal_delay_stats.dart';
import '../models/delay_summary.dart';
import '../models/frequency_stats.dart';
import '../models/history_result.dart';
import '../models/number_delay_stats.dart';
import '../models/number_overview.dart';
import '../models/strong_number_stats.dart';
import '../services/animal_delay_calculator.dart';
import '../services/delay_calculator.dart';
import '../services/number_delay_calculator.dart';
import '../services/strong_number_calculator.dart';
import 'animals.dart';
import 'gph_database.dart';
import 'gph_database_number_details.dart';
import 'gph_database_rankings.dart';

class HistorySummary {
  const HistorySummary({
    required this.totalPrizes,
    this.firstDate,
    this.lastDate,
  });

  final int totalPrizes;
  final String? firstDate;
  final String? lastDate;

  bool get isEmpty => totalPrizes == 0;
}

class HistoryRepository {
  HistoryRepository({GphDatabase? database}) : _database = database ?? GphDatabase.instance;

  final GphDatabase _database;

  Future<void> initialize() async {
    await _database.database;
  }

  Future<HistorySummary> summary() async {
    final values = await Future.wait<Object?>([
      _database.countResults(),
      _database.firstDate(),
      _database.lastDate(),
    ]);
    return HistorySummary(
      totalPrizes: values[0] as int,
      firstDate: values[1] as String?,
      lastDate: values[2] as String?,
    );
  }

  Future<List<HistoryResult>> forDate(DateTime date) {
    return _database.resultsForDate(_isoDate(date));
  }

  Future<List<HistoryResult>> latest({int limit = 25}) {
    return _database.latest(limit: limit);
  }

  Future<DelaySummary> delays() async {
    final rows = await _database.resultsForDelayAnalysis();
    return DelayCalculator.calculate(rows);
  }

  Future<List<AnimalDelayEntry>> animalDelays() async {
    final rows = await _database.resultsForDelayAnalysis();
    return AnimalDelayCalculator.calculate(rows);
  }

  Future<List<NumberDelayEntry>> numberDelays(NumberDelayMode mode) async {
    final rows = await _database.resultsForDelayAnalysis();
    return NumberDelayCalculator.calculate(rows, mode: mode);
  }

  Future<NumberOverview> numberOverview({
    required String mode,
    required String value,
  }) async {
    final normalized = normalizeNumberValue(mode, value);
    final aggregateFuture = _database.numberAggregate(mode: mode, query: normalized);
    final recentFuture = _database.latestForNumber(
      mode: mode,
      query: normalized,
      limit: 12,
    );
    final firstFuture = _database.latestForNumber(
      mode: mode,
      query: normalized,
      prize: 1,
      limit: 1,
    );
    final delayFuture = switch (mode) {
      'Dezena' => numberDelays(NumberDelayMode.ten),
      'Centena' => numberDelays(NumberDelayMode.hundred),
      _ => Future<List<NumberDelayEntry>>.value(const <NumberDelayEntry>[]),
    };

    final aggregate = await aggregateFuture;
    final recent = await recentFuture;
    final firstRows = await firstFuture;
    final delayRows = await delayFuture;
    final delay = delayRows.where((item) => item.value == normalized).firstOrNull;
    final group = groupForNumberValue(normalized);
    final animal = group >= 1 && group <= gphAnimals.length
        ? gphAnimals.firstWhere((item) => item.group == group).name
        : '';

    return NumberOverview(
      mode: mode,
      value: normalized,
      group: group,
      animal: animal,
      totalAppearances: _asInt(aggregate['total']),
      firstPrizeAppearances: _asInt(aggregate['cabecas']),
      currentDelay: delay?.delay,
      completeDraws: delay?.completeDraws,
      lastAny: recent.isEmpty ? null : recent.first,
      lastFirst: firstRows.isEmpty ? null : firstRows.first,
      recent: recent,
    );
  }

  Future<List<String>> availableDraws() => _database.distinctDraws();

  Future<List<FrequencyEntry>> animalFrequency({
    required bool firstPrizeOnly,
    int? days,
  }) async {
    String? startDate;
    if (days != null) {
      final today = DateTime.now();
      final start = DateTime(today.year, today.month, today.day)
          .subtract(Duration(days: days - 1));
      startDate = _isoDate(start);
    }

    final rows = await _database.frequencyByAnimal(
      firstPrizeOnly: firstPrizeOnly,
      startDate: startDate,
    );
    final total = rows.fold<int>(0, (sum, row) => sum + _asInt(row['total']));

    return rows.map((row) {
      final lastKey = (row['ultima_chave'] ?? '').toString();
      final parts = lastKey.split(' ');
      return FrequencyEntry(
        group: _asInt(row['grupo']),
        animal: (row['bicho'] ?? '').toString(),
        count: _asInt(row['total']),
        total: total,
        lastDate: (row['ultima_data'] ?? '').toString().isEmpty
            ? null
            : row['ultima_data'].toString(),
        lastTime: parts.length > 1 ? parts.last : null,
      );
    }).toList(growable: false);
  }

  Future<AnimalOverview> animalOverview(int group) async {
    final values = await Future.wait<Object?>([
      _database.animalAggregate(group),
      _database.latestForGroup(group, limit: 8),
      _database.latestForGroup(group, prize: 1, limit: 1),
      _database.resultsForDelayAnalysis(),
    ]);
    final aggregate = values[0] as Map<String, Object?>;
    final recent = values[1] as List<HistoryResult>;
    final firstRows = values[2] as List<HistoryResult>;
    final delayRows = values[3] as List<HistoryResult>;
    final delayEntries = AnimalDelayCalculator.calculate(delayRows);
    final delay = delayEntries.where((item) => item.group == group).firstOrNull;
    final animal = recent.isNotEmpty
        ? _titleCase(recent.first.animal)
        : gphAnimals.firstWhere((item) => item.group == group).name;

    return AnimalOverview(
      group: group,
      animal: animal,
      totalAppearances: _asInt(aggregate['total']),
      firstPrizeAppearances: _asInt(aggregate['cabecas']),
      delayAny: delay?.delayAny ?? 0,
      delayHead: delay?.delayHead ?? 0,
      completeDraws: delay?.completeDraws ?? 0,
      lastAny: recent.isEmpty ? null : recent.first,
      lastFirst: firstRows.isEmpty ? null : firstRows.first,
      recent: recent,
    );
  }

  Future<List<StrongNumberEntry>> strongNumbers({
    required int group,
    required StrongNumberKind kind,
    required bool firstPrizeOnly,
  }) async {
    final rows = await _database.rowsForGroupNumberRanking(
      group,
      firstPrizeOnly: firstPrizeOnly,
    );
    return StrongNumberCalculator.calculate(rows, kind);
  }

  Future<List<HistoryResult>> search({
    required String mode,
    required String query,
    DateTime? start,
    DateTime? end,
    int? prize,
    String? draw,
  }) {
    return _database.search(
      mode: mode,
      query: query,
      startDate: start == null ? null : _isoDate(start),
      endDate: end == null ? null : _isoDate(end),
      prize: prize,
      draw: draw,
    );
  }

  Future<int> save(Iterable<HistoryResult> results) {
    return _database.upsertResults(results);
  }

  Future<String?> syncCursor() => _database.getSyncValue('next_date');

  Future<void> saveSyncCursor(String? isoDate) => _database.setSyncValue('next_date', isoDate);

  Future<void> saveLastSync(DateTime value) =>
      _database.setSyncValue('last_sync_at', value.toIso8601String());

  static int _asInt(Object? value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static String _titleCase(String value) {
    final trimmed = value.trim().toLowerCase();
    if (trimmed.isEmpty) return value;
    return '${trimmed[0].toUpperCase()}${trimmed.substring(1)}';
  }

  static String _isoDate(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
