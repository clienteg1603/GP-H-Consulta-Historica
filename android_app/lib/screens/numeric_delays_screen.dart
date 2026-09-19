import 'package:flutter/material.dart';

import '../app_services.dart';
import '../models/number_delay_stats.dart';
import '../theme/gph_theme.dart';
import 'number_details_sheet.dart';

class NumericDelaysScreen extends StatefulWidget {
  const NumericDelaysScreen({super.key});

  @override
  State<NumericDelaysScreen> createState() => _NumericDelaysScreenState();
}

class _NumericDelaysScreenState extends State<NumericDelaysScreen> {
  NumberDelayMode _mode = NumberDelayMode.ten;
  late Future<List<NumberDelayEntry>> _ranking;
  final TextEditingController _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _reload() {
    _ranking = AppServices.history.numberDelays(_mode);
  }

  void _changeMode(NumberDelayMode mode) {
    if (_mode == mode) return;
    setState(() {
      _mode = mode;
      _search.clear();
      _reload();
    });
  }

  Future<void> _refresh() async {
    setState(_reload);
    await _ranking;
  }

  @override
  Widget build(BuildContext context) {
    final isTen = _mode == NumberDelayMode.ten;
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
                colors: [GphTheme.delaySoft, GphTheme.surfaceRaised],
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
                    color: GphTheme.delaySoft,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(
                    Icons.hourglass_bottom_rounded,
                    color: GphTheme.delay,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Atrasos numéricos',
                        style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Veja o atraso atual e toque em qualquer número para abrir sua ficha histórica.',
                        style: TextStyle(
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
          const Text('Tipo de número', style: TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _ModeButton(
                  label: 'Dezena',
                  icon: Icons.pin_rounded,
                  selected: isTen,
                  onTap: () => _changeMode(NumberDelayMode.ten),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ModeButton(
                  label: 'Centena',
                  icon: Icons.filter_3_rounded,
                  selected: !isTen,
                  onTap: () => _changeMode(NumberDelayMode.hundred),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _search,
            keyboardType: TextInputType.number,
            maxLength: isTen ? 2 : 3,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              counterText: '',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _search.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Limpar',
                      onPressed: () {
                        _search.clear();
                        setState(() {});
                      },
                      icon: const Icon(Icons.close_rounded),
                    ),
              hintText: isTen ? 'Localizar dezena, ex.: 17' : 'Localizar centena, ex.: 317',
            ),
          ),
          const SizedBox(height: 18),
          FutureBuilder<List<NumberDelayEntry>>(
            future: _ranking,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const _StatusCard(
                  text: 'Calculando atrasos numéricos...',
                  icon: Icons.hourglass_top_rounded,
                  showProgress: true,
                );
              }
              if (snapshot.hasError) {
                return const _StatusCard(
                  text: 'Não foi possível calcular os atrasos numéricos agora.',
                  icon: Icons.error_outline_rounded,
                  accent: GphTheme.danger,
                );
              }

              final all = snapshot.data ?? const <NumberDelayEntry>[];
              if (all.isEmpty) {
                return const _StatusCard(
                  text: 'Os atrasos aparecem quando a base tiver extrações completas do 1º ao 5º prêmio.',
                  icon: Icons.info_outline_rounded,
                );
              }

              final query = _search.text.trim();
              var visible = query.isEmpty
                  ? all
                  : all.where((item) => item.value.startsWith(query)).toList(growable: false);
              if (query.isEmpty && !isTen && visible.length > 100) {
                visible = visible.take(100).toList(growable: false);
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final cards = [
                        _SummaryCard(
                          label: 'Extrações completas',
                          value: '${all.first.completeDraws}',
                          icon: Icons.fact_check_rounded,
                        ),
                        _SummaryCard(
                          label: 'Maior atraso atual',
                          value: '${all.first.delay} ext.',
                          icon: Icons.hourglass_disabled_rounded,
                        ),
                      ];
                      if (constraints.maxWidth < 350) {
                        return Column(
                          children: [
                            SizedBox(width: double.infinity, child: cards[0]),
                            const SizedBox(height: 8),
                            SizedBox(width: double.infinity, child: cards[1]),
                          ],
                        );
                      }
                      return Row(
                        children: [
                          Expanded(child: cards[0]),
                          const SizedBox(width: 10),
                          Expanded(child: cards[1]),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isTen ? 'Ranking das dezenas' : 'Ranking das centenas',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    query.isNotEmpty
                        ? '${visible.length} ${visible.length == 1 ? 'número encontrado' : 'números encontrados'}.'
                        : isTen
                            ? 'As 100 dezenas aparecem em ordem de maior atraso atual.'
                            : 'Mostrando as 100 centenas mais atrasadas. Use a busca para localizar qualquer outra.',
                    style: const TextStyle(color: GphTheme.textMuted, fontSize: 11),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Atraso é apenas uma medida histórica; não indica que um número esteja prestes a sair.',
                    style: TextStyle(color: GphTheme.textMuted, fontSize: 10),
                  ),
                  const SizedBox(height: 10),
                  if (visible.isEmpty)
                    const _StatusCard(
                      text: 'Nenhum número corresponde à busca.',
                      icon: Icons.search_off_rounded,
                    )
                  else
                    ...List.generate(visible.length, (index) {
                      final item = visible[index];
                      final position = all.indexOf(item) + 1;
                      return _NumberDelayRow(
                        position: position,
                        item: item,
                        mode: _mode,
                      );
                    }),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: selected ? GphTheme.delaySoft : GphTheme.surfaceRaised,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            constraints: const BoxConstraints(minHeight: 46),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: selected ? GphTheme.delay : GphTheme.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 17,
                  color: selected ? GphTheme.delay : GphTheme.textMuted,
                ),
                const SizedBox(width: 7),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: selected ? GphTheme.textPrimary : GphTheme.textSecondary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.text,
    required this.icon,
    this.accent = GphTheme.textMuted,
    this.showProgress = false,
  });

  final String text;
  final IconData icon;
  final Color accent;
  final bool showProgress;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: GphTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: GphTheme.border),
        ),
        child: Row(
          children: [
            if (showProgress)
              const SizedBox(
                width: 19,
                height: 19,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Icon(icon, color: accent, size: 20),
            const SizedBox(width: 10),
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

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.label, required this.value, required this.icon});

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 94),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: GphTheme.delaySoft,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: GphTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 19, color: GphTheme.delay),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: GphTheme.delay,
              fontSize: 20,
              fontWeight: FontWeight.w900,
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
}

class _NumberDelayRow extends StatelessWidget {
  const _NumberDelayRow({
    required this.position,
    required this.item,
    required this.mode,
  });

  final int position;
  final NumberDelayEntry item;
  final NumberDelayMode mode;

  @override
  Widget build(BuildContext context) {
    final last = item.lastOccurrence;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => showNumberDetails(
          context,
          mode: mode == NumberDelayMode.ten ? 'Dezena' : 'Centena',
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
                  '#$position',
                  style: const TextStyle(
                    color: GphTheme.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                constraints: const BoxConstraints(minWidth: 58),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: GphTheme.delaySoft,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: GphTheme.border),
                ),
                child: Text(
                  item.value,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: GphTheme.delay,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${item.delay} extrações sem aparecer',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      last == null
                          ? 'Sem ocorrência na base completa'
                          : 'Última: ${_date(last.date)} • ${last.time} • ${last.draw} • ${last.prize}º',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: GphTheme.textMuted, fontSize: 10),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right_rounded, size: 18, color: GphTheme.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

String _date(String iso) {
  final parts = iso.split('-');
  if (parts.length != 3) return iso;
  return '${parts[2]}/${parts[1]}/${parts[0]}';
}
