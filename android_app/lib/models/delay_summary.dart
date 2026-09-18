import 'history_result.dart';

class DelayLeader {
  const DelayLeader({
    required this.value,
    required this.delay,
    required this.tieCount,
    required this.ties,
    this.last,
  });

  final String value;
  final int delay;
  final int tieCount;
  final List<String> ties;
  final HistoryResult? last;
}

class DelaySummary {
  const DelaySummary({
    required this.totalDraws,
    this.animalAny,
    this.animalHead,
    this.hundred,
    this.ten,
  });

  final int totalDraws;
  final DelayLeader? animalAny;
  final DelayLeader? animalHead;
  final DelayLeader? hundred;
  final DelayLeader? ten;

  bool get isEmpty => totalDraws == 0;
}
