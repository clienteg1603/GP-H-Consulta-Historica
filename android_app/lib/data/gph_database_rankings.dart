import '../models/history_result.dart';
import 'gph_database.dart';

extension GphDatabaseRankings on GphDatabase {
  Future<List<HistoryResult>> rowsForGroupNumberRanking(
    int group, {
    required bool firstPrizeOnly,
  }) async {
    final db = await database;
    final where = firstPrizeOnly
        ? 'grupo = ? AND premio = 1'
        : 'grupo = ? AND premio BETWEEN 1 AND 5';
    final rows = await db.query(
      'resultados',
      where: where,
      whereArgs: [group],
      orderBy: 'data ASC, hora ASC, sorteio ASC, premio ASC',
    );
    return rows.map(HistoryResult.fromMap).toList(growable: false);
  }
}
