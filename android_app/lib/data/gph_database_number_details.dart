import '../models/history_result.dart';
import '../models/number_overview.dart';
import 'gph_database.dart';

extension GphDatabaseNumberDetails on GphDatabase {
  Future<Map<String, Object?>> numberAggregate({
    required String mode,
    required String query,
  }) async {
    final db = await database;
    final filter = _numberFilter(mode, query);
    final rows = await db.rawQuery(
      '''
      SELECT
        COUNT(*) AS total,
        SUM(CASE WHEN premio = 1 THEN 1 ELSE 0 END) AS cabecas
      FROM resultados
      WHERE ${filter.field} = ? AND premio BETWEEN 1 AND 5
      ''',
      [filter.value],
    );
    return rows.first;
  }

  Future<List<HistoryResult>> latestForNumber({
    required String mode,
    required String query,
    int? prize,
    int limit = 12,
  }) async {
    final db = await database;
    final filter = _numberFilter(mode, query);
    final clauses = <String>[
      '${filter.field} = ?',
      'premio BETWEEN 1 AND 5',
    ];
    final args = <Object?>[filter.value];
    if (prize != null) {
      clauses.add('premio = ?');
      args.add(prize);
    }

    final rows = await db.query(
      'resultados',
      where: clauses.join(' AND '),
      whereArgs: args,
      orderBy: 'data DESC, hora DESC, sorteio DESC, premio ASC',
      limit: limit,
    );
    return rows.map(HistoryResult.fromMap).toList(growable: false);
  }
}

({String field, String value}) _numberFilter(String mode, String query) {
  final value = normalizeNumberValue(mode, query);
  switch (mode) {
    case 'Dezena':
      return (field: 'dezena', value: value);
    case 'Centena':
      return (field: 'centena', value: value);
    case 'Milhar':
      return (field: 'milhar', value: value);
    default:
      throw ArgumentError.value(mode, 'mode', 'Tipo numérico inválido.');
  }
}
