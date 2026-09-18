import 'package:flutter_test/flutter_test.dart';
import 'package:gph_consulta_android/models/history_result.dart';
import 'package:gph_consulta_android/services/delay_calculator.dart';

void main() {
  test('cabeça ignora reaparições do bicho no 2º ao 5º prêmio', () {
    final rows = <HistoryResult>[];

    // Garante que todos os 25 grupos já tenham aparecido na cabeça ao menos uma vez.
    for (var draw = 1; draw <= 25; draw++) {
      rows.addAll(_drawRows(draw, headGroup: draw, secondGroup: draw == 25 ? 24 : draw + 1));
    }

    // O grupo 1 reaparece fora da cabeça; isso zera/renova apenas o atraso geral.
    rows.addAll(_drawRows(26, headGroup: 2, secondGroup: 1));
    rows.addAll(_drawRows(27, headGroup: 3, secondGroup: 1));

    final result = DelayCalculator.calculate(rows);

    expect(result.totalDraws, 27);
    expect(result.animalHead?.value, 'Avestruz');
    expect(result.animalHead?.delay, 26);
    expect(result.animalHead?.last?.prize, 1);
    expect(result.animalAny?.value, isNot('Avestruz'));
  });

  test('centena e dezena usam a última extração completa em que apareceram', () {
    final rows = <HistoryResult>[
      ..._customDraw('2026-09-10', '09:00', 'PPT', ['0101', '0202', '0303', '0404', '0505']),
      ..._customDraw('2026-09-10', '11:00', 'PTM', ['1111', '1212', '1313', '1414', '1515']),
      ..._customDraw('2026-09-10', '14:00', 'PT', ['2101', '2222', '2323', '2424', '2525']),
    ];

    final result = DelayCalculator.calculate(rows);

    // 02 apareceu só na primeira extração; 01 reapareceu na terceira.
    expect(result.ten?.value, '02');
    expect(result.ten?.delay, 2);
    expect(result.hundred?.delay, 2);
  });
}

List<HistoryResult> _drawRows(int draw, {required int headGroup, required int secondGroup}) {
  final date = '2026-09-${draw.toString().padLeft(2, '0')}';
  final groups = [headGroup, secondGroup, 4, 5, 6];
  return List.generate(5, (index) {
    final group = groups[index];
    final ten = _firstDozen(group);
    final thousand = '${draw % 10}${index + 1}${ten.toString().padLeft(2, '0')}';
    return HistoryResult(
      date: date,
      draw: 'T$draw',
      time: '09:00',
      prize: index + 1,
      thousand: thousand.substring(thousand.length - 4),
      hundred: thousand.substring(thousand.length - 3),
      ten: ten.toString().padLeft(2, '0'),
      group: group,
      animal: 'G$group',
    );
  });
}

List<HistoryResult> _customDraw(String date, String time, String draw, List<String> thousands) {
  return List.generate(5, (index) {
    final thousand = thousands[index].padLeft(4, '0');
    final ten = thousand.substring(2);
    final dozen = int.parse(ten);
    final group = (((dozen - 1) % 100) ~/ 4) + 1;
    return HistoryResult(
      date: date,
      draw: draw,
      time: time,
      prize: index + 1,
      thousand: thousand,
      hundred: thousand.substring(1),
      ten: ten,
      group: group,
      animal: 'G$group',
    );
  });
}

int _firstDozen(int group) => group == 25 ? 97 : ((group - 1) * 4) + 1;
