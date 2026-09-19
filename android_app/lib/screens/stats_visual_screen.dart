import 'package:flutter/material.dart';

import '../app_services.dart';
import '../models/animal_delay_stats.dart';
import '../models/frequency_stats.dart';
import '../theme/animal_artwork.dart';
import '../theme/gph_theme.dart';
import 'widgets/animal_explorer_widgets.dart';

enum _StatsView { frequency, delay }

class StatsVisualScreen extends StatefulWidget {
  const StatsVisualScreen({super.key});

  @override
  State<StatsVisualScreen> createState() => _StatsVisualScreenState();
}

class _StatsVisualScreenState extends State<StatsVisualScreen> {
  _StatsView _view = _StatsView.frequency;
  bool _firstPrizeOnly = false;
  int? _days;
  late Future<List<FrequencyEntry>> _ranking;
  late Future<List<AnimalDelayEntry>> _delays;

  @override
  void initState() {
    super.initState();
    _reloadAll();
  }

  void _reloadAll() {
    _reloadFrequency();
    _delays = AppServices.history.animalDelays();
  }

  void _reloadFrequency() {
    _ranking = AppServices.history.animalFrequency(
      firstPrizeOnly: _firstPrizeOnly,
      days: _days,
    );
  }

  void _changeView(_StatsView view) {
    if (_view == view) return;
    setState(() => _view = view);
  }

  void _changeScope(bool firstPrizeOnly) {
    if (_firstPrizeOnly == firstPrizeOnly) return;
    setState(() {
      _firstPrizeOnly = firstPrizeOnly;
      _reloadFrequency();
    });
  }

  void _changePeriod(int? days) {
    if (_days == days) return;
    setState(() {
      _days = days;
      _reloadFrequency();
    });
  }

  Future<void> _refresh() async {
    setState(_reloadAll);
    await Future.wait([_ranking, _delays]);
  }

  @override
  Widget build(BuildContext context) {
    final delayView = _view == _StatsView.delay;
    final accent = _firstPrizeOnly
        ? GphTheme.head
        : delayView
            ? GphTheme.delay
            : GphTheme.frequency;
    final accentSoft = _firstPrizeOnly
        ? GphTheme.headSoft
        : delayView
            ? GphTheme.delaySoft
            : GphTheme.primarySoft;

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [accentSoft, GphTheme.surfaceRaised],
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
                    color: accentSoft,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(
                    _firstPrizeOnly
                        ? Icons.workspace_premium_rounded
                        : delayView
                            ? Icons.hourglass_bottom_rounded
                            : Icons.query_stats_rounded,
                    color: accent,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        delayView ? 'Atrasos dos bichos' : 'Frequência dos bichos',
                        style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        delayView
                            ? 'Atrasos atuais calculados somente com extrações completas.'
                            : 'Ranking descritivo calculado com os resultados salvos no aparelho.',
                        style: const TextStyle(
                          color: GphTheme.textSecondary,
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _ModeSelector(
            delayView: delayView,
            onFrequency: () => _changeView(_StatsView.frequency),
            onDelay: () => _changeView(_StatsView.delay),
          ),
          const SizedBox(height: 15),
          const Text('Prêmios considerados', style: TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _ScopeButton(
                  label: '1º–5º prêmio',
                  selected: !_firstPrizeOnly,
                  accent: delayView ? GphTheme.delay : GphTheme.frequency,
                  selectedBackground: delayView ? GphTheme.delaySoft : GphTheme.primarySoft,
                  onTap: () => _changeScope(false),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ScopeButton(
                  label: 'Cabeça 1º',
                  selected: _firstPrizeOnly,
                  accent: GphTheme.head,
                  selectedBackground: GphTheme.headSoft,
                  onTap: () => _changeScope(true),
                ),
              ),
            ],
          ),
          if (!delayView) ...[
            const SizedBox(height: 15),
            const Text('Período', style: TextStyle(fontWeight: FontWeight.w900)),
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
          ],
          const SizedBox(height: 20),
          if (delayView)
            FutureBuilder<List<AnimalDelayEntry>>(
              future: _delays,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const _LoadingCard(text: 'Calculando atrasos...');
                }
                if (snapshot.hasError) {
                  return const _MessageCard(text: 'Não foi possível calcular os atrasos agora.');
                }
                final rows = snapshot.data ?? const <AnimalDelayEntry>[];
                if (rows.isEmpty) {
                  return const _MessageCard(
                    text: 'Os atrasos aparecem quando a base tiver extrações completas de 1º a 5º prêmio.',
                  );
                }
                return _DelayRanking(rows: rows, firstPrizeOnly: _firstPrizeOnly);
              },
            )
          else
            FutureBuilder<List<FrequencyEntry>>(
              future: _ranking,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const _LoadingCard(text: 'Calculando frequência...');
                }
                if (snapshot.hasError) {
                  return const _MessageCard(text: 'Não foi possível calcular as estatísticas agora.');
                }
                final rows = snapshot.data ?? const <FrequencyEntry>[];
                if (rows.isEmpty) {
                  return const _MessageCard(
                    text: 'Ainda não há resultados suficientes na base local para este recorte.',
                  );
                }
                return _FrequencyRanking(rows: rows, firstPrizeOnly: _firstPrizeOnly);
              },
            ),
        ],
      ),
    );
  }
}

