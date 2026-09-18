import 'package:flutter_test/flutter_test.dart';
import 'package:gph_consulta_android/models/number_overview.dart';

void main() {
  group('normalizeNumberValue', () {
    test('preserva zeros à esquerda conforme o tipo', () {
      expect(normalizeNumberValue('Dezena', '7'), '07');
      expect(normalizeNumberValue('Centena', '17'), '017');
      expect(normalizeNumberValue('Milhar', '17'), '0017');
    });

    test('mantém somente a largura correspondente', () {
      expect(normalizeNumberValue('Dezena', '317'), '17');
      expect(normalizeNumberValue('Centena', '4317'), '317');
      expect(normalizeNumberValue('Milhar', '94317'), '4317');
    });
  });

  group('groupForNumberValue', () {
    test('deriva grupo pelas duas últimas dezenas', () {
      expect(groupForNumberValue('0001'), 1);
      expect(groupForNumberValue('0017'), 5);
      expect(groupForNumberValue('0097'), 25);
    });

    test('dezena 00 pertence ao grupo 25', () {
      expect(groupForNumberValue('00'), 25);
      expect(groupForNumberValue('1200'), 25);
    });
  });
}
