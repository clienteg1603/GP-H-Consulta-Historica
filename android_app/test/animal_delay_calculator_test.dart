import 'package:flutter_test/flutter_test.dart';
import 'package:gph_consulta_android/models/history_result.dart';
import 'package:gph_consulta_android/services/animal_delay_calculator.dart';

void main() {
  test('atrasos usam apenas extrações completas e separam cabeça do 1º–5º', () {
    final rows = <HistoryResult>[
      ..._draw('2026-09-01', '09:00', [1, 2, 3, 4, 5]),
      ..._draw('2026-09-01', '11:00', [2, 6, 7, 8, 9]),
      ..._draw('2026-09-01', '14:00', [3, 10, 11, 12, 13]),
      _row('2026-09-01', '16:00', 1, 1),
      _row('2026-09-01', '16:00', 2, 1),
    ];

    final result = AnimalDelayCalculator.calculate(rows);
    final g1 = result.firstWhere((item) => item.group == 1);
    final g2 = result.firstWhere((item) => item.group == 2);
    final g3 = result.firstWhere((item) => item.group == 3);
    final g25 = result.firstWhere((item) => item.group == 25);

    expect(g1.completeDraws, 3);
    expect(g1.delayAny, 2);
    expect(g1.delayHead, 2);
    expect(g2.delayAny, 1);
    expect(g2.delayHead, 1);
    expect(g3.delayAny, 0);
    expect(g3.delayHead, 0);
    expect(g25.delayAny, 3);
    expect(g25.delayHead, 3);
    expect(g25.lastAny, isNull);
    expect(g25.lastHead, isNull);
  });
}

List<HistoryResult> _draw(String date, String time, List<int> groups) {
  return List.generate(
    5,
    (index) => _row(date, time, index + 1, groups[index]),
  );
}

HistoryResult _row(String date, String time, int prize, int group) {
  final ten = (((group - 1) * 4) + 1).toString().padLeft(2, '0');
  return HistoryResult(
    date: date,
    draw: 'TESTE',
    time: time,
    prize: prize,
    thousand: '12$ten',
    hundred: '2$ten',
    ten: ten,
    group: group,
    animal: 'Grupo $group',
  );
}
