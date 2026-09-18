import '../data/animals.dart';
import '../models/delay_summary.dart';
import '../models/history_result.dart';

class DelayCalculator {
  const DelayCalculator._();

  static DelaySummary calculate(List<HistoryResult> sourceRows) {
    if (sourceRows.isEmpty) {
      return const DelaySummary(totalDraws: 0);
    }

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

    if (complete.isEmpty) {
      return const DelaySummary(totalDraws: 0);
    }

    final groupLastSeen = <int, int>{for (var group = 1; group <= 25; group++) group: -1};
    final groupLastRow = <int, HistoryResult>{};
    final headLastSeen = <int, int>{for (var group = 1; group <= 25; group++) group: -1};
    final headLastRow = <int, HistoryResult>{};
    final hundredLastSeen = <String, int>{};
    final hundredLastRow = <String, HistoryResult>{};
    final tenLastSeen = <String, int>{};
    final tenLastRow = <String, HistoryResult>{};

    for (var index = 0; index < complete.length; index++) {
      final drawRows = complete[index];
      for (final row in drawRows) {
        groupLastSeen[row.group] = index;
        groupLastRow[row.group] = row;

        final hundred = row.hundred.padLeft(3, '0');
        hundredLastSeen[hundred] = index;
        hundredLastRow[hundred] = row;

        final ten = row.ten.padLeft(2, '0');
        tenLastSeen[ten] = index;
        tenLastRow[ten] = row;

        if (row.prize == 1) {
          headLastSeen[row.group] = index;
          headLastRow[row.group] = row;
        }
      }
    }

    final total = complete.length;
    return DelaySummary(
      totalDraws: total,
      animalAny: _groupLeader(total, groupLastSeen, groupLastRow),
      animalHead: _groupLeader(total, headLastSeen, headLastRow),
      hundred: _textLeader(total, hundredLastSeen, hundredLastRow),
      ten: _textLeader(total, tenLastSeen, tenLastRow),
    );
  }

  static DelayLeader? _groupLeader(
    int total,
    Map<int, int> lastSeen,
    Map<int, HistoryResult> lastRows,
  ) {
    if (lastSeen.isEmpty) return null;
    final delays = <int, int>{
      for (final entry in lastSeen.entries) entry.key: total - 1 - entry.value,
    };
    final maxDelay = delays.values.reduce((a, b) => a > b ? a : b);
    final tiedGroups = delays.entries
        .where((entry) => entry.value == maxDelay)
        .map((entry) => entry.key)
        .toList()
      ..sort();
    final leader = tiedGroups.first;
    final ties = tiedGroups.map(_animalName).toList(growable: false);
    return DelayLeader(
      value: _animalName(leader),
      delay: maxDelay,
      tieCount: ties.length,
      ties: ties,
      last: lastRows[leader],
    );
  }

  static DelayLeader? _textLeader(
    int total,
    Map<String, int> lastSeen,
    Map<String, HistoryResult> lastRows,
  ) {
    if (lastSeen.isEmpty) return null;
    final delays = <String, int>{
      for (final entry in lastSeen.entries) entry.key: total - 1 - entry.value,
    };
    final maxDelay = delays.values.reduce((a, b) => a > b ? a : b);
    final ties = delays.entries
        .where((entry) => entry.value == maxDelay)
        .map((entry) => entry.key)
        .toList()
      ..sort((a, b) => (int.tryParse(a) ?? 0).compareTo(int.tryParse(b) ?? 0));
    final leader = ties.first;
    return DelayLeader(
      value: leader,
      delay: maxDelay,
      tieCount: ties.length,
      ties: List.unmodifiable(ties),
      last: lastRows[leader],
    );
  }

  static String _animalName(int group) {
    if (group < 1 || group > gphAnimals.length) return 'Grupo $group';
    return gphAnimals[group - 1].name;
  }
}
