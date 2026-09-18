import '../data/animals.dart';
import '../models/animal_delay_stats.dart';
import '../models/history_result.dart';

class AnimalDelayCalculator {
  const AnimalDelayCalculator._();

  static List<AnimalDelayEntry> calculate(List<HistoryResult> sourceRows) {
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
      return prizes.length >= 5 && List.generate(5, (i) => i + 1).every(prizes.contains);
    }).toList(growable: false);

    if (complete.isEmpty) return const [];

    final lastAnyIndex = <int, int>{for (var group = 1; group <= 25; group++) group: -1};
    final lastHeadIndex = <int, int>{for (var group = 1; group <= 25; group++) group: -1};
    final lastAnyRow = <int, HistoryResult>{};
    final lastHeadRow = <int, HistoryResult>{};

    for (var index = 0; index < complete.length; index++) {
      final drawRows = complete[index];
      for (final row in drawRows) {
        lastAnyIndex[row.group] = index;
        lastAnyRow[row.group] = row;
        if (row.prize == 1) {
          lastHeadIndex[row.group] = index;
          lastHeadRow[row.group] = row;
        }
      }
    }

    final total = complete.length;
    return gphAnimals.map((animal) {
      final anyIndex = lastAnyIndex[animal.group] ?? -1;
      final headIndex = lastHeadIndex[animal.group] ?? -1;
      return AnimalDelayEntry(
        group: animal.group,
        animal: animal.name,
        completeDraws: total,
        delayAny: total - 1 - anyIndex,
        delayHead: total - 1 - headIndex,
        lastAny: lastAnyRow[animal.group],
        lastHead: lastHeadRow[animal.group],
      );
    }).toList(growable: false);
  }
}
