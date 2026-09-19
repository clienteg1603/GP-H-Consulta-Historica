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
          _DayHeader(
            date: _date,
            isToday: _isToday,
            syncing: _syncing,
            onPickDate: _pickDate,
            onSync: _syncAndReload,
          ),
          const SizedBox(height: 12),
          _DayNavigation(
            isToday: _isToday,
            onPrevious: () => _changeDate(_date.subtract(const Duration(days: 1))),
            onToday: () => _changeDate(DateTime.now()),
            onNext: () => _changeDate(_date.add(const Duration(days: 1))),
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
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({
    required this.date,
    required this.isToday,
    required this.syncing,
    required this.onPickDate,
    required this.onSync,
  });

  final DateTime date;
  final bool isToday;
  final bool syncing;
  final VoidCallback onPickDate;
  final VoidCallback onSync;

  @override
  Widget build(BuildContext context) {
    final icon = Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: GphTheme.primarySoft,
        borderRadius: BorderRadius.circular(13),
      ),
      child: const Icon(Icons.calendar_month_rounded, color: GphTheme.primary, size: 24),
    );
    final title = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isToday ? 'Jogos de hoje' : 'Jogos do dia',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 3),
        Text(
          _displayDate(date),
          style: const TextStyle(color: GphTheme.textSecondary, fontWeight: FontWeight.w700),
        ),
      ],
    );
    final actions = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        OutlinedButton.icon(
          onPressed: onPickDate,
          icon: const Icon(Icons.edit_calendar_rounded, size: 18),
          label: const Text('Data'),
        ),
        const SizedBox(width: 7),
        FilledButton.tonalIcon(
          onPressed: syncing ? null : onSync,
          icon: syncing
              ? const SizedBox(
                  width: 17,
                  height: 17,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.sync_rounded, size: 18),
          label: Text(syncing ? 'Atualizando' : 'Atualizar'),
        ),
      ],
    );

    return Container(
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 430) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    icon,
                    const SizedBox(width: 12),
                    Expanded(child: title),
                  ],
                ),
                const SizedBox(height: 13),
                SizedBox(width: double.infinity, child: actions),
              ],
            );
          }
          return Row(
            children: [
              icon,
              const SizedBox(width: 12),
              Expanded(child: title),
              actions,
            ],
          );
        },
      ),
    );
  }
}

class _DayNavigation extends StatelessWidget {
  const _DayNavigation({
    required this.isToday,
    required this.onPrevious,
    required this.onToday,
    required this.onNext,
  });

  final bool isToday;
  final VoidCallback onPrevious;
  final VoidCallback onToday;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onPrevious,
              icon: const Icon(Icons.chevron_left_rounded),
              label: const Text('Anterior', maxLines: 1),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton.tonalIcon(
            onPressed: isToday ? null : onToday,
            icon: const Icon(Icons.today_rounded, size: 17),
            label: const Text('Hoje'),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: isToday ? null : onNext,
              icon: const Icon(Icons.chevron_right_rounded),
              label: const Text('Próximo', maxLines: 1),
            ),
          ),
        ],
      );
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final cards = [
          _SummaryValue(value: '$draws', label: 'extrações', icon: Icons.schedule_rounded),
          _SummaryValue(value: '$prizes', label: 'prêmios', icon: Icons.receipt_long_rounded),
          _SummaryValue(value: '$completeDraws', label: 'completas', icon: Icons.fact_check_rounded),
        ];
        if (constraints.maxWidth < 360) {
          return Column(
            children: cards
                .map((card) => Padding(
                      padding: const EdgeInsets.only(bottom: 7),
                      child: SizedBox(width: double.infinity, child: card),
                    ))
                .toList(),
          );
        }
        return Row(
          children: [
            Expanded(child: cards[0]),
            const SizedBox(width: 8),
            Expanded(child: cards[1]),
            const SizedBox(width: 8),
            Expanded(child: cards[2]),
          ],
        );
      },
    );
  }
}

class _SummaryValue extends StatelessWidget {
  const _SummaryValue({required this.value, required this.label, required this.icon});

  final String value;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
        constraints: const BoxConstraints(minHeight: 80),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
        decoration: BoxDecoration(
          color: GphTheme.surfaceRaised,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: GphTheme.border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 17, color: GphTheme.primary),
            const SizedBox(height: 5),
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            Text(label, style: const TextStyle(color: GphTheme.textMuted, fontSize: 10)),
          ],
        ),
      );
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
          Wrap(
            spacing: 9,
            runSpacing: 7,
            crossAxisAlignment: WrapCrossAlignment.center,
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
              Text(
                first.draw,
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
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
          constraints: const BoxConstraints(minHeight: 62),
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
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
                child: AnimalArtwork(group: row.group, borderRadius: 9, showGlow: false),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(row.thousand, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 340;
                  final art = SizedBox(
                    width: compact ? 92 : 110,
                    child: AnimalArtwork(group: row.group, borderRadius: 14),
                  );
                  final info = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        row.animal,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
                  );
                  if (compact) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [art, const SizedBox(height: 10), info],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [art, const SizedBox(width: 14), Expanded(child: info)],
                  );
                },
              ),
              const SizedBox(height: 18),
              _DetailLine(label: 'Milhar', value: row.thousand, accent: GphTheme.primary),
              _DetailLine(label: 'Centena', value: row.hundred, accent: GphTheme.textPrimary),
              _DetailLine(label: 'Dezena', value: row.ten, accent: GphTheme.textPrimary),
              _DetailLine(
                label: 'Grupo',
                value: '${row.group.toString().padLeft(2, '0')} • ${row.animal}',
                accent: GphTheme.primary,
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
  const _DetailLine({required this.label, required this.value, required this.accent});

  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 7),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: GphTheme.surface,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: GphTheme.border),
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
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: accent, fontWeight: FontWeight.w900, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}

String _displayDate(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
