import 'package:flutter/material.dart';

import '../app_services.dart';
import '../data/animals.dart';
import '../data/history_repository.dart';
import '../models/animal.dart';
import '../models/history_result.dart';
import '../services/history_sync_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<HistorySummary> _summary;
  late Future<List<HistoryResult>> _latest;
  bool _syncing = false;
  SyncProgress? _progress;
  String? _syncMessage;

  @override
  void initState() {
    super.initState();
    _reloadLocal();
  }

  void _reloadLocal() {
    _summary = AppServices.history.summary();
    _latest = AppServices.history.latest(limit: 5);
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
          if (!mounted) return;
          setState(() => _progress = progress);
        },
      );
      if (!mounted) return;
      setState(() {
        _reloadLocal();
        _syncMessage = result.initialLoad
            ? 'Primeira sincronização concluída. ${result.saved} prêmios processados.'
            : 'Atualização concluída. ${result.saved} prêmios processados.';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.errors.isEmpty
                ? _syncMessage!
                : '${_syncMessage!} ${result.errors.length} página(s) tiveram erro.',
          ),
        ),
      );
    } on SyncException catch (error) {
      if (!mounted) return;
      setState(() {
        _reloadLocal();
        _syncMessage = error.message;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (error) {
      if (!mounted) return;
      setState(() => _syncMessage = 'Não foi possível sincronizar agora.');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível sincronizar agora: $error')),
      );
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        setState(_reloadLocal);
        await _summary;
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            sliver: SliverToBoxAdapter(
              child: FutureBuilder<HistorySummary>(
                future: _summary,
                builder: (context, snapshot) => _SyncCard(
                  summary: snapshot.data,
                  syncing: _syncing,
                  progress: _progress,
                  message: _syncMessage,
                  onSync: _sync,
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            sliver: SliverToBoxAdapter(
              child: FutureBuilder<List<HistoryResult>>(
                future: _latest,
                builder: (context, snapshot) {
                  final rows = snapshot.data ?? const <HistoryResult>[];
                  if (rows.isEmpty) return const SizedBox.shrink();
                  return _LatestResultCard(rows: rows);
                },
              ),
            ),
          ),
          const SliverPadding(
            padding: EdgeInsets.fromLTRB(16, 14, 16, 10),
            sliver: SliverToBoxAdapter(
              child: Text('25 bichos', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            sliver: SliverLayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.crossAxisExtent;
                final columns = width >= 760 ? 5 : width >= 520 ? 4 : 3;
                return SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 0.92,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _AnimalCard(animal: gphAnimals[index]),
                    childCount: gphAnimals.length,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SyncCard extends StatelessWidget {
  const _SyncCard({required this.summary, required this.syncing, required this.progress, required this.message, required this.onSync});

  final HistorySummary? summary;
  final bool syncing;
  final SyncProgress? progress;
  final String? message;
  final VoidCallback onSync;

  @override
  Widget build(BuildContext context) {
    final info = summary;
    final empty = info == null || info.isEmpty;
    final progressValue = progress == null || progress!.total <= 0 ? null : progress!.current / progress!.total;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1726),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF1C2B41)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.storage_rounded, color: Color(0xFF60A5FA)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  empty ? 'Base histórica no celular' : '${info.totalPrizes} prêmios na base local',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            empty
                ? 'Na primeira atualização, o GP-H prepara o histórico do Rio de Janeiro desde 02/01/2026. Depois, as atualizações são incrementais.'
                : 'Período salvo: ${_displayIso(info.firstDate)} a ${_displayIso(info.lastDate)}. Os dados ficam no armazenamento privado do aplicativo.',
            style: const TextStyle(color: Color(0xFF9FB0C5), height: 1.4),
          ),
          if (syncing) ...[
            const SizedBox(height: 14),
            LinearProgressIndicator(value: progressValue),
            const SizedBox(height: 8),
            Text(
              progress == null
                  ? 'Preparando sincronização...'
                  : 'Consultando ${_displayDate(progress!.day)} • ${progress!.current}/${progress!.total} dias • ${progress!.saved} prêmios processados',
              style: const TextStyle(color: Color(0xFF9FB0C5), fontSize: 12),
            ),
          ],
          if (!syncing && message != null) ...[
            const SizedBox(height: 10),
            Text(message!, style: const TextStyle(color: Color(0xFF86EFAC), fontSize: 12)),
          ],
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: syncing ? null : onSync,
            icon: syncing
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.sync_rounded),
            label: Text(empty ? 'Preparar histórico' : 'Atualizar resultados'),
          ),
        ],
      ),
    );
  }

  static String _displayIso(String? iso) {
    if (iso == null) return '—';
    final parts = iso.split('-');
    if (parts.length != 3) return iso;
    return '${parts[2]}/${parts[1]}/${parts[0]}';
  }

  static String _displayDate(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
}

class _LatestResultCard extends StatelessWidget {
  const _LatestResultCard({required this.rows});

  final List<HistoryResult> rows;

  @override
  Widget build(BuildContext context) {
    final first = rows.first;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1523),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1C2B41)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bolt_rounded, color: Color(0xFF60A5FA), size: 20),
              const SizedBox(width: 7),
              const Text('Último resultado salvo', style: TextStyle(fontWeight: FontWeight.w800)),
              const Spacer(),
              Text('${_date(first.date)} • ${first.time}', style: const TextStyle(color: Color(0xFF7F94AD), fontSize: 12)),
            ],
          ),
          const SizedBox(height: 10),
          ...rows.map(
            (row) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
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

  static String _date(String iso) {
    final parts = iso.split('-');
    if (parts.length != 3) return iso;
    return '${parts[2]}/${parts[1]}/${parts[0]}';
  }
}

class _AnimalCard extends StatelessWidget {
  const _AnimalCard({required this.animal});
  final Animal animal;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF0D1726),
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          showModalBottomSheet<void>(
            context: context,
            backgroundColor: const Color(0xFF0D1726),
            showDragHandle: true,
            builder: (context) => Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${animal.name} • Grupo ${animal.group.toString().padLeft(2, '0')}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  Text('Dezenas: ${animal.dozens}', style: const TextStyle(color: Color(0xFFB9CBE0), fontSize: 16)),
                  const SizedBox(height: 12),
                  const Text('A pesquisa histórica deste grupo já pode ser feita na aba Pesquisa.', style: TextStyle(color: Color(0xFF879BB4))),
                ],
              ),
            ),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFF1C2B41)),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(11),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: const Color(0xFF162A46), borderRadius: BorderRadius.circular(10)),
                child: Text(animal.group.toString().padLeft(2, '0'), style: const TextStyle(color: Color(0xFFBFD8FF), fontWeight: FontWeight.w900)),
              ),
              const Spacer(),
              Text(animal.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
              const SizedBox(height: 4),
              Text(animal.dozens, maxLines: 2, style: const TextStyle(color: Color(0xFF7F94AD), fontSize: 11, height: 1.25)),
            ],
          ),
        ),
      ),
    );
  }
}
