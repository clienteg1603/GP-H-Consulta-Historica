import 'package:flutter/widgets.dart';
import 'package:workmanager/workmanager.dart';

import '../data/history_repository.dart';
import '../models/history_result.dart';
import 'history_sync_service.dart';
import 'result_notification_service.dart';

const String backgroundHistoryTask = 'gph.background.history.sync';
const String backgroundHistoryUniqueWork = 'gph-background-history-sync';

const String _keyEnabled = 'background_sync_enabled';
const String _keyNotifications = 'background_sync_notifications';
const String _keyLastCheck = 'background_sync_last_check';
const String _keyLastError = 'background_sync_last_error';
const String _keyLastNewCount = 'background_sync_last_new_count';

class BackgroundSyncConfig {
  const BackgroundSyncConfig({
    required this.enabled,
    required this.notificationsEnabled,
    this.lastCheck,
    this.lastError,
    this.lastNewCount = 0,
  });

  final bool enabled;
  final bool notificationsEnabled;
  final DateTime? lastCheck;
  final String? lastError;
  final int lastNewCount;
}

class BackgroundSyncService {
  BackgroundSyncService({required HistoryRepository repository})
      : _repository = repository;

  final HistoryRepository _repository;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    await Workmanager().initialize(backgroundCallbackDispatcher);
    _initialized = true;
  }

  Future<BackgroundSyncConfig> config() async {
    final values = await Future.wait<String?>([
      _repository.setting(_keyEnabled),
      _repository.setting(_keyNotifications),
      _repository.setting(_keyLastCheck),
      _repository.setting(_keyLastError),
      _repository.setting(_keyLastNewCount),
    ]);
    return BackgroundSyncConfig(
      enabled: _asBool(values[0]),
      notificationsEnabled: _asBool(values[1]),
      lastCheck: values[2] == null ? null : DateTime.tryParse(values[2]!),
      lastError: values[3]?.trim().isEmpty ?? true ? null : values[3],
      lastNewCount: int.tryParse(values[4] ?? '') ?? 0,
    );
  }

  Future<void> ensureScheduled() async {
    await initialize();
    if (await _repository.boolSetting(_keyEnabled)) {
      await _schedule();
    }
  }

  Future<void> setEnabled(bool enabled) async {
    await _repository.saveBoolSetting(_keyEnabled, enabled);
    await initialize();
    if (enabled) {
      await _repository.saveSetting(_keyLastError, null);
      await _schedule();
    } else {
      await Workmanager().cancelByUniqueName(backgroundHistoryUniqueWork);
    }
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    await _repository.saveBoolSetting(_keyNotifications, enabled);
  }

  Future<void> _schedule() {
    return Workmanager().registerPeriodicTask(
      backgroundHistoryUniqueWork,
      backgroundHistoryTask,
      frequency: const Duration(minutes: 15),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
      constraints: Constraints(
        networkType: NetworkType.connected,
        requiresBatteryNotLow: true,
        requiresStorageNotLow: true,
      ),
    );
  }

  static bool _asBool(String? value) =>
      value == '1' || value?.toLowerCase() == 'true';
}

@pragma('vm:entry-point')
void backgroundCallbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    if (taskName != backgroundHistoryTask) return true;
    WidgetsFlutterBinding.ensureInitialized();
    return performBackgroundHistoryCheck();
  });
}

Future<bool> performBackgroundHistoryCheck() async {
  final repository = HistoryRepository();
  try {
    await repository.initialize();
    final enabled = await repository.boolSetting(_keyEnabled);
    if (!enabled) return true;

    final summary = await repository.summary();
    if (summary.isEmpty) {
      await repository.saveSetting(
        _keyLastError,
        'Prepare o histórico no app antes de usar a atualização automática.',
      );
      await repository.saveSetting(
        _keyLastCheck,
        DateTime.now().toIso8601String(),
      );
      return true;
    }

    final before = await _recentRows(repository);
    final sync = HistorySyncService(repository: repository);
    final result = await sync.sync(recentLookbackDays: 0);
    final after = await _recentRows(repository);
    final newRows = detectNewHistoryRows(before, after);

    final notifications = await repository.boolSetting(_keyNotifications);
    if (notifications && newRows.isNotEmpty) {
      final notificationService = ResultNotificationService();
      await notificationService.showNewResults(newRows);
    }

    await repository.saveSetting(
      _keyLastCheck,
      DateTime.now().toIso8601String(),
    );
    await repository.saveSetting(
      _keyLastNewCount,
      newRows.length.toString(),
    );
    await repository.saveSetting(
      _keyLastError,
      result.errors.isEmpty ? null : result.errors.first,
    );

    return result.errors.isEmpty;
  } catch (error) {
    await repository.saveSetting(
      _keyLastCheck,
      DateTime.now().toIso8601String(),
    );
    await repository.saveSetting(_keyLastError, error.toString());
    return false;
  }
}

Future<List<HistoryResult>> _recentRows(HistoryRepository repository) async {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = today.subtract(const Duration(days: 1));
  final values = await Future.wait([
    repository.forDate(yesterday),
    repository.forDate(today),
  ]);
  return [...values[0], ...values[1]];
}

List<HistoryResult> detectNewHistoryRows(
  Iterable<HistoryResult> before,
  Iterable<HistoryResult> after,
) {
  final known = before.map(_resultKey).toSet();
  final added = after.where((row) => !known.contains(_resultKey(row))).toList();
  added.sort((a, b) {
    final byDate = a.date.compareTo(b.date);
    if (byDate != 0) return byDate;
    final byTime = a.time.compareTo(b.time);
    if (byTime != 0) return byTime;
    final byDraw = a.draw.compareTo(b.draw);
    if (byDraw != 0) return byDraw;
    return a.prize.compareTo(b.prize);
  });
  return added;
}

String _resultKey(HistoryResult row) =>
    '${row.date}|${row.draw}|${row.time}|${row.prize}';
