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
                  : 2;
          final ratio = columns == 2 ? 0.76 : (columns == 3 ? 0.82 : 0.88);

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

    return Material(
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
                        padding: EdgeInsets.all(4),
                        child: Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFFBFD8FF)),
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
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        animal.dozens,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: GphTheme.textMuted, fontSize: 10),
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
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 6),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                color: accent,
                fontWeight: FontWeight.w900,
                fontSize: 14,
              ),
            ),
            Text(label, style: const TextStyle(color: GphTheme.textMuted, fontSize: 9)),
          ],
        ),
      );
}

Future<void> showAnimalDetails(BuildContext context, int group) async {
  final animal = gphAnimals.firstWhere((item) => item.group == group);

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 22),
        child: FutureBuilder<AnimalOverview>(
          future: AppServices.history.animalOverview(group),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(height: 260, child: Center(child: CircularProgressIndicator()));
            }
            final info = snapshot.data;
            if (info == null) {
              return const SizedBox(height: 190, child: Center(child: Text('Não foi possível carregar os detalhes.')));
            }

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimalArtwork(group: group, borderRadius: 18),
                  const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(animal.name, style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w900)),
                            const SizedBox(height: 2),
                            Text('Dezenas: ${animal.dozens}', style: const TextStyle(color: GphTheme.textSecondary)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                        decoration: BoxDecoration(
                          color: GphTheme.primarySoft,
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: Text(
                          'Grupo ${group.toString().padLeft(2, '0')}',
                          style: const TextStyle(color: GphTheme.primary, fontWeight: FontWeight.w900),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _DetailMetric(label: 'Aparições 1º–5º', value: '${info.totalAppearances}x')),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _DetailMetric(
                          label: 'Cabeças 1º',
                          value: '${info.firstPrizeAppearances}x',
                          accent: GphTheme.head,
                          background: GphTheme.headSoft,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _DetailMetric(
                          label: 'Atraso 1º–5º',
                          value: '${info.delayAny}',
                          accent: GphTheme.delay,
                          background: GphTheme.delaySoft,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _DetailMetric(
                          label: 'Atraso cabeça',
                          value: '${info.delayHead}',
                          accent: GphTheme.head,
                          background: GphTheme.headSoft,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _OccurrenceLine(label: 'Última aparição', row: info.lastAny),
                  const SizedBox(height: 7),
                  _OccurrenceLine(label: 'Última cabeça', row: info.lastFirst),
                  const SizedBox(height: 18),
                  const Text('Ocorrências recentes', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                  const SizedBox(height: 8),
                  ...info.recent.take(6).map(
                    (row) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Row(
                        children: [
                          SizedBox(width: 82, child: Text(gphDate(row.date), style: const TextStyle(color: GphTheme.textMuted, fontSize: 11))),
                          SizedBox(width: 46, child: Text(row.time, style: const TextStyle(fontSize: 11))),
                          SizedBox(width: 34, child: Text('${row.prize}º', style: const TextStyle(fontSize: 11))),
                          SizedBox(width: 58, child: Text(row.thousand, style: const TextStyle(fontWeight: FontWeight.w900))),
                          Expanded(child: Text(row.draw, overflow: TextOverflow.ellipsis, style: const TextStyle(color: GphTheme.textSecondary, fontSize: 11))),
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
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: GphTheme.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                color: accent,
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
            Text(label, style: const TextStyle(color: GphTheme.textMuted, fontSize: 10)),
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
          color: GphTheme.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: GphTheme.textMuted, fontSize: 10)),
            const SizedBox(height: 3),
            Text(
              row == null
                  ? 'Ainda não apareceu na base'
                  : '${gphDate(row!.date)} • ${row!.draw} ${row!.time} • ${row!.prize}º • ${row!.thousand}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      );
}
