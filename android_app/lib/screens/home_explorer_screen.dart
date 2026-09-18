import 'package:flutter/material.dart';

import '../app_services.dart';
import '../data/animals.dart';
import '../data/history_repository.dart';
import '../models/animal.dart';
import '../models/animal_delay_stats.dart';
import '../models/delay_summary.dart';
import '../models/frequency_stats.dart';
import '../models/history_result.dart';
import '../services/history_sync_service.dart';

enum _AnimalSort { group, delayAny, delayHead }

class HomeExplorerScreen extends StatefulWidget {
  const HomeExplorerScreen({super.key});

  @override
  State<HomeExplorerScreen> createState() => _HomeExplorerScreenState();
}

class _HomeExplorerScreenState extends State<HomeExplorerScreen> {
  late Future<HistorySummary> _summary;
  late Future<List<HistoryResult>> _latest;
  late Future<DelaySummary> _delays;
  late Future<List<AnimalDelayEntry>> _animalDelays;
  bool _syncing = false;
  SyncProgress? _progress;
  String? _syncMessage;
  _AnimalSort _sort = _AnimalSort.group;

  @override
  void initState() {
    super.initState();
    _reloadLocal();
  }

  void _reloadLocal() {
    _summary = AppServices.history.summary();
    _latest = AppServices.history.latest(limit: 5);
    _delays = AppServices.history.delays();
    _animalDelays = AppServices.history.animalDelays();
  }

  Future<void> _refresh() async {
    setState(_reloadLocal);
    await Future.wait([_summary, _latest, _delays, _animalDelays]);
  }

  Future<void> _sync() async {
    if (_syncing) return;
    setState(() {
      _syncing = true;
      _progress = null;
      _syncMessage = null;
    });
    try {
      final result = await AppServices.sync.sync(
        onProgress: (progress) {
          if (mounted) setState(() => _progress = progress);
        },
      );
      if (!mounted) return;
      setState(() {
        _reloadLocal();
        _syncMessage = result.initialLoad
            ? 'Primeira sincronização concluída. ${result.saved} prêmios processados.'
            : 'Atualização concluída. ${result.saved} prêmios processados.';
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_syncMessage!)));
    } on SyncException catch (error) {
      if (!mounted) return;
      setState(() {
        _reloadLocal();
        _syncMessage = error.message;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!mounted) return;
      setState(() => _syncMessage = 'Não foi possível sincronizar agora.');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível sincronizar agora.')),
      );
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
        children: [
          FutureBuilder<HistorySummary>(
            future: _summary,
            builder: (context, snapshot) => _SyncCard(
              summary: snapshot.data,
              syncing: _syncing,
              progress: _progress,
              message: _syncMessage,
              onSync: _sync,
            ),
          ),
          const SizedBox(height: 14),
          FutureBuilder<List<HistoryResult>>(
            future: _latest,
            builder: (context, snapshot) {
              final rows = snapshot.data ?? const <HistoryResult>[];
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const _InfoCard(text: 'Carregando último resultado...');
              }
              if (rows.isEmpty) return const SizedBox.shrink();
              return _LatestResultCard(rows: rows);
            },
          ),
          const SizedBox(height: 22),
          const _SectionTitle(
            title: 'Atrasos atuais',
            subtitle: 'Maiores atrasos considerando somente extrações completas.',
          ),
          const SizedBox(height: 10),
          FutureBuilder<DelaySummary>(
            future: _delays,
            builder: (context, snapshot) {
              final summary = snapshot.data;
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const _InfoCard(text: 'Calculando atrasos...');
              }
              if (summary == null || summary.isEmpty) {
                return const _InfoCard(text: 'Prepare o histórico para calcular os atrasos.');
              }
              return _DelayStrip(summary: summary);
            },
          ),
          const SizedBox(height: 24),
          const _SectionTitle(
            title: 'Explorar os 25 bichos',
            subtitle: 'Veja dezenas, atraso atual e detalhes históricos de cada grupo.',
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Grupo'),
                selected: _sort == _AnimalSort.group,
                onSelected: (_) => setState(() => _sort = _AnimalSort.group),
              ),
              ChoiceChip(
                label: const Text('Atraso 1º–5º'),
                selected: _sort == _AnimalSort.delayAny,
                onSelected: (_) => setState(() => _sort = _AnimalSort.delayAny),
              ),
              ChoiceChip(
                label: const Text('Atraso cabeça'),
                selected: _sort == _AnimalSort.delayHead,
                onSelected: (_) => setState(() => _sort = _AnimalSort.delayHead),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FutureBuilder<List<AnimalDelayEntry>>(
            future: _animalDelays,
            builder: (context, snapshot) {
              final delayByGroup = {
                for (final item in snapshot.data ?? const <AnimalDelayEntry>[]) item.group: item,
              };
              final animals = [...gphAnimals];
              if (_sort == _AnimalSort.delayAny) {
                animals.sort((a, b) {
                  final av = delayByGroup[a.group]?.delayAny ?? -1;
                  final bv = delayByGroup[b.group]?.delayAny ?? -1;
                  final byDelay = bv.compareTo(av);
                  return byDelay != 0 ? byDelay : a.group.compareTo(b.group);
                });
              } else if (_sort == _AnimalSort.delayHead) {
                animals.sort((a, b) {
                  final av = delayByGroup[a.group]?.delayHead ?? -1;
                  final bv = delayByGroup[b.group]?.delayHead ?? -1;
                  final byDelay = bv.compareTo(av);
                  return byDelay != 0 ? byDelay : a.group.compareTo(b.group);
                });
              }

              return LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 760
                      ? 4
                      : constraints.maxWidth >= 520
                          ? 3
                          : 2;
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: animals.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 1.03,
                    ),
                    itemBuilder: (context, index) {
                      final animal = animals[index];
                      return _AnimalExplorerCard(
                        animal: animal,
                        delay: delayByGroup[animal.group],
                      );
                    },
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(color: Color(0xFF7F94AD), fontSize: 12)),
        ],
      );
}

