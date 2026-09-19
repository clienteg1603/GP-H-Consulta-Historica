import 'data/history_repository.dart';
import 'services/app_update_service.dart';
import 'services/background_sync_service.dart';
import 'services/history_sync_service.dart';
import 'services/result_notification_service.dart';

class AppServices {
  AppServices._();

  static final HistoryRepository history = HistoryRepository();
  static final HistorySyncService sync = HistorySyncService(repository: history);
  static final AppUpdateService update = AppUpdateService();
  static final ResultNotificationService notifications = ResultNotificationService();
  static final BackgroundSyncService background =
      BackgroundSyncService(repository: history);

  static Future<void> initialize() async {
    await history.initialize();
    await notifications.initialize();
    await background.initialize();
    await background.ensureScheduled();
  }
}
