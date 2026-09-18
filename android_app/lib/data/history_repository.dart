import '../models/delay_summary.dart';
import '../models/history_result.dart';
import '../services/delay_calculator.dart';
import 'gph_database.dart';

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

  Future<List<HistoryResult>> search({
    required String mode,
    required String query,
    DateTime? start,
    DateTime? end,
  }) {
    return _database.search(
      mode: mode,
      query: query,
      startDate: start == null ? null : _isoDate(start),
      endDate: end == null ? null : _isoDate(end),
    );
  }

  Future<int> save(Iterable<HistoryResult> results) {
    return _database.upsertResults(results);
  }

  Future<String?> syncCursor() => _database.getSyncValue('next_date');

  Future<void> saveSyncCursor(String? isoDate) => _database.setSyncValue('next_date', isoDate);

  Future<void> saveLastSync(DateTime value) =>
      _database.setSyncValue('last_sync_at', value.toIso8601String());

  static String _isoDate(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
}
