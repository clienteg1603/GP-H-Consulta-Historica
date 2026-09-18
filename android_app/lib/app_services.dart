import 'data/history_repository.dart';
import 'services/app_update_service.dart';
import 'services/history_sync_service.dart';

class AppServices {
  AppServices._();

  static final HistoryRepository history = HistoryRepository();
  static final HistorySyncService sync = HistorySyncService(repository: history);
  static final AppUpdateService update = AppUpdateService();

  static Future<void> initialize() async {
    await history.initialize();
  }
}
