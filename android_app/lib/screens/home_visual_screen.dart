import 'package:flutter/material.dart';

import '../app_services.dart';
import '../data/animals.dart';
import '../data/history_repository.dart';
import '../models/animal_delay_stats.dart';
import '../models/delay_summary.dart';
import '../models/history_result.dart';
import '../theme/gph_theme.dart';
import 'sync_settings_sheet.dart';
import 'widgets/animal_explorer_widgets.dart';
import 'widgets/home_overview_widgets.dart';

enum _AnimalSort { group, delayAny, delayHead }

/// Composição visual da tela inicial.
///
/// Reutiliza a mesma base e os mesmos cálculos; as mudanças desta camada
/// são somente de apresentação e ergonomia para toque.
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

  Future<void> _openSyncSettings() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.58),
      builder: (_) => const SyncSettingsSheet(),
    );
    if (!mounted) return;
    setState(_reloadLocal);
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
        children: [
          FutureBuilder<List<HistoryResult>>(
            future: _latest,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const HomeInfoCard(
                  text: 'Carregando último resultado...',
                  icon: Icons.hourglass_top_rounded,
                );
              }
              if (snapshot.hasError) {
                return const HomeInfoCard(
                  text: 'Não foi possível carregar o último resultado agora.',
                  icon: Icons.error_outline_rounded,
                  accent: GphTheme.danger,
                );
              }
              final rows = snapshot.data ?? const <HistoryResult>[];
              if (rows.isEmpty) {
                return const HomeInfoCard(
                  text: 'Ainda não há resultados salvos. Toque em Base histórica abaixo para preparar o histórico.',
                  icon: Icons.inbox_outlined,
                );
              }
              return LatestResultCard(rows: rows);
            },
          ),
          const SizedBox(height: 12),
          FutureBuilder<HistorySummary>(
            future: _summary,
            builder: (context, snapshot) => _HistoryManageCard(
              summary: snapshot.data,
              loading: snapshot.connectionState == ConnectionState.waiting,
              onTap: _openSyncSettings,
            ),
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
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const HomeInfoCard(
                  text: 'Calculando atrasos...',
                  icon: Icons.hourglass_bottom_rounded,
                  accent: GphTheme.delay,
                );
              }
              if (snapshot.hasError) {
                return const HomeInfoCard(
                  text: 'Não foi possível calcular os atrasos agora.',
                  icon: Icons.error_outline_rounded,
                  accent: GphTheme.danger,
                );
              }
              final summary = snapshot.data;
              if (summary == null || summary.isEmpty) {
                return const HomeInfoCard(
                  text: 'Prepare o histórico para calcular os atrasos.',
                  icon: Icons.info_outline_rounded,
                );
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
                  icon: Icons.grid_view_rounded,
                  label: 'Grupo',
                  selected: _sort == _AnimalSort.group,
                  accent: GphTheme.primary,
                  selectedBackground: GphTheme.primarySoft,
                  onTap: () => setState(() => _sort = _AnimalSort.group),
                ),
                const SizedBox(width: 8),
                _SortChip(
                  icon: Icons.hourglass_bottom_rounded,
                  label: 'Atraso 1º–5º',
                  selected: _sort == _AnimalSort.delayAny,
                  accent: GphTheme.delay,
                  selectedBackground: GphTheme.delaySoft,
                  onTap: () => setState(() => _sort = _AnimalSort.delayAny),
                ),
                const SizedBox(width: 8),
                _SortChip(
                  icon: Icons.workspace_premium_rounded,
                  label: 'Atraso cabeça',
                  selected: _sort == _AnimalSort.delayHead,
                  accent: GphTheme.head,
                  selectedBackground: GphTheme.headSoft,
                  onTap: () => setState(() => _sort = _AnimalSort.delayHead),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          FutureBuilder<List<AnimalDelayEntry>>(
            future: _animalDelays,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const HomeInfoCard(
                  text: 'Carregando os 25 bichos...',
                  icon: Icons.pets_rounded,
                );
              }

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

              final grid = AnimalExplorerGrid(
                animals: animals,
                delayByGroup: delayByGroup,
              );

              if (!snapshot.hasError) return grid;

              return Column(
                children: [
                  const HomeInfoCard(
                    text: 'Os bichos foram carregados, mas não foi possível calcular os atrasos agora.',
                    icon: Icons.error_outline_rounded,
                    accent: GphTheme.danger,
                  ),
                  const SizedBox(height: 10),
                  grid,
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _HistoryManageCard extends StatelessWidget {
  const _HistoryManageCard({
    required this.summary,
    required this.loading,
    required this.onTap,
  });

  final HistorySummary? summary;
  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final empty = summary == null || summary!.isEmpty;
    final title = loading
        ? 'Carregando base histórica...'
        : empty
            ? 'Base histórica'
            : '${summary!.totalPrizes} prêmios salvos';
    final subtitle = loading
        ? 'Aguarde um instante.'
        : empty
            ? 'Toque para preparar o histórico e configurar a sincronização.'
            : '${gphDate(summary!.firstDate)} → ${gphDate(summary!.lastDate)}';

    return Material(
      color: GphTheme.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: loading ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          constraints: const BoxConstraints(minHeight: 68),
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: GphTheme.border),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: GphTheme.primarySoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.storage_rounded,
                  color: GphTheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: GphTheme.textMuted,
                        fontSize: 10,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: GphTheme.surfaceRaised,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.tune_rounded,
                  color: GphTheme.textSecondary,
                  size: 19,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SortChip extends StatelessWidget {
  const _SortChip({
    required this.icon,
    required this.label,
    required this.selected,
    required this.accent,
    required this.selectedBackground,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final Color accent;
  final Color selectedBackground;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: selected ? selectedBackground : GphTheme.surfaceRaised,
        borderRadius: BorderRadius.circular(13),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(13),
          child: Container(
            constraints: const BoxConstraints(minHeight: 44),
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: selected ? accent : GphTheme.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  selected ? Icons.check_rounded : icon,
                  size: 17,
                  color: selected ? accent : GphTheme.textMuted,
                ),
                const SizedBox(width: 7),
                Text(
                  label,
                  style: TextStyle(
                    color: selected ? GphTheme.textPrimary : GphTheme.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}
