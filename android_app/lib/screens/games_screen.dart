import 'package:flutter/material.dart';

import '../app_services.dart';
import '../models/history_result.dart';

class GamesScreen extends StatefulWidget {
  const GamesScreen({super.key});

  @override
  State<GamesScreen> createState() => _GamesScreenState();
}

class _GamesScreenState extends State<GamesScreen> {
  DateTime _date = DateTime.now();
  late Future<List<HistoryResult>> _results;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _results = AppServices.history.forDate(_date);
  }

  void _changeDate(DateTime value) {
    setState(() {
      _date = value;
      _reload();
    });
  }

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2026, 1, 2),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (selected != null) _changeDate(selected);
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        setState(_reload);
        await _results;
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0D1726),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFF1C2B41)),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_month_rounded, color: Color(0xFF60A5FA)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Jogos do dia', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 3),
                      Text(_displayDate(_date), style: const TextStyle(color: Color(0xFF9FB0C5))),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Escolher data',
                  onPressed: _pickDate,
                  icon: const Icon(Icons.edit_calendar_rounded),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _changeDate(_date.subtract(const Duration(days: 1))),
                  icon: const Icon(Icons.chevron_left_rounded),
                  label: const Text('Anterior'),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.tonal(
                onPressed: () => _changeDate(DateTime.now()),
                child: const Text('Hoje'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _changeDate(_date.add(const Duration(days: 1))),
                  icon: const Icon(Icons.chevron_right_rounded),
                  label: const Text('Próximo'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FutureBuilder<List<HistoryResult>>(
            future: _results,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(28),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (snapshot.hasError) return _message('Não foi possível consultar a base local.');
              final rows = snapshot.data ?? const <HistoryResult>[];
              if (rows.isEmpty) {
                return _message('Nenhum resultado salvo para esta data. Atualize o histórico na tela Início.');
              }
              final groups = <String, List<HistoryResult>>{};
              for (final row in rows) {
                final key = '${row.time}|${row.draw}';
                groups.putIfAbsent(key, () => []).add(row);
              }
              return Column(
                children: groups.values
                    .map((group) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _DrawCard(rows: group),
                        ))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _message(String text) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF0B1523),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF1C2B41)),
        ),
        child: Text(text, style: const TextStyle(color: Color(0xFF9FB0C5))),
      );

  String _displayDate(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
}

class _DrawCard extends StatelessWidget {
  const _DrawCard({required this.rows});

  final List<HistoryResult> rows;

  @override
  Widget build(BuildContext context) {
    final first = rows.first;
    final ordered = [...rows]..sort((a, b) => a.prize.compareTo(b.prize));
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1523),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1C2B41)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xFF162A46),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(first.time, style: const TextStyle(fontWeight: FontWeight.w900)),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(first.draw, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16))),
            ],
          ),
          const SizedBox(height: 12),
          ...ordered.map(
            (row) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  SizedBox(width: 34, child: Text('${row.prize}º', style: const TextStyle(color: Color(0xFF7F94AD)))),
                  SizedBox(width: 56, child: Text(row.thousand, style: const TextStyle(fontWeight: FontWeight.w900))),
                  Expanded(child: Text(row.animal)),
                  Text('G${row.group.toString().padLeft(2, '0')}', style: const TextStyle(color: Color(0xFF9FB0C5))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
