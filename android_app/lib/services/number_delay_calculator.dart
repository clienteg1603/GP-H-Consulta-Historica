import '../models/history_result.dart';
import '../models/number_delay_stats.dart';

class NumberDelayCalculator {
  const NumberDelayCalculator._();

  static List<NumberDelayEntry> calculate(
    List<HistoryResult> sourceRows, {
    required NumberDelayMode mode,
  }) {
    if (sourceRows.isEmpty) return const [];

    final rows = [...sourceRows]
      ..sort((a, b) {
        final byDate = a.date.compareTo(b.date);
        if (byDate != 0) return byDate;
        final byTime = a.time.compareTo(b.time);
        if (byTime != 0) return byTime;
        final byDraw = a.draw.compareTo(b.draw);
        if (byDraw != 0) return byDraw;
        return a.prize.compareTo(b.prize);
      });

    final grouped = <String, List<HistoryResult>>{};
    for (final row in rows) {
      if (row.prize < 1 || row.prize > 5) continue;
      final key = '${row.date}|${row.time}|${row.draw}';
      grouped.putIfAbsent(key, () => <HistoryResult>[]).add(row);
    }

    final complete = grouped.values.where((drawRows) {
      final prizes = drawRows.map((row) => row.prize).toSet();
      return prizes.length >= 5 &&
          List.generate(5, (index) => index + 1).every(prizes.contains);
    }).toList(growable: false);

    if (complete.isEmpty) return const [];

    final totalValues = mode == NumberDelayMode.ten ? 100 : 1000;
    final width = mode == NumberDelayMode.ten ? 2 : 3;
    final lastIndex = List<int>.filled(totalValues, -1);
    final lastRows = <int, HistoryResult>{};

    for (var index = 0; index < complete.length; index++) {
      final seen = <int>{};
      for (final row in complete[index]) {
        final raw = mode == NumberDelayMode.ten ? row.ten : row.hundred;
        final value = int.tryParse(raw);
        if (value == null || value < 0 || value >= totalValues) continue;
        if (seen.add(value)) {
          lastIndex[value] = index;
          lastRows[value] = row;
        }
      }
    }

    final totalDraws = complete.length;
    final result = List<NumberDelayEntry>.generate(totalValues, (value) {
      final index = lastIndex[value];
      return NumberDelayEntry(
        value: value.toString().padLeft(width, '0'),
        completeDraws: totalDraws,
        delay: totalDraws - 1 - index,
        lastOccurrence: lastRows[value],
      );
    });

    result.sort((a, b) {
      final byDelay = b.delay.compareTo(a.delay);
      if (byDelay != 0) return byDelay;
      return int.parse(a.value).compareTo(int.parse(b.value));
    });

    return result;
  }
}
