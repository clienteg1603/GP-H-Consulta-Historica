import 'history_result.dart';

enum NumberDelayMode { ten, hundred }

class NumberDelayEntry {
  const NumberDelayEntry({
    required this.value,
    required this.completeDraws,
    required this.delay,
    this.lastOccurrence,
  });

  final String value;
  final int completeDraws;
  final int delay;
  final HistoryResult? lastOccurrence;
}
