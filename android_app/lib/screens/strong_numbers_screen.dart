import 'package:flutter/material.dart';

import '../app_services.dart';
import '../data/animals.dart';
import '../models/animal.dart';
import '../models/strong_number_stats.dart';
import '../theme/animal_artwork.dart';
import '../theme/gph_theme.dart';
import 'number_details_sheet.dart';

class StrongNumbersScreen extends StatefulWidget {
  const StrongNumbersScreen({super.key});

  @override
  State<StrongNumbersScreen> createState() => _StrongNumbersScreenState();
}

class _StrongNumbersScreenState extends State<StrongNumbersScreen> {
  int _group = 1;
  StrongNumberKind _kind = StrongNumberKind.dozen;
  bool _firstPrizeOnly = false;
  late Future<List<StrongNumberEntry>> _ranking;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Animal get _animal => gphAnimals.firstWhere((item) => item.group == _group);

  void _reload() {
    _ranking = AppServices.history.strongNumbers(
      group: _group,
      kind: _kind,
      firstPrizeOnly: _firstPrizeOnly,
    );
  }

  void _changeGroup(int? value) {
    if (value == null || value == _group) return;
    setState(() {
      _group = value;
      _reload();
    });
  }

  void _changeKind(StrongNumberKind kind) {
    if (kind == _kind) return;
    setState(() {
      _kind = kind;
      _reload();
    });
  }

  void _changeScope(bool firstPrizeOnly) {
    if (firstPrizeOnly == _firstPrizeOnly) return;
    setState(() {
      _firstPrizeOnly = firstPrizeOnly;
      _reload();
    });
  }

  Future<void> _refresh() async {
    setState(_reload);
    await _ranking;
  }