class _SyncCard extends StatelessWidget {
  const _SyncCard({
    required this.summary,
    required this.syncing,
    required this.progress,
    required this.message,
    required this.onSync,
  });

  final HistorySummary? summary;
  final bool syncing;
  final SyncProgress? progress;
  final String? message;
  final VoidCallback onSync;

  @override
  Widget build(BuildContext context) {
    final empty = summary == null || summary!.isEmpty;
    final progressValue = progress == null || progress!.total <= 0
        ? null
        : progress!.current / progress!.total;
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF10213A), Color(0xFF0D1726)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF24405F)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFF173253),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.storage_rounded, color: Color(0xFF7DB6FF)),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      empty ? 'Base histórica no celular' : '${summary!.totalPrizes} prêmios salvos',
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      empty
                          ? 'Prepare o histórico do Rio de Janeiro desde 02/01/2026.'
                          : '${_date(summary!.firstDate)} → ${_date(summary!.lastDate)}',
                      style: const TextStyle(color: Color(0xFF9FB0C5), fontSize: 12),
                    ),
                  ],
                ),
              ),
              FilledButton.tonalIcon(
                onPressed: syncing ? null : onSync,
                icon: syncing
                    ? const SizedBox(
                        width: 17,
                        height: 17,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.sync_rounded, size: 19),
                label: Text(empty ? 'Preparar' : 'Atualizar'),
              ),
            ],
          ),
          if (syncing) ...[
            const SizedBox(height: 13),
            LinearProgressIndicator(value: progressValue),
            const SizedBox(height: 7),
            Text(
              progress == null
                  ? 'Preparando sincronização...'
                  : 'Consultando ${_dateTime(progress!.day)} • ${progress!.current}/${progress!.total} dias • ${progress!.saved} prêmios',
              style: const TextStyle(color: Color(0xFF9FB0C5), fontSize: 11),
            ),
          ],
          if (!syncing && message != null) ...[
            const SizedBox(height: 9),
            Text(message!, style: const TextStyle(color: Color(0xFF86EFAC), fontSize: 11)),
          ],
        ],
      ),
    );
  }
}

class _LatestResultCard extends StatelessWidget {
  const _LatestResultCard({required this.rows});
  final List<HistoryResult> rows;

  @override
  Widget build(BuildContext context) {
    final first = rows.first;
    final ordered = [...rows]..sort((a, b) => a.prize.compareTo(b.prize));
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1523),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF1C2B41)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bolt_rounded, color: Color(0xFF60A5FA), size: 21),
              const SizedBox(width: 7),
              const Expanded(
                child: Text('Último resultado', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
              ),
              Text('${first.draw} • ${first.time}', style: const TextStyle(color: Color(0xFFB9D6F7), fontSize: 11)),
            ],
          ),
          Text(_date(first.date), style: const TextStyle(color: Color(0xFF7F94AD), fontSize: 11)),
          const SizedBox(height: 8),
          ...ordered.map(
            (row) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  SizedBox(width: 34, child: Text('${row.prize}º', style: const TextStyle(color: Color(0xFF7F94AD)))),
                  SizedBox(width: 62, child: Text(row.thousand, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16))),
                  Expanded(child: Text(_titleCase(row.animal), style: const TextStyle(fontWeight: FontWeight.w700))),
                  Text('G${row.group.toString().padLeft(2, '0')}', style: const TextStyle(color: Color(0xFF9FB0C5), fontSize: 12)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DelayStrip extends StatelessWidget {
  const _DelayStrip({required this.summary});
  final DelaySummary summary;

  @override
  Widget build(BuildContext context) {
    final items = [
      ('1º–5º', summary.animalAny),
      ('Cabeça', summary.animalHead),
      ('Centena', summary.hundred),
      ('Dezena', summary.ten),
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((item) {
        final leader = item.$2;
        return Container(
          width: (MediaQuery.sizeOf(context).width - 48) / 2,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF0D1726),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF1C2B41)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.$1, style: const TextStyle(color: Color(0xFF8EA3BA), fontSize: 11, fontWeight: FontWeight.w700)),
              const SizedBox(height: 5),
              Text(leader?.value ?? '—', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
              Text(leader == null ? 'Sem dados' : '${leader.delay} extrações', style: const TextStyle(color: Color(0xFF7DB6FF), fontSize: 11)),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _AnimalExplorerCard extends StatelessWidget {
  const _AnimalExplorerCard({required this.animal, required this.delay});
  final Animal animal;
  final AnimalDelayEntry? delay;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF0D1726),
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showAnimalDetails(context, animal.group),
        child: Container(
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF1C2B41)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFF162A46),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(animal.group.toString().padLeft(2, '0'), style: const TextStyle(color: Color(0xFFBFD8FF), fontWeight: FontWeight.w900)),
                  ),
                  const Spacer(),
                  const Icon(Icons.chevron_right_rounded, color: Color(0xFF536B85)),
                ],
              ),
              const SizedBox(height: 9),
              Text(animal.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
              const SizedBox(height: 2),
              Text(animal.dozens, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF7F94AD), fontSize: 10)),
              const Spacer(),
              Row(
                children: [
                  Expanded(child: _MiniMetric(label: '1º–5º', value: delay == null ? '—' : '${delay!.delayAny}')),
                  const SizedBox(width: 6),
                  Expanded(child: _MiniMetric(label: 'Cabeça', value: delay == null ? '—' : '${delay!.delayHead}')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF0A1422),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
            Text(label, style: const TextStyle(color: Color(0xFF71869F), fontSize: 9)),
          ],
        ),
      );
}

