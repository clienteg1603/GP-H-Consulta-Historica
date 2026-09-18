import 'history_result.dart';

class FrequencyEntry {
  const FrequencyEntry({
    required this.group,
    required this.animal,
    required this.count,
    required this.total,
    this.lastDate,
    this.lastTime,
  });

  final int group;
  final String animal;
  final int count;
  final int total;
  final String? lastDate;
  final String? lastTime;

  double get percentage => total <= 0 ? 0 : (count * 100) / total;
}

class AnimalOverview {
  const AnimalOverview({
    required this.group,
    required this.animal,
    required this.totalAppearances,
    required this.firstPrizeAppearances,
    required this.delayAny,
    required this.delayHead,
    required this.completeDraws,
    required this.recent,
    this.lastAny,
    this.lastFirst,
  });

  final int group;
  final String animal;
  final int totalAppearances;
  final int firstPrizeAppearances;
  final int delayAny;
  final int delayHead;
  final int completeDraws;
  final HistoryResult? lastAny;
  final HistoryResult? lastFirst;
  final List<HistoryResult> recent;
}
