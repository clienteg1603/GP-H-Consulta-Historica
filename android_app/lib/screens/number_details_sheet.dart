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
      initialChildSize: 0.78,
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
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 105,
                      child: AnimalArtwork(
                        group: data.group,
                        borderRadius: 13,
                        showGlow: false,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
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
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  data.mode,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: GphTheme.textMuted,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                  ),
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
                      ),
                    ),
                  ],
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
            Row(
              children: [
                Expanded(
                  child: _MetricCard(
                    label: '1º–5º prêmio',
                    value: '${data.totalAppearances}x',
                    icon: Icons.receipt_long_rounded,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MetricCard(
                    label: 'Cabeça 1º',
                    value: '${data.firstPrizeAppearances}x',
                    icon: Icons.workspace_premium_rounded,
                  ),
                ),
              ],
            ),
            if (data.currentDelay != null) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _MetricCard(
                      label: 'Atraso atual',
                      value: '${data.currentDelay} ext.',
                      icon: Icons.hourglass_bottom_rounded,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _MetricCard(
                      label: 'Base completa',
                      value: '${data.completeDraws ?? 0} ext.',
                      icon: Icons.fact_check_rounded,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 18),
            _OccurrenceCard(label: 'Última ocorrência', row: data.lastAny),
            const SizedBox(height: 8),
            _OccurrenceCard(label: 'Última cabeça', row: data.lastFirst),
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
              const Text(
                'Nenhuma ocorrência encontrada.',
                style: TextStyle(color: GphTheme.textSecondary),
              )
            else
              ...data.recent.map(_RecentRow.new),
            if (data.currentDelay != null) ...[
              const SizedBox(height: 10),
              const Text(
                'O atraso é somente uma medida histórica e não indica ocorrência futura.',
                style: TextStyle(color: GphTheme.textMuted, fontSize: 10),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.label, required this.value, required this.icon});

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: GphTheme.surfaceRaised,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: GphTheme.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: GphTheme.primary),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
            Text(label, style: const TextStyle(color: GphTheme.textMuted, fontSize: 10)),
          ],
        ),
      );
}

class _OccurrenceCard extends StatelessWidget {
  const _OccurrenceCard({required this.label, required this.row});

  final String label;
  final HistoryResult? row;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: GphTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: GphTheme.border),
        ),
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
      );
}

class _RecentRow extends StatelessWidget {
  const _RecentRow(this.row);

  final HistoryResult row;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 7),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
              ),
            ),
            Text(
              '${row.prize}º • ${row.thousand}',
              style: const TextStyle(color: Color(0xFF8FB7E6), fontSize: 11, fontWeight: FontWeight.w700),
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
