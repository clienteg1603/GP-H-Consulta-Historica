import 'package:flutter/material.dart';

import '../../app_services.dart';
import '../../data/animals.dart';
import '../../data/history_repository.dart';
import '../../models/animal.dart';
import '../../models/animal_delay_stats.dart';
import '../../models/history_result.dart';
import '../../theme/animal_artwork.dart';
import '../../theme/gph_theme.dart';
import 'home_overview_widgets.dart';

class AnimalExplorerGrid extends StatelessWidget {
  const AnimalExplorerGrid({
    super.key,
    required this.animals,
    required this.delayByGroup,
  });

  final List<Animal> animals;
  final Map<int, AnimalDelayEntry> delayByGroup;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 760
              ? 4
              : constraints.maxWidth >= 520
                  ? 3
                  : constraints.maxWidth >= 340
                      ? 2
                      : 1;
          final ratio = columns == 1
              ? 1.42
              : columns == 2
                  ? 0.76
                  : columns == 3
                      ? 0.82
                      : 0.88;

          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: animals.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: ratio,
            ),
            itemBuilder: (context, index) {
              final animal = animals[index];
              return _AnimalCard(
                animal: animal,
                delay: delayByGroup[animal.group],
              );
            },
          );
        },
      );
}

class _AnimalCard extends StatelessWidget {
  const _AnimalCard({required this.animal, required this.delay});

  final Animal animal;
  final AnimalDelayEntry? delay;

  @override
  Widget build(BuildContext context) {
    final groupText = animal.group.toString().padLeft(2, '0');

    return Semantics(
      button: true,
      label: '${animal.name}, grupo $groupText. Toque para abrir os detalhes.',
      child: Material(
        color: GphTheme.surfaceRaised,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => showAnimalDetails(context, animal.group),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: GphTheme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    AnimalArtwork(group: animal.group, borderRadius: 0, showGlow: false),
                    Positioned(
                      left: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xD90A1422),
                          borderRadius: BorderRadius.circular(9),
                          border: Border.all(color: const Color(0x663B82F6)),
                        ),
                        child: Text(
                          'G$groupText',
                          style: const TextStyle(
                            color: Color(0xFFD7E9FF),
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                    const Positioned(
                      right: 7,
                      top: 7,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Color(0xB30A1422),
                          shape: BoxShape.circle,
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(5),
                          child: Icon(
                            Icons.chevron_right_rounded,
                            size: 18,
                            color: Color(0xFFBFD8FF),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(11, 10, 11, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          animal.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          animal.dozens,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: GphTheme.textMuted,
                            fontSize: 10,
                          ),
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            Expanded(
                              child: _MiniMetric(
                                label: '1º–5º',
                                value: delay == null ? '—' : '${delay!.delayAny}',
                                accent: GphTheme.delay,
                                background: GphTheme.delaySoft,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: _MiniMetric(
                                label: 'Cabeça',
                                value: delay == null ? '—' : '${delay!.delayHead}',
                                accent: GphTheme.head,
                                background: GphTheme.headSoft,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric({
    required this.label,
    required this.value,
    required this.accent,
    required this.background,
  });

  final String label;
  final String value;
  final Color accent;
  final Color background;

  @override
  Widget build(BuildContext context) => Container(
        constraints: const BoxConstraints(minHeight: 51),
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 6),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: accent,
                fontWeight: FontWeight.w900,
                fontSize: 14,
              ),
            ),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: GphTheme.textMuted, fontSize: 9),
            ),
          ],
        ),
      );
}

Future<void> showAnimalDetails(BuildContext context, int group) async {
  final animal = gphAnimals.firstWhere((item) => item.group == group);

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.86,
      minChildSize: 0.58,
      maxChildSize: 0.96,
      builder: (context, controller) => FutureBuilder<AnimalOverview>(
        future: AppServices.history.animalOverview(group),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _AnimalDetailsState(
              icon: Icons.pets_rounded,
              text: 'Carregando detalhes do bicho...',
              loading: true,
            );
          }

          final info = snapshot.data;
          if (snapshot.hasError || info == null) {
            return const _AnimalDetailsState(
              icon: Icons.error_outline_rounded,
              text: 'Não foi possível carregar os detalhes deste bicho.',
            );
          }

          return ListView(
            controller: controller,
            padding: const EdgeInsets.fromLTRB(18, 4, 18, 28),
            children: [
              AnimalArtwork(group: group, borderRadius: 18),
              const SizedBox(height: 14),
              LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 330;
                  final identity = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        animal.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 23,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Dezenas: ${animal.dozens}',
                        style: const TextStyle(color: GphTheme.textSecondary),
                      ),
                    ],
                  );
                  final groupBadge = Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: GphTheme.primarySoft,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Text(
                      'Grupo ${group.toString().padLeft(2, '0')}',
                      style: const TextStyle(
                        color: GphTheme.primary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  );

                  if (compact) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        identity,
                        const SizedBox(height: 9),
                        groupBadge,
                      ],
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: identity),
                      const SizedBox(width: 10),
                      groupBadge,
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              _MetricGrid(
                children: [
                  _DetailMetric(
                    label: 'Aparições 1º–5º',
                    value: '${info.totalAppearances}x',
                    accent: GphTheme.frequency,
                    background: GphTheme.primarySoft,
                  ),
                  _DetailMetric(
                    label: 'Cabeças 1º',
                    value: '${info.firstPrizeAppearances}x',
                    accent: GphTheme.head,
                    background: GphTheme.headSoft,
                  ),
                  _DetailMetric(
                    label: 'Atraso 1º–5º',
                    value: '${info.delayAny}',
                    accent: GphTheme.delay,
                    background: GphTheme.delaySoft,
                  ),
                  _DetailMetric(
                    label: 'Atraso cabeça',
                    value: '${info.delayHead}',
                    accent: GphTheme.head,
                    background: GphTheme.headSoft,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _OccurrenceLine(
                label: 'Última aparição',
                row: info.lastAny,
                accent: GphTheme.frequency,
              ),
              const SizedBox(height: 8),
              _OccurrenceLine(
                label: 'Última cabeça',
                row: info.lastFirst,
                accent: GphTheme.head,
              ),
              const SizedBox(height: 20),
              const Row(
                children: [
                  Icon(Icons.history_rounded, size: 19, color: GphTheme.primary),
                  SizedBox(width: 7),
                  Text(
                    'Ocorrências recentes',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Últimas ocorrências salvas na base local.',
                style: TextStyle(color: GphTheme.textMuted, fontSize: 10),
              ),
              const SizedBox(height: 10),
              if (info.recent.isEmpty)
                const _RecentEmpty()
              else
                ...info.recent.take(6).map(_RecentOccurrence.new),
            ],
          );
        },
      ),
    ),
  );
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 320 ? 2 : 1;
          final width = columns == 1
              ? constraints.maxWidth
              : (constraints.maxWidth - 8) / 2;

          return Wrap(
            spacing: 8,
            runSpacing: 8,
            children: children
                .map((child) => SizedBox(width: width, child: child))
                .toList(),
          );
        },
      );
}

