import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/history_result.dart';

class GphDatabase {
  GphDatabase._();

  static final GphDatabase instance = GphDatabase._();

  Database? _database;
  Future<Database>? _opening;

  Future<Database> get database async {
    final current = _database;
    if (current != null) return current;

    final opening = _opening;
    if (opening != null) return opening;

    final future = _openDatabase();
    _opening = future;
    try {
      final db = await future;
      _database = db;
      return db;
    } finally {
      _opening = null;
    }
  }

  Future<Database> _openDatabase() async {
    final root = await getDatabasesPath();
    final path = p.join(root, 'gph_historico_android.db');
    return openDatabase(
      path,
      version: 1,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE resultados (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            data TEXT NOT NULL,
            dia_semana TEXT,
            sorteio TEXT NOT NULL,
            hora TEXT NOT NULL,
            premio INTEGER NOT NULL,
            milhar TEXT NOT NULL,
            centena TEXT NOT NULL,
            dezena TEXT NOT NULL,
            grupo INTEGER NOT NULL,
            bicho TEXT NOT NULL,
            fonte TEXT,
            grupo_publicado INTEGER,
            bicho_publicado TEXT,
            criado_em TEXT DEFAULT CURRENT_TIMESTAMP,
            atualizado_em TEXT DEFAULT CURRENT_TIMESTAMP,
            UNIQUE(data, sorteio, hora, premio)
          )
        ''');
        await db.execute('CREATE INDEX idx_resultados_data ON resultados(data)');
        await db.execute('CREATE INDEX idx_resultados_grupo ON resultados(grupo)');
        await db.execute('CREATE INDEX idx_resultados_milhar ON resultados(milhar)');
        await db.execute('CREATE INDEX idx_resultados_dezena ON resultados(dezena)');
        await db.execute('''
          CREATE TABLE sync_state (
            chave TEXT PRIMARY KEY,
            valor TEXT,
            atualizado_em TEXT DEFAULT CURRENT_TIMESTAMP
          )
        ''');
      },
    );
  }

  Future<int> countResults() async {
    final db = await database;
    final rows = await db.rawQuery('SELECT COUNT(*) AS total FROM resultados');
    return Sqflite.firstIntValue(rows) ?? 0;
  }

  Future<String?> firstDate() async {
    final db = await database;
    final rows = await db.rawQuery('SELECT MIN(data) AS value FROM resultados');
    return rows.first['value'] as String?;
  }

  Future<String?> lastDate() async {
    final db = await database;
    final rows = await db.rawQuery('SELECT MAX(data) AS value FROM resultados');
    return rows.first['value'] as String?;
  }

  Future<int> upsertResults(Iterable<HistoryResult> results) async {
    final list = results.toList(growable: false);
    if (list.isEmpty) return 0;
    final db = await database;
    var changed = 0;
    await db.transaction((txn) async {
      for (final row in list) {
        final values = row.toMap();
        values['atualizado_em'] = DateTime.now().toIso8601String();
        final id = await txn.insert(
          'resultados',
          values,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        if (id > 0) changed++;
      }
    });
    return changed;
  }

  Future<List<HistoryResult>> resultsForDate(String isoDate) async {
    final db = await database;
    final rows = await db.query(
      'resultados',
      where: 'data = ?',
      whereArgs: [isoDate],
      orderBy: 'hora ASC, sorteio ASC, premio ASC',
    );
    return rows.map(HistoryResult.fromMap).toList(growable: false);
  }

  Future<List<HistoryResult>> latest({int limit = 25}) async {
    final db = await database;
    final rows = await db.query(
      'resultados',
      orderBy: 'data DESC, hora DESC, sorteio DESC, premio ASC',
      limit: limit,
    );
    return rows.map(HistoryResult.fromMap).toList(growable: false);
  }

  Future<List<HistoryResult>> resultsForDelayAnalysis() async {
    final db = await database;
    final rows = await db.query(
      'resultados',
      where: 'premio BETWEEN 1 AND 5',
      orderBy: 'data ASC, hora ASC, sorteio ASC, premio ASC',
    );
    return rows.map(HistoryResult.fromMap).toList(growable: false);
  }

  Future<List<HistoryResult>> search({
    required String mode,
    required String query,
    String? startDate,
    String? endDate,
    int limit = 250,
  }) async {
    final db = await database;
    final normalized = query.trim();
    if (normalized.isEmpty) return const [];

    String field;
    Object value;
    switch (mode) {
      case 'Grupo':
        field = 'grupo';
        value = int.tryParse(normalized) ?? -1;
        break;
      case 'Dezena':
        field = 'dezena';
        value = normalized.padLeft(2, '0');
        break;
      case 'Centena':
        field = 'centena';
        value = normalized.padLeft(3, '0');
        break;
      case 'Milhar':
        field = 'milhar';
        value = normalized.padLeft(4, '0');
        break;
      default:
        field = 'LOWER(bicho)';
        value = normalized.toLowerCase();
    }

    final clauses = <String>['$field = ?'];
    final args = <Object?>[value];
    if (startDate != null) {
      clauses.add('data >= ?');
      args.add(startDate);
    }
    if (endDate != null) {
      clauses.add('data <= ?');
      args.add(endDate);
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

  Future<String?> getSyncValue(String key) async {
    final db = await database;
    final rows = await db.query(
      'sync_state',
      columns: ['valor'],
      where: 'chave = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['valor'] as String?;
  }

  Future<void> setSyncValue(String key, String? value) async {
    final db = await database;
    await db.insert(
      'sync_state',
      {
        'chave': key,
        'valor': value,
        'atualizado_em': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
