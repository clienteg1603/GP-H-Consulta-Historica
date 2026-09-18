import 'package:flutter_test/flutter_test.dart';
import 'package:gph_consulta_android/models/frequency_stats.dart';

void main() {
  test('percentual de frequência usa o total do recorte', () {
    const entry = FrequencyEntry(
      group: 14,
      animal: 'GATO',
      count: 25,
      total: 100,
    );

    expect(entry.percentage, 25.0);
  });

  test('percentual é zero quando o recorte está vazio', () {
    const entry = FrequencyEntry(
      group: 1,
      animal: 'AVESTRUZ',
      count: 0,
      total: 0,
    );

    expect(entry.percentage, 0.0);
  });
}