class _ModeSelector extends StatelessWidget {
  const _ModeSelector({
    required this.delayView,
    required this.onFrequency,
    required this.onDelay,
  });

  final bool delayView;
  final VoidCallback onFrequency;
  final VoidCallback onDelay;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: GphTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: GphTheme.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: _ModeButton(
                icon: Icons.query_stats_rounded,
                label: 'Frequência',
                selected: !delayView,
                accent: GphTheme.frequency,
                selectedBackground: GphTheme.primarySoft,
                onTap: onFrequency,
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: _ModeButton(
                icon: Icons.hourglass_bottom_rounded,
                label: 'Atrasos',
                selected: delayView,
                accent: GphTheme.delay,
                selectedBackground: GphTheme.delaySoft,
                onTap: onDelay,
              ),
            ),
          ],
        ),
      );
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({
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
        color: selected ? selectedBackground : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 18,
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

class _ScopeButton extends StatelessWidget {
  const _ScopeButton({
    required this.label,
    required this.selected,
    required this.accent,
    required this.selectedBackground,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color accent;
  final Color selectedBackground;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: selected ? selectedBackground : GphTheme.surfaceRaised,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            constraints: const BoxConstraints(minHeight: 44),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: selected ? accent : GphTheme.border),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: selected ? accent : GphTheme.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      );
}

class _FrequencyRanking extends StatelessWidget {
  const _FrequencyRanking({required this.rows, required this.firstPrizeOnly});

  final List<FrequencyEntry> rows;
  final bool firstPrizeOnly;

  @override
  Widget build(BuildContext context) {
    final total = rows.isEmpty ? 0 : rows.first.total;
    final accent = firstPrizeOnly ? GphTheme.head : GphTheme.frequency;
    final background = firstPrizeOnly ? GphTheme.headSoft : GphTheme.primarySoft;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                label: firstPrizeOnly ? 'Cabeças analisadas' : 'Prêmios analisados',
                value: '$total',
                icon: firstPrizeOnly
                    ? Icons.workspace_premium_rounded
                    : Icons.receipt_long_rounded,
                accent: accent,
                background: background,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SummaryCard(
                label: 'Bichos com ocorrência',
                value: '${rows.length}/25',
                icon: Icons.pets_rounded,
                accent: accent,
                background: background,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        const Text('Ranking de frequência', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
        const SizedBox(height: 3),
        const Text(
          'Empates usam a ocorrência mais recente e depois o grupo. Toque em um bicho para abrir os detalhes.',
          style: TextStyle(color: GphTheme.textMuted, fontSize: 10, height: 1.3),
        ),
        const SizedBox(height: 10),
        ...List.generate(
          rows.length,
          (index) => _FrequencyRow(
            position: index + 1,
            item: rows[index],
            accent: accent,
          ),
        ),
      ],
    );
  }
}

class _DelayRanking extends StatelessWidget {
  const _DelayRanking({required this.rows, required this.firstPrizeOnly});

  final List<AnimalDelayEntry> rows;
  final bool firstPrizeOnly;

  @override
  Widget build(BuildContext context) {
    final ordered = [...rows]
      ..sort((a, b) {
        final byDelay = b
            .delay(firstPrizeOnly: firstPrizeOnly)
            .compareTo(a.delay(firstPrizeOnly: firstPrizeOnly));
        if (byDelay != 0) return byDelay;
        return a.group.compareTo(b.group);
      });
    final completeDraws = ordered.first.completeDraws;
    final maxDelay = ordered.first.delay(firstPrizeOnly: firstPrizeOnly);
    final accent = firstPrizeOnly ? GphTheme.head : GphTheme.delay;
    final background = firstPrizeOnly ? GphTheme.headSoft : GphTheme.delaySoft;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                label: 'Extrações completas',
                value: '$completeDraws',
                icon: Icons.fact_check_rounded,
                accent: accent,
                background: background,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SummaryCard(
                label: 'Maior atraso atual',
                value: '$maxDelay ext.',
                icon: Icons.hourglass_bottom_rounded,
                accent: accent,
                background: background,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Text(
          firstPrizeOnly ? 'Atraso na cabeça' : 'Atraso no 1º–5º prêmio',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 3),
        const Text(
          'O atraso conta extrações completas desde a última ocorrência. Toque no bicho para ver o histórico.',
          style: TextStyle(color: GphTheme.textMuted, fontSize: 10, height: 1.3),
        ),
        const SizedBox(height: 10),
        ...List.generate(
          ordered.length,
          (index) => _DelayRow(
            position: index + 1,
            item: ordered[index],
            firstPrizeOnly: firstPrizeOnly,
            accent: accent,
          ),
        ),
      ],
    );
  }
}

class _FrequencyRow extends StatelessWidget {
  const _FrequencyRow({
    required this.position,
    required this.item,
    required this.accent,
  });

  final int position;
  final FrequencyEntry item;
  final Color accent;

  @override
  Widget build(BuildContext context) => _AnimalRankingRow(
        position: position,
        group: item.group,
        title: _titleCase(item.animal),
        subtitle: item.lastDate == null
            ? 'Sem última ocorrência'
            : 'Última: ${_date(item.lastDate!)}${item.lastTime == null ? '' : ' • ${item.lastTime}'}',
        value: '${item.count}x',
        valueLabel: '${item.percentage.toStringAsFixed(1)}%',
        accent: accent,
        onTap: () => showAnimalDetails(context, item.group),
      );
}

class _DelayRow extends StatelessWidget {
  const _DelayRow({
    required this.position,
    required this.item,
    required this.firstPrizeOnly,
    required this.accent,
  });

  final int position;
  final AnimalDelayEntry item;
  final bool firstPrizeOnly;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final delay = item.delay(firstPrizeOnly: firstPrizeOnly);
    final last = item.last(firstPrizeOnly: firstPrizeOnly);

    return _AnimalRankingRow(
      position: position,
      group: item.group,
      title: item.animal,
      subtitle: last == null
          ? 'Ainda não apareceu nas extrações completas'
          : 'Última: ${_date(last.date)} • ${last.draw} ${last.time} • ${last.prize}º',
      value: '$delay',
      valueLabel: 'extrações',
      accent: accent,
      onTap: () => showAnimalDetails(context, item.group),
    );
  }
}

