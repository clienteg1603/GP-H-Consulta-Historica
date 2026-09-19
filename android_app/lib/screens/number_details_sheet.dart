import 'package:flutter/material.dart';

import '../app_services.dart';
import '../models/history_result.dart';
import '../models/number_overview.dart';
import '../theme/animal_artwork.dart';
import '../theme/gph_theme.dart';

Future<void> showNumberDetails(
  BuildContext context, {
  required String mode,
  required String value,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.80,
      minChildSize: 0.55,
      maxChildSize: 0.95,
      builder: (context, controller) => _NumberDetailsBody(
        mode: mode,
        value: value,
        controller: controller,
      ),
    ),
  );
}

class _NumberDetailsBody extends StatelessWidget {
  const _NumberDetailsBody({
    required this.mode,
    required this.value,
    required this.controller,
  });

  final String mode;
  final String value;
  final ScrollController controller;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<NumberOverview>(
      future: AppServices.history.numberOverview(mode: mode, value: value),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text('Não foi possível carregar os detalhes deste número.'),
            ),
          );
        }

        final data = snapshot.data!;
        final hasAnimal = data.group >= 1 && data.group <= 25 && data.animal.isNotEmpty;

        return ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 30),
          children: [
            if (hasAnimal)
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: GphTheme.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: GphTheme.borderStrong),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final compact = constraints.maxWidth < 330;
                    final art = SizedBox(
                      width: compact ? 88 : 105,
                      child: AnimalArtwork(
                        group: data.group,
                        borderRadius: 13,
                        showGlow: false,
                      ),
                    );
                    final info = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                              decoration: BoxDecoration(
                                color: GphTheme.primarySoft,
                                borderRadius: BorderRadius.circular(9),
                              ),
                              child: Text(
                                data.value,
                                style: const TextStyle(
                                  color: Color(0xFFD7E9FF),
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            Text(
                              data.mode,
                              style: const TextStyle(
                                color: GphTheme.textMuted,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 7),
                        Text(
                          data.animal,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Grupo ${data.group.toString().padLeft(2, '0')}',
                          style: const TextStyle(
                            color: GphTheme.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    );

                    if (compact) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          art,
                          const SizedBox(height: 10),
                          info,
                        ],
                      );
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        art,
                        const SizedBox(width: 12),
                        Expanded(child: info),
                      ],
                    );
                  },
                ),
              )
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    constraints: const BoxConstraints(minWidth: 76),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: GphTheme.primarySoft,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      data.value,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w900),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(data.mode, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 4),
                        const Text(
                          'Grupo não identificado',
                          style: TextStyle(color: GphTheme.textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 18),
            LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth >= 520
                    ? (constraints.maxWidth - 10) / 2
                    : constraints.maxWidth;
                final cards = <Widget>[
                  _MetricCard(
                    label: '1º–5º prêmio',
                    value: '${data.totalAppearances}x',
                    icon: Icons.receipt_long_rounded,
                    accent: GphTheme.frequency,
                    background: GphTheme.primarySoft,
                  ),
                  _MetricCard(
                    label: 'Cabeça 1º',
                    value: '${data.firstPrizeAppearances}x',
                    icon: Icons.workspace_premium_rounded,
                    accent: GphTheme.head,
                    background: GphTheme.headSoft,
                  ),
                  if (data.currentDelay != null)
                    _MetricCard(
                      label: 'Atraso atual',
                      value: '${data.currentDelay} ext.',
                      icon: Icons.hourglass_bottom_rounded,
                      accent: GphTheme.delay,
                      background: GphTheme.delaySoft,
                    ),
                  if (data.currentDelay != null)
                    _MetricCard(
                      label: 'Base completa',
                      value: '${data.completeDraws ?? 0} ext.',
                      icon: Icons.fact_check_rounded,
                      accent: GphTheme.textSecondary,
                      background: GphTheme.surfaceRaised,
                    ),
                ];
                return Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: cards.map((card) => SizedBox(width: width, child: card)).toList(),
                );
              },
            ),
            const SizedBox(height: 18),
            _OccurrenceCard(
              label: 'Última ocorrência',
              row: data.lastAny,
              accent: GphTheme.frequency,
            ),
            const SizedBox(height: 8),
            _OccurrenceCard(
              label: 'Última cabeça',
              row: data.lastFirst,
              accent: GphTheme.head,
            ),
            const SizedBox(height: 20),
            const Row(
              children: [
                Icon(Icons.history_rounded, size: 19, color: GphTheme.primary),
                SizedBox(width: 7),
                Text(
                  'Ocorrências recentes',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Histórico recente salvo no aparelho.',
              style: TextStyle(color: GphTheme.textMuted, fontSize: 10),
            ),
            const SizedBox(height: 10),
            if (data.recent.isEmpty)
              const _EmptyRecent()
            else
              ...data.recent.map(_RecentRow.new),
            if (data.currentDelay != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
                decoration: BoxDecoration(
                  color: GphTheme.delaySoft,
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(color: const Color(0x665A481D)),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline_rounded, size: 16, color: GphTheme.delay),
                    SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        'O atraso é somente uma medida histórica e não indica ocorrência futura.',
                        style: TextStyle(color: GphTheme.textSecondary, fontSize: 10, height: 1.3),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
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
        constraints: const BoxConstraints(minHeight: 92),
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: GphTheme.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: accent),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(color: accent, fontSize: 19, fontWeight: FontWeight.w900),
            ),
            Text(label, style: const TextStyle(color: GphTheme.textMuted, fontSize: 10)),
          ],
        ),
      );
}

class _OccurrenceCard extends StatelessWidget {
  const _OccurrenceCard({required this.label, required this.row, required this.accent});

  final String label;
  final HistoryResult? row;
  final Color accent;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: GphTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: GphTheme.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.history_rounded, size: 17, color: accent),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(color: GphTheme.textMuted, fontSize: 10)),
                  const SizedBox(height: 4),
                  Text(
                    row == null
                        ? 'Sem ocorrência na base.'
                        : '${_date(row!.date)} • ${row!.time} • ${row!.draw} • ${row!.prize}º prêmio',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

class _EmptyRecent extends StatelessWidget {
  const _EmptyRecent();

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
          'Nenhuma ocorrência encontrada.',
          style: TextStyle(color: GphTheme.textSecondary),
        ),
      );
}

class _RecentRow extends StatelessWidget {
  const _RecentRow(this.row);

  final HistoryResult row;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 7),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: GphTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: GphTheme.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                '${_date(row.date)} • ${row.time} • ${row.draw}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: GphTheme.primarySoft,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${row.prize}º • ${row.thousand}',
                style: const TextStyle(color: GphTheme.primary, fontSize: 11, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      );
}

String _date(String iso) {
  final parts = iso.split('-');
  if (parts.length != 3) return iso;
  return '${parts[2]}/${parts[1]}/${parts[0]}';
}
