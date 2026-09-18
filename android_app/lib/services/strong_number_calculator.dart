import '../models/history_result.dart';
import '../models/strong_number_stats.dart';

class StrongNumberCalculator {
  const StrongNumberCalculator._();

  static List<StrongNumberEntry> calculate(
    List<HistoryResult> rows,
    StrongNumberKind kind,
  ) {
    if (rows.isEmpty) return const [];

    final buckets = <String, _Bucket>{};
    for (final row in rows) {
      if (row.prize < 1 || row.prize > 5) continue;
      final value = _valueFor(row, kind).padLeft(kind.width, '0');
      final bucket = buckets.putIfAbsent(value, _Bucket.new);
      bucket.count++;
      if (bucket.last == null || _isLater(row, bucket.last!)) {
        bucket.last = row;
      }
    }

    final result = buckets.entries.map((entry) {
      final last = entry.value.last!;
      return StrongNumberEntry(
        value: entry.key,
        count: entry.value.count,
        lastDate: last.date,
        lastTime: last.time,
        lastDraw: last.draw,
        lastPrize: last.prize,
      );
    }).toList();

    result.sort((a, b) {
      final byCount = b.count.compareTo(a.count);
      if (byCount != 0) return byCount;
      final byDate = b.lastDate.compareTo(a.lastDate);
      if (byDate != 0) return byDate;
      final byTime = b.lastTime.compareTo(a.lastTime);
      if (byTime != 0) return byTime;
      final av = int.tryParse(a.value) ?? 0;
      final bv = int.tryParse(b.value) ?? 0;
      return av.compareTo(bv);
    });

    return result;
  }

  static String _valueFor(HistoryResult row, StrongNumberKind kind) {
    switch (kind) {
      case StrongNumberKind.dozen:
        return row.ten;
      case StrongNumberKind.hundred:
        return row.hundred;
      case StrongNumberKind.thousand:
        return row.thousand;
    }
  }

  static bool _isLater(HistoryResult candidate, HistoryResult current) {
    final candidateKey =
        '${candidate.date}|${candidate.time}|${candidate.draw}|${candidate.prize.toString().padLeft(2, '0')}';
    final currentKey =
        '${current.date}|${current.time}|${current.draw}|${current.prize.toString().padLeft(2, '0')}';
    return candidateKey.compareTo(currentKey) > 0;
  }
}

class _Bucket {
  int count = 0;
  HistoryResult? last;
}