class _AnimalRankingRow extends StatelessWidget {
  const _AnimalRankingRow({
    required this.position,
    required this.group,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.valueLabel,
    required this.accent,
    required this.onTap,
  });

  final int position;
  final int group;
  final String title;
  final String subtitle;
  final String value;
  final String valueLabel;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Material(
          color: GphTheme.surface,
          borderRadius: BorderRadius.circular(15),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 9),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: GphTheme.border),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 31,
                    child: Text(
                      '$positionº',
                      style: const TextStyle(color: GphTheme.textMuted, fontWeight: FontWeight.w800),
                    ),
                  ),
                  SizedBox(
                    width: 52,
                    child: AnimalArtwork(group: group, borderRadius: 9, showGlow: false),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: GphTheme.textMuted, fontSize: 9.5),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        value,
                        style: TextStyle(
                          color: accent,
                          fontWeight: FontWeight.w900,
                          fontSize: 17,
                        ),
                      ),
                      Text(
                        valueLabel,
                        style: TextStyle(
                          color: accent,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 3),
                  const Icon(Icons.chevron_right_rounded, size: 18, color: GphTheme.textMuted),
                ],
              ),
            ),
          ),
        ),
      );
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
    required this.background,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color accent;
  final Color background;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: GphTheme.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 19, color: accent),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                color: accent,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(color: GphTheme.textMuted, fontSize: 10)),
          ],
        ),
      );
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(30),
        child: Center(
          child: Column(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 10),
              Text(text, style: const TextStyle(color: GphTheme.textSecondary)),
            ],
          ),
        ),
      );
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(
          color: GphTheme.surface,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: GphTheme.border),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline_rounded, color: GphTheme.textMuted, size: 20),
            const SizedBox(width: 9),
            Expanded(child: Text(text, style: const TextStyle(color: GphTheme.textSecondary))),
          ],
        ),
      );
}

String _date(String iso) {
  final parts = iso.split('-');
  if (parts.length != 3) return iso;
  return '${parts[2]}/${parts[1]}/${parts[0]}';
}

String _titleCase(String value) {
  final trimmed = value.trim().toLowerCase();
  if (trimmed.isEmpty) return value;
  return '${trimmed[0].toUpperCase()}${trimmed.substring(1)}';
}
