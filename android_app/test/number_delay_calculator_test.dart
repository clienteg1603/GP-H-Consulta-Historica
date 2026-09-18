import 'package:flutter_test/flutter_test.dart';
import 'package:gph_consulta_android/models/history_result.dart';
import 'package:gph_consulta_android/models/number_delay_stats.dart';
import 'package:gph_consulta_android/services/number_delay_calculator.dart';

void main() {
  group('NumberDelayCalculator', () {
    test('calcula atraso por extração completa e preserva zeros à esquerda', () {
      final rows = <HistoryResult>[
        ..._draw('2026-09-01', '09:00', ['010', '011', '012', '013', '014']),
        ..._draw('2026-09-01', '11:00', ['020', '021', '022', '023', '024']),
        ..._draw('2026-09-01', '14:00', ['010', '030', '031', '032', '033']),
      ];

      final tens = NumberDelayCalculator.calculate(rows, mode: NumberDelayMode.ten);
      final hundreds = NumberDelayCalculator.calculate(rows, mode: NumberDelayMode.hundred);

      expect(_find(tens, '11').delay, 2);
      expect(_find(tens, '20').delay, 1);
      expect(_find(tens, '10').delay, 0);
      expect(_find(tens, '99').delay, 3);
      expect(_find(hundreds, '011').delay, 2);
      expect(_find(hundreds, '010').delay, 0);
      expect(_find(hundreds, '005').value, '005');
    });

    test('ignora extração incompleta', () {
      final rows = <HistoryResult>[
        ..._draw('2026-09-01', '09:00', ['010', '011', '012', '013', '014']),
        ..._draw('2026-09-01', '11:00', ['020', '021', '022', '023']),
      ];

      final tens = NumberDelayCalculator.calculate(rows, mode: NumberDelayMode.ten);

      expect(_find(tens, '10').completeDraws, 1);
      expect(_find(tens, '10').delay, 0);
      expect(_find(tens, '20').delay, 1);
    });

    test('ordena por maior atraso e depois menor número', () {
      final rows = _draw('2026-09-01', '09:00', ['010', '011', '012', '013', '014']);
      final tens = NumberDelayCalculator.calculate(rows, mode: NumberDelayMode.ten);

      expect(tens.first.value, '00');
      expect(tens.first.delay, 1);
      expect(tens[1].value, '01');
    });
  });
}

List<HistoryResult> _draw(String date, String time, List<String> hundreds) {
  return List<HistoryResult>.generate(hundreds.length, (index) {
    final hundred = hundreds[index].padLeft(3, '0');
    final ten = hundred.substring(hundred.length - 2);
    return HistoryResult(
      date: date,
      draw: 'PT',
      time: time,
      prize: index + 1,
      thousand: '1$hundred',
      hundred: hundred,
      ten: ten,
      group: 1,
      animal: 'AVESTRUZ',
    );
  });
}

NumberDelayEntry _find(List<NumberDelayEntry> rows, String value) {
  return rows.firstWhere((item) => item.value == value);
}
