import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../models/history_result.dart';

class ResultNotificationService {
  ResultNotificationService();

  static const String channelId = 'gph_new_results';
  static const String channelName = 'Novos resultados';
  static const String channelDescription =
      'Avisos quando o GP-H encontra novos resultados na atualização automática.';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );
    await _plugin.initialize(settings);
    _initialized = true;
  }

  Future<bool> requestPermission() async {
    await initialize();
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return true;
    return await android.requestPermission() ?? false;
  }

  Future<void> showNewResults(List<HistoryResult> rows) async {
    if (rows.isEmpty) return;
    await initialize();

    final ordered = [...rows]
      ..sort((a, b) {
        final date = a.date.compareTo(b.date);
        if (date != 0) return date;
        final time = a.time.compareTo(b.time);
        if (time != 0) return time;
        final draw = a.draw.compareTo(b.draw);
        if (draw != 0) return draw;
        return a.prize.compareTo(b.prize);
      });

    final latest = ordered.last;
    final sameDraw = ordered
        .where(
          (row) =>
              row.date == latest.date &&
              row.time == latest.time &&
              row.draw == latest.draw,
        )
        .toList(growable: false)
      ..sort((a, b) => a.prize.compareTo(b.prize));

    final title = sameDraw.length == ordered.length
        ? 'Novo resultado • ${latest.draw} ${latest.time}'
        : '${ordered.length} novos prêmios encontrados';
    final body = sameDraw
        .take(5)
        .map((row) => '${row.prize}º ${row.thousand} ${_titleCase(row.animal)}')
        .join(' • ');

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        styleInformation: BigTextStyleInformation(body),
      ),
    );

    final id = _notificationId(latest);
    await _plugin.show(
      id,
      title,
      body,
      details,
      payload: 'new-results',
    );
  }

  int _notificationId(HistoryResult row) {
    final source = '${row.date}|${row.time}|${row.draw}';
    return source.hashCode & 0x7fffffff;
  }

  String _titleCase(String value) {
    final trimmed = value.trim().toLowerCase();
    if (trimmed.isEmpty) return value;
    return '${trimmed[0].toUpperCase()}${trimmed.substring(1)}';
  }
}
