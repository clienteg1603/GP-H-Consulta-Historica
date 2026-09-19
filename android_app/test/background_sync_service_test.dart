import 'package:flutter_test/flutter_test.dart';
import 'package:gph_consulta_android/models/history_result.dart';
import 'package:gph_consulta_android/services/background_sync_service.dart';

HistoryResult result({
  required String date,
  required String time,
  required String draw,
  required int prize,
  String thousand = '1234',
}) {
  return HistoryResult(
    date: date,
    draw: draw,
    time: time,
    prize: prize,
    thousand: thousand,
    hundred: thousand.padLeft(4, '0').substring(1),
    ten: thousand.padLeft(4, '0').substring(2),
    group: 9,
    animal: 'COBRA',
  );
}

void main() {
  test('detecta somente chaves de prêmio que ainda não existiam', () {
    final before = [
      result(date: '2026-09-19', time: '11:00', draw: 'PTM', prize: 1),
    ];
    final after = [
      result(
        date: '2026-09-19',
        time: '11:00',
        draw: 'PTM',
        prize: 1,
        thousand: '9999',
      ),
      result(date: '2026-09-19', time: '11:00', draw: 'PTM', prize: 2),
    ];

    final added = detectNewHistoryRows(before, after);

    expect(added, hasLength(1));
    expect(added.single.prize, 2);
  });

  test('ordena novos resultados por data, hora, sorteio e prêmio', () {
    final after = [
      result(date: '2026-09-19', time: '14:00', draw: 'PT', prize: 2),
      result(date: '2026-09-18', time: '21:00', draw: 'CORUJA', prize: 1),
      result(date: '2026-09-19', time: '14:00', draw: 'PT', prize: 1),
    ];

    final added = detectNewHistoryRows(const [], after);

    expect(added.map((row) => '${row.date}|${row.time}|${row.prize}').toList(), [
      '2026-09-18|21:00|1',
      '2026-09-19|14:00|1',
      '2026-09-19|14:00|2',
    ]);
  });
}
