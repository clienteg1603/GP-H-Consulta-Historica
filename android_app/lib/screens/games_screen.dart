import 'package:flutter/material.dart';

import '../app_services.dart';
import '../models/history_result.dart';
import '../services/history_sync_service.dart';
import '../theme/animal_artwork.dart';
import '../theme/gph_theme.dart';

class GamesScreen extends StatefulWidget {
  const GamesScreen({super.key});

  @override
  State<GamesScreen> createState() => _GamesScreenState();
}

class _GamesScreenState extends State<GamesScreen> {
  DateTime _date = DateTime.now();
  late Future<List<HistoryResult>> _results;
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _results = AppServices.history.forDate(_date);
  }

  void _changeDate(DateTime value) {
    final now = DateTime.now();
    final normalized = DateTime(value.year, value.month, value.day);
    final today = DateTime(now.year, now.month, now.day);
    if (normalized.isAfter(today)) return;
    setState(() {
      _date = normalized;
      _reload();
    });
  }

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2026, 1, 2),
      lastDate: DateTime.now(),
    );
    if (selected != null) _changeDate(selected);
  }

  Future<void> _syncAndReload() async {
    if (_syncing) return;
    setState(() => _syncing = true);
    try {
      final result = await AppServices.sync.sync();
      if (!mounted) return;
      setState(_reload);
      final message = result.errors.isEmpty
          ? 'Resultados atualizados. ${result.saved} prêmios processados.'
          : 'Atualização concluída com ${result.errors.length} página(s) com erro.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } on SyncException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível atualizar os resultados agora.')),
      );
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  bool get _isToday {
    final now = DateTime.now();
    return _date.year == now.year && _date.month == now.month && _date.day == now.day;
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
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF122640), GphTheme.surfaceRaised],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: GphTheme.borderStrong),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: GphTheme.primarySoft,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(
                    Icons.calendar_month_rounded,
                    color: GphTheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isToday ? 'Jogos de hoje' : 'Jogos do dia',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _displayDate(_date),
                        style: const TextStyle(color: GphTheme.textSecondary, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
                IconButton.filledTonal(
                  tooltip: 'Escolher data',
                  onPressed: _pickDate,
                  icon: const Icon(Icons.edit_calendar_rounded, size: 20),
                ),
                const SizedBox(width: 5),
                IconButton.filledTonal(
                  tooltip: 'Atualizar resultados',
                  onPressed: _syncing ? null : _syncAndReload,
                  icon: _syncing
                      ? const SizedBox(
                          width: 19,
                          height: 19,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.sync_rounded, size: 20),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
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
              FilledButton.tonalIcon(
                onPressed: _isToday ? null : () => _changeDate(DateTime.now()),
                icon: const Icon(Icons.today_rounded, size: 17),
                label: const Text('Hoje'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isToday
                      ? null
                      : () => _changeDate(_date.add(const Duration(days: 1))),
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
                return _message(
                  _isToday
                      ? 'Ainda não há resultados salvos para hoje. Use o botão de atualizar acima.'
                      : 'Nenhum resultado salvo para esta data.',
                );
              }
              final groups = <String, List<HistoryResult>>{};
              for (final row in rows) {
                final key = '${row.time}|${row.draw}';
                groups.putIfAbsent(key, () => []).add(row);
              }
              final complete = groups.values.where((group) {
                final prizes = group.map((row) => row.prize).toSet();
                return {1, 2, 3, 4, 5}.every(prizes.contains);
              }).length;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DaySummary(
                    draws: groups.length,
                    prizes: rows.length,
                    completeDraws: complete,
                  ),
                  const SizedBox(height: 12),
                  ...groups.values.map(
                    (group) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _DrawCard(rows: group),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _message(String text) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: GphTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: GphTheme.border),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline_rounded, color: GphTheme.textMuted, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(text, style: const TextStyle(color: GphTheme.textSecondary))),
          ],
        ),
      );

  String _displayDate(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
}

