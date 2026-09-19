import 'dart:async';

import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;

import '../data/animals.dart';
import '../data/history_repository.dart';
import '../models/history_result.dart';

class SyncProgress {
  const SyncProgress({
    required this.day,
    required this.current,
    required this.total,
    required this.saved,
    required this.initialLoad,
  });

  final DateTime day;
  final int current;
  final int total;
  final int saved;
  final bool initialLoad;
}

class SyncResult {
  const SyncResult({
    required this.start,
    required this.end,
    required this.saved,
    required this.pagesWithoutResults,
    required this.errors,
    required this.initialLoad,
  });

  final DateTime start;
  final DateTime end;
  final int saved;
  final int pagesWithoutResults;
  final List<String> errors;
  final bool initialLoad;
}

class HistorySyncService {
  HistorySyncService({required HistoryRepository repository, http.Client? client})
      : _repository = repository,
        _client = client ?? http.Client();

  static final DateTime firstHistoryDate = DateTime(2026, 1, 2);
  static const String _baseUrl =
      'https://brasildeunoposte.com.br/resultado-do-jogo-do-bicho-deu-no-poste-{date}/';

  final HistoryRepository _repository;
  final http.Client _client;

  Future<SyncResult> sync({
    void Function(SyncProgress progress)? onProgress,
    int recentLookbackDays = 7,
  }) async {
    final summary = await _repository.summary();
    final today = _dateOnly(DateTime.now());
    final firstLoad = summary.isEmpty ||
        summary.firstDate == null ||
        DateTime.parse(summary.firstDate!).isAfter(firstHistoryDate);

    DateTime start;
    if (firstLoad) {
      final resume = await _repository.syncCursor();
      final resumeDate = resume == null ? null : DateTime.tryParse(resume);
      if (resumeDate != null && !resumeDate.isBefore(firstHistoryDate)) {
        start = _dateOnly(resumeDate);
      } else if (summary.lastDate != null) {
        start = _dateOnly(DateTime.parse(summary.lastDate!).add(const Duration(days: 1)));
        if (start.isBefore(firstHistoryDate)) start = firstHistoryDate;
      } else {
        start = firstHistoryDate;
      }
    } else {
      final last = summary.lastDate == null ? today : DateTime.parse(summary.lastDate!);
      final lookback = recentLookbackDays < 0 ? 0 : recentLookbackDays;
      start = _dateOnly(last.subtract(Duration(days: lookback)));
      if (start.isBefore(firstHistoryDate)) start = firstHistoryDate;
    }

    if (start.isAfter(today)) start = today;
    final total = today.difference(start).inDays + 1;
    var saved = 0;
    var noResults = 0;
    final errors = <String>[];

    for (var index = 0; index < total; index++) {
      final day = start.add(Duration(days: index));
      try {
        final rows = await fetchDay(day);
        if (rows.isNotEmpty) {
          saved += await _repository.save(rows);
        } else {
          noResults++;
        }
        if (firstLoad) {
          await _repository.saveSyncCursor(_isoDate(day.add(const Duration(days: 1))));
        }
      } on _PageNotFound {
        noResults++;
        if (firstLoad) {
          await _repository.saveSyncCursor(_isoDate(day.add(const Duration(days: 1))));
        }
      } catch (error) {
        errors.add('${_displayDate(day)}: $error');
        if (firstLoad) {
          throw SyncException(
            'Sincronização pausada em ${_displayDate(day)}. O que já foi salvo foi mantido.',
            cause: error,
            partialSaved: saved,
          );
        }
      }

      onProgress?.call(SyncProgress(
        day: day,
        current: index + 1,
        total: total,
        saved: saved,
        initialLoad: firstLoad,
      ));
    }

    if (firstLoad) await _repository.saveSyncCursor(null);
    await _repository.saveLastSync(DateTime.now());

    return SyncResult(
      start: start,
      end: today,
      saved: saved,
      pagesWithoutResults: noResults,
      errors: errors,
      initialLoad: firstLoad,
    );
  }

