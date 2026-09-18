import 'package:flutter/material.dart';

import '../app_services.dart';
import '../models/frequency_stats.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  bool _firstPrizeOnly = false;
  int? _days;
  late Future<List<FrequencyEntry>> _ranking;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _ranking = AppServices.history.animalFrequency(
      firstPrizeOnly: _firstPrizeOnly,
      days: _days,
    );
  }

  void _changeScope(bool firstPrizeOnly) {
    if (_firstPrizeOnly == firstPrizeOnly) return;
    setState(() {
      _firstPrizeOnly = firstPrizeOnly;
      _reload();
    });
  }

  void _changePeriod(int? days) {
    if (_days == days) return;
    setState(() {
      _days = days;
      _reload();
    });
  }

  Future<void> _refresh() async {
    setState(_reload);
    await _ranking;
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF10213A), Color(0xFF0D1726)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFF24405F)),
            ),
            child: const Row(
              children: [
                Icon(Icons.query_stats_rounded, color: Color(0xFF7DB6FF), size: 28),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Frequência dos bichos',
                        style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Ranking descritivo calculado somente com os resultados salvos no aparelho.',
                        style: TextStyle(color: Color(0xFF9FB0C5), fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text('Prêmios considerados', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: const SizedBox(width: double.infinity, child: Center(child: Text('1º–5º prêmio'))),
                  selected: !_firstPrizeOnly,
                  onSelected: (_) => _changeScope(false),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ChoiceChip(
                  label: const SizedBox(width: double.infinity, child: Center(child: Text('Somente 1º'))),
                  selected: _firstPrizeOnly,
                  onSelected: (_) => _changeScope(true),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Período', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Todo histórico'),
                selected: _days == null,
                onSelected: (_) => _changePeriod(null),
              ),
              ChoiceChip(
                label: const Text('30 dias'),
                selected: _days == 30,
                onSelected: (_) => _changePeriod(30),
              ),
              ChoiceChip(
                label: const Text('90 dias'),
                selected: _days == 90,
                onSelected: (_) => _changePeriod(90),
              ),
            ],
          ),
          const SizedBox(height: 20),
          FutureBuilder<List<FrequencyEntry>>(
            future: _ranking,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(30),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (snapshot.hasError) {
                return _message('Não foi possível calcular as estatísticas agora.');
              }
              final rows = snapshot.data ?? const <FrequencyEntry>[];
              if (rows.isEmpty) {
                return _message('Ainda não há resultados suficientes na base local para este recorte.');
              }
              return _RankingPanel(rows: rows, firstPrizeOnly: _firstPrizeOnly);
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
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF1C2B41)),
        ),
        child: Text(text, style: const TextStyle(color: Color(0xFF9FB0C5))),
      );
}

class _RankingPanel extends StatelessWidget {
  const _RankingPanel({required this.rows, required this.firstPrizeOnly});

  final List<FrequencyEntry> rows;
  final bool firstPrizeOnly;

  @override
  Widget build(BuildContext context) {
    final total = rows.isEmpty ? 0 : rows.first.total;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                label: firstPrizeOnly ? 'Cabeças analisadas' : 'Prêmios analisados',
                value: '$total',
                icon: firstPrizeOnly ? Icons.workspace_premium_rounded : Icons.receipt_long_rounded,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SummaryCard(
                label: 'Bichos com ocorrência',
                value: '${rows.length}/25',
                icon: Icons.pets_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text('Ranking de frequência', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
        const SizedBox(height: 3),
        const Text(
          'Empates são ordenados pela ocorrência mais recente e depois pelo número do grupo.',
          style: TextStyle(color: Color(0xFF7F94AD), fontSize: 11),
        ),
        const SizedBox(height: 10),
        ...List.generate(rows.length, (index) {
          final item = rows[index];
          return _FrequencyRow(position: index + 1, item: item);
        }),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.label, required this.value, required this.icon});

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1726),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFF1C2B41)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 19, color: const Color(0xFF79B4FF)),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: Color(0xFF8296AD), fontSize: 10)),
        ],
      ),
    );
  }
}

class _FrequencyRow extends StatelessWidget {
  const _FrequencyRow({required this.position, required this.item});

  final int position;
  final FrequencyEntry item;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1523),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1C2B41)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(
              '$positionº',
              style: const TextStyle(color: Color(0xFF6E86A1), fontWeight: FontWeight.w800),
            ),
          ),
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFF162A46),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              item.group.toString().padLeft(2, '0'),
              style: const TextStyle(color: Color(0xFFBFD8FF), fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_titleCase(item.animal), style: const TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(
                  item.lastDate == null
                      ? 'Sem última ocorrência'
                      : 'Última: ${_date(item.lastDate!)}${item.lastTime == null ? '' : ' • ${item.lastTime}'}',
                  style: const TextStyle(color: Color(0xFF71869F), fontSize: 10),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${item.count}x', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
              Text(
                '${item.percentage.toStringAsFixed(1)}%',
                style: const TextStyle(color: Color(0xFF7DB6FF), fontSize: 11, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _date(String iso) {
    final parts = iso.split('-');
    if (parts.length != 3) return iso;
    return '${parts[2]}/${parts[1]}/${parts[0]}';
  }
}

String _titleCase(String value) {
  final trimmed = value.trim().toLowerCase();
  if (trimmed.isEmpty) return value;
  return '${trimmed[0].toUpperCase()}${trimmed.substring(1)}';
}