class _DaySummary extends StatelessWidget {
  const _DaySummary({
    required this.draws,
    required this.prizes,
    required this.completeDraws,
  });

  final int draws;
  final int prizes;
  final int completeDraws;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: GphTheme.surfaceRaised,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: GphTheme.border),
      ),
      child: Row(
        children: [
          _SummaryValue(value: '$draws', label: 'extrações'),
          const _SummaryDivider(),
          _SummaryValue(value: '$prizes', label: 'prêmios'),
          const _SummaryDivider(),
          _SummaryValue(value: '$completeDraws', label: 'completas'),
        ],
      ),
    );
  }
}

class _SummaryValue extends StatelessWidget {
  const _SummaryValue({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          Text(label, style: const TextStyle(color: GphTheme.textMuted, fontSize: 10)),
        ],
      ),
    );
  }
}

class _SummaryDivider extends StatelessWidget {
  const _SummaryDivider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 30, color: GphTheme.border);
  }
}

class _DrawCard extends StatelessWidget {
  const _DrawCard({required this.rows});

  final List<HistoryResult> rows;

  @override
  Widget build(BuildContext context) {
    final ordered = [...rows]..sort((a, b) => a.prize.compareTo(b.prize));
    final first = ordered.first;
    final prizes = ordered.map((row) => row.prize).toSet();
    final complete = {1, 2, 3, 4, 5}.every(prizes.contains);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: GphTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: GphTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: GphTheme.primarySoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  first.time,
                  style: const TextStyle(color: GphTheme.primary, fontWeight: FontWeight.w900),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  first.draw,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: complete ? const Color(0xFF123A2A) : const Color(0xFF3B2B15),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(
                  complete ? 'Completa' : '${ordered.length}/5',
                  style: TextStyle(
                    color: complete ? GphTheme.success : GphTheme.warning,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...ordered.map((row) => _PrizeRow(row: row)),
        ],
      ),
    );
  }
}

class _PrizeRow extends StatelessWidget {
  const _PrizeRow({required this.row});

  final HistoryResult row;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showDetails(context),
        child: Container(
          margin: const EdgeInsets.only(bottom: 5),
          padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 7),
          decoration: BoxDecoration(
            color: GphTheme.surfaceRaised,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 30,
                child: Text(
                  '${row.prize}º',
                  style: const TextStyle(color: GphTheme.textMuted, fontWeight: FontWeight.w700),
                ),
              ),
              SizedBox(
                width: 50,
                child: AnimalArtwork(
                  group: row.group,
                  borderRadius: 9,
                  showGlow: false,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      row.thousand,
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      row.animal,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: GphTheme.textSecondary, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                decoration: BoxDecoration(
                  color: GphTheme.primarySoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'G${row.group.toString().padLeft(2, '0')}',
                  style: const TextStyle(color: GphTheme.primary, fontSize: 10, fontWeight: FontWeight.w900),
                ),
              ),
              const SizedBox(width: 2),
              const Icon(Icons.chevron_right_rounded, color: GphTheme.textMuted, size: 19),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showDetails(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 110,
                    child: AnimalArtwork(group: row.group, borderRadius: 14),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          row.animal,
                          style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${row.prize}º prêmio • ${row.draw}',
                          style: const TextStyle(color: GphTheme.textSecondary, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${_date(row.date)} • ${row.time}',
                          style: const TextStyle(color: GphTheme.textMuted, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _DetailLine(label: 'Milhar', value: row.thousand),
              _DetailLine(label: 'Centena', value: row.hundred),
              _DetailLine(label: 'Dezena', value: row.ten),
              _DetailLine(
                label: 'Grupo',
                value: '${row.group.toString().padLeft(2, '0')} • ${row.animal}',
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _date(String iso) {
    final parts = iso.split('-');
    if (parts.length != 3) return iso;
    return '${parts[2]}/${parts[1]}/${parts[0]}';
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 7),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: GphTheme.surface,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 78,
            child: Text(label, style: const TextStyle(color: GphTheme.textMuted)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