  Future<List<HistoryResult>> fetchDay(DateTime day) async {
    final datePart =
        '${day.day.toString().padLeft(2, '0')}-${day.month.toString().padLeft(2, '0')}-${day.year.toString().padLeft(4, '0')}';
    final url = _baseUrl.replaceFirst('{date}', datePart);
    final uri = Uri.parse(url);

    final response = await _client
        .get(
          uri,
          headers: const {
            'User-Agent':
                'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 GPH-Consulta-Android/0.1.0',
            'Accept-Language': 'pt-BR,pt;q=0.9',
          },
        )
        .timeout(const Duration(seconds: 18));

    if (response.statusCode == 404) throw const _PageNotFound();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw SyncException('HTTP ${response.statusCode} ao consultar a fonte.');
    }

    return parseDailyHtml(response.body, day, url);
  }

  static List<HistoryResult> parseDailyHtml(String rawHtml, DateTime day, String source) {
    final document = html_parser.parse(rawHtml);
    final lines = <String>[];

    void visit(Node node) {
      if (node is Text) {
        for (final raw in node.data.split(RegExp(r'[\r\n]+'))) {
          final line = raw.replaceAll(RegExp(r'\s+'), ' ').trim();
          if (line.isNotEmpty) lines.add(line);
        }
      }
      for (final child in node.nodes) {
        visit(child);
      }
    }

    visit(document);

    final heading = RegExp(
      r'\b(PPT|PTM|PTV|PTN|PT|FEDERAL|CORUJA|CORUJINHA)\b.*?\bdas?\s+(\d{1,2}:\d{2})',
      caseSensitive: false,
      unicode: true,
    );
    final prize = RegExp(
      r'^\s*([1-5])\s*[°ºoª]?\s*=?\s*(\d{1,4})\s*[–—-]\s*(\d{1,2})\s+(.+?)\s*$',
      caseSensitive: false,
      unicode: true,
    );

    String? currentDraw;
    String? currentTime;
    final rows = <HistoryResult>[];

    for (final line in lines) {
      final headingMatch = heading.firstMatch(line);
      if (headingMatch != null) {
        final rawDraw = headingMatch.group(1)!.toUpperCase();
        currentDraw = rawDraw == 'CORUJINHA' ? 'CORUJA' : rawDraw;
        currentTime = _normalizeTime(headingMatch.group(2)!);
        continue;
      }

      final match = prize.firstMatch(line);
      if (match == null || currentDraw == null || currentTime == null) continue;

      final prizeNumber = int.parse(match.group(1)!);
      final publishedGroup = int.tryParse(match.group(3)!);
      final publishedAnimal = match.group(4)!.trim();
      final derived = _derive(match.group(2)!);
      rows.add(HistoryResult(
        date: _isoDate(day),
        weekday: _weekday(day),
        draw: currentDraw,
        time: currentTime,
        prize: prizeNumber,
        thousand: derived.thousand,
        hundred: derived.hundred,
        ten: derived.ten,
        group: derived.group,
        animal: derived.animal,
        source: source,
        publishedGroup: publishedGroup,
        publishedAnimal: publishedAnimal,
      ));
    }

    return rows;
  }

  static _Derived _derive(String rawThousand) {
    final digitsOnly = rawThousand.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.isEmpty) throw const FormatException('Milhar vazia.');
    final four = digitsOnly.length > 4
        ? digitsOnly.substring(digitsOnly.length - 4)
        : digitsOnly.padLeft(4, '0');
    final hundred = four.substring(1);
    final ten = four.substring(2);
    final dozen = int.parse(ten);
    final group = (((dozen - 1) % 100) ~/ 4) + 1;
    final animal = gphAnimals[group - 1].name.toUpperCase();
    return _Derived(four, hundred, ten, group, animal);
  }

  static String _normalizeTime(String value) {
    final parts = value.split(':');
    if (parts.length != 2) return value;
    return '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}';
  }

  static String _weekday(DateTime value) {
    const names = <String>[
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return names[value.weekday - 1];
  }

  static DateTime _dateOnly(DateTime value) => DateTime(value.year, value.month, value.day);

  static String _isoDate(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

  static String _displayDate(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
}

class SyncException implements Exception {
  const SyncException(this.message, {this.cause, this.partialSaved = 0});

  final String message;
  final Object? cause;
  final int partialSaved;

  @override
  String toString() => message;
}

class _Derived {
  const _Derived(this.thousand, this.hundred, this.ten, this.group, this.animal);

  final String thousand;
  final String hundred;
  final String ten;
  final int group;
  final String animal;
}

class _PageNotFound implements Exception {
  const _PageNotFound();
}
