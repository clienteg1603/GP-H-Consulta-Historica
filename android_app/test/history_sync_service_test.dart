import 'package:flutter_test/flutter_test.dart';
import 'package:gph_consulta_android/services/history_sync_service.dart';

void main() {
  test('parser reproduz o contrato da Consulta Windows', () {
    const html = '''
      <html><body>
        <h2>Resultado PPT das 09:00</h2>
        <p>1º = 5215 – 4 BORBOLETA</p>
        <p>2º = 8690 – 23 URSO</p>
        <p>3º = 4591 – 23 URSO</p>
        <p>4º = 0054 – 14 GATO</p>
        <p>5º = 2425 – 7 CARNEIRO</p>
        <h2>Resultado CORUJINHA das 21:00</h2>
        <p>1º = 0099 - 25 VACA</p>
      </body></html>
    ''';

    final rows = HistorySyncService.parseDailyHtml(
      html,
      DateTime(2026, 9, 18),
      'fixture',
    );

    expect(rows, hasLength(6));
    expect(rows.first.draw, 'PPT');
    expect(rows.first.time, '09:00');
    expect(rows.first.thousand, '5215');
    expect(rows.first.hundred, '215');
    expect(rows.first.ten, '15');
    expect(rows.first.group, 4);
    expect(rows.first.animal, 'BORBOLETA');
    expect(rows.first.publishedGroup, 4);
    expect(rows.first.publishedAnimal, 'BORBOLETA');
    expect(rows.last.draw, 'CORUJA');
    expect(rows.last.group, 25);
    expect(rows.last.animal, 'VACA');
  });

  test('dezena 00 pertence ao grupo 25', () {
    const html = '<h2>PT das 14:00</h2><p>1º 0100 - 25 VACA</p>';
    final rows = HistorySyncService.parseDailyHtml(
      html,
      DateTime(2026, 9, 18),
      'fixture',
    );
    expect(rows.single.ten, '00');
    expect(rows.single.group, 25);
    expect(rows.single.animal, 'VACA');
  });
}