Future<void> _showAnimalDetails(BuildContext context, int group) async {
  final animal = gphAnimals.firstWhere((item) => item.group == group);
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF0D1726),
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
        child: FutureBuilder<AnimalOverview>(
          future: AppServices.history.animalOverview(group),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(height: 240, child: Center(child: CircularProgressIndicator()));
            }
            if (snapshot.data == null) {
              return const SizedBox(height: 180, child: Center(child: Text('Não foi possível carregar os detalhes.')));
            }
            final info = snapshot.data!;
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${animal.name} • Grupo ${group.toString().padLeft(2, '0')}', style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 3),
                  Text('Dezenas: ${animal.dozens}', style: const TextStyle(color: Color(0xFF9FB0C5))),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _DetailMetric(label: 'Aparições 1º–5º', value: '${info.totalAppearances}x')),
                      const SizedBox(width: 8),
                      Expanded(child: _DetailMetric(label: 'Cabeças 1º', value: '${info.firstPrizeAppearances}x')),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: _DetailMetric(label: 'Atraso 1º–5º', value: '${info.delayAny}')),
                      const SizedBox(width: 8),
                      Expanded(child: _DetailMetric(label: 'Atraso cabeça', value: '${info.delayHead}')),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _OccurrenceLine(label: 'Última aparição', row: info.lastAny),
                  const SizedBox(height: 7),
                  _OccurrenceLine(label: 'Última cabeça', row: info.lastFirst),
                  const SizedBox(height: 16),
                  const Text('Ocorrências recentes', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                  const SizedBox(height: 8),
                  ...info.recent.take(6).map(
                    (row) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Row(
                        children: [
                          SizedBox(width: 82, child: Text(_date(row.date), style: const TextStyle(color: Color(0xFF8296AD), fontSize: 11))),
                          SizedBox(width: 46, child: Text(row.time, style: const TextStyle(fontSize: 11))),
                          SizedBox(width: 34, child: Text('${row.prize}º', style: const TextStyle(fontSize: 11))),
                          SizedBox(width: 58, child: Text(row.thousand, style: const TextStyle(fontWeight: FontWeight.w900))),
                          Expanded(child: Text(row.draw, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF9FB0C5), fontSize: 11))),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    ),
  );
}

class _DetailMetric extends StatelessWidget {
  const _DetailMetric({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: const Color(0xFF0B1523),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF1C2B41)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
            Text(label, style: const TextStyle(color: Color(0xFF7F94AD), fontSize: 10)),
          ],
        ),
      );
}

class _OccurrenceLine extends StatelessWidget {
  const _OccurrenceLine({required this.label, required this.row});
  final String label;
  final HistoryResult? row;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: const Color(0xFF0B1523),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Color(0xFF7F94AD), fontSize: 10)),
            const SizedBox(height: 3),
            Text(
              row == null ? 'Ainda não apareceu na base' : '${_date(row!.date)} • ${row!.draw} ${row!.time} • ${row!.prize}º • ${row!.thousand}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      );
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF0B1523),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF1C2B41)),
        ),
        child: Text(text, style: const TextStyle(color: Color(0xFF879BB4))),
      );
}

String _date(String? iso) {
  if (iso == null) return '—';
  final parts = iso.split('-');
  if (parts.length != 3) return iso;
  return '${parts[2]}/${parts[1]}/${parts[0]}';
}

String _dateTime(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';

String _titleCase(String value) {
  final trimmed = value.trim().toLowerCase();
  if (trimmed.isEmpty) return value;
  return '${trimmed[0].toUpperCase()}${trimmed.substring(1)}';
}