class _DetailMetric extends StatelessWidget {
  const _DetailMetric({
    required this.label,
    required this.value,
    this.accent = GphTheme.textPrimary,
    this.background = GphTheme.surface,
  });

  final String label;
  final String value;
  final Color accent;
  final Color background;

  @override
  Widget build(BuildContext context) => Container(
        constraints: const BoxConstraints(minHeight: 76),
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: GphTheme.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: accent,
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: GphTheme.textMuted, fontSize: 10),
            ),
          ],
        ),
      );
}

class _OccurrenceLine extends StatelessWidget {
  const _OccurrenceLine({
    required this.label,
    required this.row,
    required this.accent,
  });

  final String label;
  final HistoryResult? row;
  final Color accent;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: GphTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: GphTheme.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(Icons.history_rounded, size: 17, color: accent),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(color: GphTheme.textMuted, fontSize: 10),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    row == null
                        ? 'Ainda não apareceu na base'
                        : '${gphDate(row!.date)} • ${row!.draw} ${row!.time} • ${row!.prize}º • ${row!.thousand}',
                    style: const TextStyle(fontWeight: FontWeight.w700, height: 1.3),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

class _RecentOccurrence extends StatelessWidget {
  const _RecentOccurrence(this.row);

  final HistoryResult row;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 7),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
        decoration: BoxDecoration(
          color: GphTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: GphTheme.border),
        ),
        child: Row(
          children: [
            Container(
              constraints: const BoxConstraints(minWidth: 34),
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
              decoration: BoxDecoration(
                color: GphTheme.primarySoft,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${row.prize}º',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: GphTheme.primary,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${gphDate(row.date)} • ${row.time} • ${row.draw}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    row.thousand,
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

class _RecentEmpty extends StatelessWidget {
  const _RecentEmpty();

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: GphTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: GphTheme.border),
        ),
        child: const Text(
          'Nenhuma ocorrência recente encontrada.',
          style: TextStyle(color: GphTheme.textSecondary),
        ),
      );
}

class _AnimalDetailsState extends StatelessWidget {
  const _AnimalDetailsState({
    required this.icon,
    required this.text,
    this.loading = false,
  });

  final IconData icon;
  final String text;
  final bool loading;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (loading)
                const CircularProgressIndicator()
              else
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: GphTheme.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: GphTheme.border),
                  ),
                  child: Icon(icon, color: GphTheme.textMuted),
                ),
              const SizedBox(height: 12),
              Text(
                text,
                textAlign: TextAlign.center,
                style: const TextStyle(color: GphTheme.textSecondary),
              ),
            ],
          ),
        ),
      );
}
