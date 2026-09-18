import 'package:flutter_test/flutter_test.dart';
import 'package:gph_consulta_android/models/history_result.dart';
import 'package:gph_consulta_android/models/strong_number_stats.dart';
import 'package:gph_consulta_android/services/strong_number_calculator.dart';

void main() {
  test('ranking prioriza frequência, depois recência e depois menor número', () {
    final rows = <HistoryResult>[
      _row('2026-09-01', '09:00', 1, '1217'),
      _row('2026-09-01', '11:00', 2, '3417'),
      _row('2026-09-01', '14:00', 3, '5618'),
      _row('2026-09-01', '16:00', 4, '7818'),
      _row('2026-09-01', '18:00', 1, '9019'),
      _row('2026-09-01', '18:00', 1, '9020'),
    ];

    final ranking = StrongNumberCalculator.calculate(
      rows,
      StrongNumberKind.dozen,
    );

    expect(ranking[0].value, '18');
    expect(ranking[0].count, 2);
    expect(ranking[1].value, '17');
    expect(ranking[1].count, 2);
    expect(ranking[2].value, '19');
    expect(ranking[3].value, '20');
  });

  test('centena e milhar preservam zeros à esquerda', () {
    final rows = <HistoryResult>[
      _row('2026-09-02', '09:00', 1, '0017'),
    ];

    final hundreds = StrongNumberCalculator.calculate(
      rows,
      StrongNumberKind.hundred,
    );
    final thousands = StrongNumberCalculator.calculate(
      rows,
      StrongNumberKind.thousand,
    );

    expect(hundreds.single.value, '017');
    expect(thousands.single.value, '0017');
  });
}

HistoryResult _row(
  String date,
  String time,
  int prize,
  String thousand,
) {
  final normalized = thousand.padLeft(4, '0');
  final ten = normalized.substring(2);
  final dozen = int.parse(ten);
  final group = (((dozen - 1) % 100) ~/ 4) + 1;
  return HistoryResult(
    date: date,
    draw: 'TESTE',
    time: time,
    prize: prize,
    thousand: normalized,
    hundred: normalized.substring(1),
    ten: ten,
    group: group,
    animal: 'Grupo $group',
  );
}
