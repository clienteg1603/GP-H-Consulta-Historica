import 'history_result.dart';

class AnimalDelayEntry {
  const AnimalDelayEntry({
    required this.group,
    required this.animal,
    required this.completeDraws,
    required this.delayAny,
    required this.delayHead,
    this.lastAny,
    this.lastHead,
  });

  final int group;
  final String animal;
  final int completeDraws;
  final int delayAny;
  final int delayHead;
  final HistoryResult? lastAny;
  final HistoryResult? lastHead;

  int delay({required bool firstPrizeOnly}) =>
      firstPrizeOnly ? delayHead : delayAny;

  HistoryResult? last({required bool firstPrizeOnly}) =>
      firstPrizeOnly ? lastHead : lastAny;
}
