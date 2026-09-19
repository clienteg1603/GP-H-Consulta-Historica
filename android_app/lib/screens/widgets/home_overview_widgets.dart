import 'package:flutter/material.dart';

import '../../data/history_repository.dart';
import '../../models/delay_summary.dart';
import '../../models/history_result.dart';
import '../../services/history_sync_service.dart';
import '../../theme/gph_theme.dart';

class HomeSectionTitle extends StatelessWidget {
  const HomeSectionTitle({super.key, required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
        ],
      );
}

class HomeSyncCard extends StatelessWidget {
  const HomeSyncCard({
    super.key,
    required this.summary,
    required this.syncing,
    required this.progress,
    required this.message,
    required this.messageIsError,
    required this.onSync,
  });

  final HistorySummary? summary;
  final bool syncing;
  final SyncProgress? progress;
  final String? message;
  final bool messageIsError;
  final VoidCallback onSync;

  @override
  Widget build(BuildContext context) {
    final empty = summary == null || summary!.isEmpty;
    final progressValue = progress == null || progress!.total <= 0
        ? null
        : progress!.current / progress!.total;

    final identity = Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: GphTheme.primarySoft,
            borderRadius: BorderRadius.circular(13),
          ),
          child: const Icon(Icons.storage_rounded, color: GphTheme.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                empty ? 'Base histórica no celular' : '${summary!.totalPrizes} prêmios salvos',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 3),
              Text(
                empty
                    ? 'Histórico do Rio de Janeiro desde 02/01/2026.'
                    : '${gphDate(summary!.firstDate)}  →  ${gphDate(summary!.lastDate)}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: GphTheme.textSecondary, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );

    final syncButton = FilledButton.tonalIcon(
      onPressed: syncing ? null : onSync,
      icon: syncing
          ? const SizedBox(
              width: 17,
              height: 17,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.sync_rounded, size: 19),
      label: Text(empty ? 'Preparar histórico' : 'Atualizar histórico'),
    );

    final messageColor = messageIsError ? GphTheme.danger : GphTheme.success;
    final messageIcon = messageIsError
        ? Icons.error_outline_rounded
        : Icons.check_circle_outline_rounded;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF122640), GphTheme.surfaceRaised],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: GphTheme.borderStrong),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 370;
              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    identity,
                    const SizedBox(height: 12),
                    syncButton,
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: identity),
                  const SizedBox(width: 10),
                  syncButton,
                ],
              );
            },
          ),
          if (syncing) ...[
            const SizedBox(height: 14),
            LinearProgressIndicator(value: progressValue),
            const SizedBox(height: 8),
            Text(
              progress == null
                  ? 'Preparando sincronização...'
                  : 'Consultando ${gphDateTime(progress!.day)} • ${progress!.current}/${progress!.total} dias • ${progress!.saved} prêmios',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: GphTheme.textSecondary, fontSize: 11),
            ),
          ],
          if (!syncing && message != null) ...[
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(messageIcon, size: 16, color: messageColor),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    message!,
                    style: TextStyle(color: messageColor, fontSize: 11, height: 1.3),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class LatestResultCard extends StatelessWidget {
  const LatestResultCard({super.key, required this.rows});

  final List<HistoryResult> rows;

  @override
  Widget build(BuildContext context) {
    final first = rows.first;
    final ordered = [...rows]..sort((a, b) => a.prize.compareTo(b.prize));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: GphTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: GphTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.emoji_events_rounded, color: GphTheme.warning, size: 21),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Último resultado',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  '${first.draw} • ${first.time}',
                  maxLines: 2,
                  textAlign: TextAlign.end,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: GphTheme.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(gphDate(first.date), style: const TextStyle(color: GphTheme.textMuted, fontSize: 11)),
          const SizedBox(height: 10),
          ...ordered.map(
            (row) => Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
              decoration: BoxDecoration(
                color: GphTheme.surfaceRaised,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 34,
                    child: Text('${row.prize}º', style: const TextStyle(color: GphTheme.textMuted, fontSize: 11)),
                  ),
                  SizedBox(
                    width: 64,
                    child: Text(row.thousand, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                  ),
                  Expanded(
                    child: Text(
                      gphTitleCase(row.animal),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                    decoration: BoxDecoration(
                      color: GphTheme.primarySoft,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'G${row.group.toString().padLeft(2, '0')}',
                      style: const TextStyle(color: GphTheme.primary, fontSize: 10, fontWeight: FontWeight.w900),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DelayStrip extends StatelessWidget {
  const DelayStrip({super.key, required this.summary});

  final DelaySummary summary;

  @override
  Widget build(BuildContext context) {
    final items = [
      ('1º–5º', summary.animalAny, Icons.pets_rounded, GphTheme.delay, GphTheme.delaySoft),
      ('Cabeça', summary.animalHead, Icons.workspace_premium_rounded, GphTheme.head, GphTheme.headSoft),
      ('Centena', summary.hundred, Icons.filter_3_rounded, GphTheme.delay, GphTheme.delaySoft),
      ('Dezena', summary.ten, Icons.pin_rounded, GphTheme.delay, GphTheme.delaySoft),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final singleColumn = constraints.maxWidth < 340;
        final width = singleColumn ? constraints.maxWidth : (constraints.maxWidth - 8) / 2;
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: items.map((item) {
            final leader = item.$2;
            final accent = item.$4;
            final background = item.$5;
            return Container(
              width: width,
              constraints: const BoxConstraints(minHeight: 82),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: GphTheme.surfaceRaised,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: GphTheme.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: background,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(item.$3, color: accent, size: 18),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.$1,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: GphTheme.textMuted,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          leader?.value ?? '—',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                        ),
                        Text(
                          leader == null ? 'Sem dados' : '${leader.delay} extrações',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: accent, fontSize: 10, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class HomeInfoCard extends StatelessWidget {
  const HomeInfoCard({
    super.key,
    required this.text,
    this.icon = Icons.info_outline_rounded,
    this.accent = GphTheme.textMuted,
  });

  final String text;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: GphTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: GphTheme.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 19, color: accent),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(color: GphTheme.textSecondary, height: 1.3),
              ),
            ),
          ],
        ),
      );
}

String gphDate(String? iso) {
  if (iso == null) return '—';
  final parts = iso.split('-');
  if (parts.length != 3) return iso;
  return '${parts[2]}/${parts[1]}/${parts[0]}';
}

String gphDateTime(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';

String gphTitleCase(String value) {
  final trimmed = value.trim().toLowerCase();
  if (trimmed.isEmpty) return value;
  return '${trimmed[0].toUpperCase()}${trimmed.substring(1)}';
}