  @override
  Widget build(BuildContext context) {
    final animal = _animal;

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
        children: [
          Container(
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
            child: const Row(
              children: [
                _HeaderIcon(),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Números fortes por bicho',
                        style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Ranking histórico por frequência. Toque em qualquer número para abrir sua ficha completa.',
                        style: TextStyle(color: GphTheme.textSecondary, fontSize: 12, height: 1.35),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<int>(
            key: ValueKey('strong-group-$_group'),
            initialValue: _group,
            isExpanded: true,
            menuMaxHeight: 420,
            decoration: const InputDecoration(
              labelText: 'Bicho',
              prefixIcon: Icon(Icons.pets_rounded),
            ),
            selectedItemBuilder: (context) => gphAnimals
                .map(
                  (item) => Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '${item.group.toString().padLeft(2, '0')} • ${item.name}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                )
                .toList(growable: false),
            items: gphAnimals
                .map(
                  (item) => DropdownMenuItem<int>(
                    value: item.group,
                    child: Row(
                      children: [
                        SizedBox(
                          width: 42,
                          child: AnimalArtwork(
                            group: item.group,
                            borderRadius: 7,
                            showGlow: false,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${item.group.toString().padLeft(2, '0')} • ${item.name}',
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.w800),
                              ),
                              Text(
                                item.dozens,
                                style: const TextStyle(color: GphTheme.textMuted, fontSize: 10),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(growable: false),
            onChanged: _changeGroup,
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: GphTheme.surface,
              borderRadius: BorderRadius.circular(17),
              border: Border.all(color: GphTheme.borderStrong),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 100,
                  child: AnimalArtwork(
                    group: animal.group,
                    borderRadius: 12,
                    showGlow: false,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        animal.name,
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Grupo ${animal.group.toString().padLeft(2, '0')}',
                        style: const TextStyle(
                          color: GphTheme.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        animal.dozens,
                        style: const TextStyle(color: GphTheme.textSecondary, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text('Prêmios considerados', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: const SizedBox(
                    width: double.infinity,
                    child: Center(child: Text('1º–5º prêmio')),
                  ),
                  selected: !_firstPrizeOnly,
                  onSelected: (_) => _changeScope(false),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ChoiceChip(
                  label: const SizedBox(
                    width: double.infinity,
                    child: Center(child: Text('Somente 1º')),
                  ),
                  selected: _firstPrizeOnly,
                  onSelected: (_) => _changeScope(true),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Tipo de número', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: StrongNumberKind.values
                .map(
                  (kind) => ChoiceChip(
                    avatar: Icon(
                      _kindIcon(kind),
                      size: 16,
                      color: _kind == kind ? GphTheme.primary : GphTheme.textMuted,
                    ),
                    label: Text(kind.label),
                    selected: _kind == kind,
                    onSelected: (_) => _changeKind(kind),
                  ),
                )
                .toList(growable: false),
          ),
          const SizedBox(height: 20),
          FutureBuilder<List<StrongNumberEntry>>(
            future: _ranking,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const _LoadingBlock();
              }
              if (snapshot.hasError) {
                return const _MessageCard(
                  text: 'Não foi possível calcular este ranking agora.',
                );
              }
              final rows = snapshot.data ?? const <StrongNumberEntry>[];
              if (rows.isEmpty) {
                return const _MessageCard(
                  text: 'Ainda não há ocorrências suficientes deste bicho neste recorte.',
                );
              }
              return _RankingPanel(
                rows: rows,
                kind: _kind,
                firstPrizeOnly: _firstPrizeOnly,
              );
            },
          ),
        ],
      ),
    );
  }

  static IconData _kindIcon(StrongNumberKind kind) {
    switch (kind) {
      case StrongNumberKind.dozen:
        return Icons.pin_rounded;
      case StrongNumberKind.hundred:
        return Icons.filter_3_rounded;
      case StrongNumberKind.thousand:
        return Icons.numbers_rounded;
    }
  }
}

class _HeaderIcon extends StatelessWidget {
  const _HeaderIcon();

  @override
  Widget build(BuildContext context) => Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: GphTheme.primarySoft,
          borderRadius: BorderRadius.circular(13),
        ),
        child: const Icon(Icons.numbers_rounded, color: GphTheme.primary, size: 25),
      );
}

class _RankingPanel extends StatelessWidget {
  const _RankingPanel({
    required this.rows,
    required this.kind,
    required this.firstPrizeOnly,
  });

  final List<StrongNumberEntry> rows;
  final StrongNumberKind kind;
  final bool firstPrizeOnly;

  @override
  Widget build(BuildContext context) {
    final totalOccurrences = rows.fold<int>(0, (sum, item) => sum + item.count);
    final limit = kind == StrongNumberKind.dozen ? rows.length : 50;
    final shown = rows.take(limit).toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                value: '$totalOccurrences',
                label: firstPrizeOnly ? 'cabeças do bicho' : 'aparições do bicho',
                icon: firstPrizeOnly
                    ? Icons.workspace_premium_rounded
                    : Icons.receipt_long_rounded,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SummaryCard(
                value: '${rows.length}',
                label: '${kind.label.toLowerCase()} diferentes',
                icon: Icons.format_list_numbered_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Text(
                'Ranking de ${kind.label.toLowerCase()}',
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
              ),
            ),
            if (rows.length > shown.length)
              Text(
                'Top ${shown.length} de ${rows.length}',
                style: const TextStyle(color: GphTheme.textMuted, fontSize: 11),
              ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'Frequência, recência e histórico são descritivos. Toque numa linha para ver ocorrências e detalhes.',
          style: TextStyle(color: GphTheme.textMuted, fontSize: 10, height: 1.3),
        ),
        const SizedBox(height: 10),
        ...List.generate(
          shown.length,
          (index) => _NumberRow(
            position: index + 1,
            item: shown[index],
            kind: kind,
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.value, required this.label, required this.icon});

  final String value;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: GphTheme.surfaceRaised,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: GphTheme.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 19, color: GphTheme.primary),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(color: GphTheme.textMuted, fontSize: 10)),
          ],
        ),
      );
}

class _NumberRow extends StatelessWidget {
  const _NumberRow({
    required this.position,
    required this.item,
    required this.kind,
  });

  final int position;
  final StrongNumberEntry item;
  final StrongNumberKind kind;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: () => showNumberDetails(
          context,
          mode: _modeForKind(kind),
          value: item.value,
        ),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            color: GphTheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: GphTheme.border),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 34,
                child: Text(
                  '$positionº',
                  style: const TextStyle(color: GphTheme.textMuted, fontWeight: FontWeight.w800),
                ),
              ),
              Container(
                constraints: const BoxConstraints(minWidth: 62),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: GphTheme.primarySoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  item.value,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFFD7E9FF),
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Última: ${_date(item.lastDate)} • ${item.lastTime}',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${item.lastDraw} • ${item.lastPrize}º prêmio',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: GphTheme.textMuted, fontSize: 10),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${item.count}x',
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17),
                  ),
                  const Text(
                    'ocorrências',
                    style: TextStyle(color: GphTheme.primary, fontSize: 9),
                  ),
                ],
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right_rounded, size: 18, color: GphTheme.textMuted),
            ],
          ),
        ),
      );
}

class _LoadingBlock extends StatelessWidget {
  const _LoadingBlock();

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.all(28),
        child: Center(
          child: Column(
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 10),
              Text('Calculando ranking...', style: TextStyle(color: GphTheme.textSecondary)),
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

String _modeForKind(StrongNumberKind kind) {
  switch (kind) {
    case StrongNumberKind.dozen:
      return 'Dezena';
    case StrongNumberKind.hundred:
      return 'Centena';
    case StrongNumberKind.thousand:
      return 'Milhar';
  }
}

String _date(String iso) {
  final parts = iso.split('-');
  if (parts.length != 3) return iso;
  return '${parts[2]}/${parts[1]}/${parts[0]}';
}
