import 'history_result.dart';

class NumberOverview {
  const NumberOverview({
    required this.mode,
    required this.value,
    required this.group,
    required this.animal,
    required this.totalAppearances,
    required this.firstPrizeAppearances,
    required this.recent,
    this.currentDelay,
    this.completeDraws,
    this.lastAny,
    this.lastFirst,
  });

  final String mode;
  final String value;
  final int group;
  final String animal;
  final int totalAppearances;
  final int firstPrizeAppearances;
  final int? currentDelay;
  final int? completeDraws;
  final HistoryResult? lastAny;
  final HistoryResult? lastFirst;
  final List<HistoryResult> recent;
}

String normalizeNumberValue(String mode, String raw) {
  final digits = raw.replaceAll(RegExp(r'\D'), '');
  switch (mode) {
    case 'Dezena':
      return digits.padLeft(2, '0').substring(digits.padLeft(2, '0').length - 2);
    case 'Centena':
      return digits.padLeft(3, '0').substring(digits.padLeft(3, '0').length - 3);
    case 'Milhar':
      return digits.padLeft(4, '0').substring(digits.padLeft(4, '0').length - 4);
    default:
      return digits;
  }
}

int groupForNumberValue(String value) {
  final digits = value.replaceAll(RegExp(r'\D'), '');
  if (digits.isEmpty) return 0;
  final tail = digits.length <= 2 ? digits : digits.substring(digits.length - 2);
  final ten = int.tryParse(tail) ?? 0;
  if (ten == 0) return 25;
  return ((ten - 1) ~/ 4) + 1;
}
