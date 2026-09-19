import 'package:flutter/material.dart';

import '../app_services.dart';
import '../data/animals.dart';
import '../data/history_repository.dart';
import '../models/animal_delay_stats.dart';
import '../models/delay_summary.dart';
import '../models/history_result.dart';
import '../services/history_sync_service.dart';
import 'widgets/animal_explorer_widgets.dart';
import 'widgets/home_overview_widgets.dart';

enum _AnimalSort { group, delayAny, delayHead }

/// Nova composição visual da tela inicial.
///
/// Reutiliza exatamente a mesma base, sincronização e cálculos da Alpha 11;
/// a mudança aqui é somente de apresentação e ergonomia para toque.
class HomeVisualScreen extends StatefulWidget {
  const HomeVisualScreen({super.key});

  @override
  State<HomeVisualScreen> createState() => _HomeVisualScreenState();
}

class _HomeVisualScreenState extends State<HomeVisualScreen> {
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
            builder: (context, snapshot) => HomeSyncCard(
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
                return const HomeInfoCard(text: 'Carregando último resultado...');
              }
              if (rows.isEmpty) return const SizedBox.shrink();
              return LatestResultCard(rows: rows);
            },
          ),
          const SizedBox(height: 24),
          const HomeSectionTitle(
            title: 'Atrasos atuais',
            subtitle: 'Os maiores atrasos da base, considerando extrações completas.',
          ),
          const SizedBox(height: 10),
          FutureBuilder<DelaySummary>(
            future: _delays,
            builder: (context, snapshot) {
              final summary = snapshot.data;
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const HomeInfoCard(text: 'Calculando atrasos...');
              }
              if (summary == null || summary.isEmpty) {
                return const HomeInfoCard(text: 'Prepare o histórico para calcular os atrasos.');
              }
              return DelayStrip(summary: summary);
            },
          ),
          const SizedBox(height: 26),
          const HomeSectionTitle(
            title: 'Os 25 bichos',
            subtitle: 'Toque no bicho para abrir dezenas, atrasos e histórico completo.',
          ),
          const SizedBox(height: 11),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _SortChip(
                  label: 'Grupo',
                  selected: _sort == _AnimalSort.group,
                  onTap: () => setState(() => _sort = _AnimalSort.group),
                ),
                const SizedBox(width: 8),
                _SortChip(
                  label: 'Atraso 1º–5º',
                  selected: _sort == _AnimalSort.delayAny,
                  onTap: () => setState(() => _sort = _AnimalSort.delayAny),
                ),
                const SizedBox(width: 8),
                _SortChip(
                  label: 'Atraso cabeça',
                  selected: _sort == _AnimalSort.delayHead,
                  onTap: () => setState(() => _sort = _AnimalSort.delayHead),
                ),
              ],
            ),
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

              return AnimalExplorerGrid(
                animals: animals,
                delayByGroup: delayByGroup,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SortChip extends StatelessWidget {
  const _SortChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
      );
}
