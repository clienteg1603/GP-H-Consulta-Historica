import 'package:flutter/material.dart';

import '../app_services.dart';
import '../models/number_delay_stats.dart';
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
                colors: [Color(0xFF13213A), Color(0xFF0A1625)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFF274466)),
            ),
            child: const Row(
              children: [
                Icon(Icons.hourglass_bottom_rounded, color: Color(0xFF7DB6FF), size: 30),
                SizedBox(width: 12),
                Expanded(
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
                        style: TextStyle(color: Color(0xFF9FB0C5), fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text('Tipo de número', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: const SizedBox(
                    width: double.infinity,
                    child: Center(child: Text('Dezena')),
                  ),
                  selected: isTen,
                  onSelected: (_) => _changeMode(NumberDelayMode.ten),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ChoiceChip(
                  label: const SizedBox(
                    width: double.infinity,
                    child: Center(child: Text('Centena')),
                  ),
                  selected: !isTen,
                  onSelected: (_) => _changeMode(NumberDelayMode.hundred),
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
                return const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (snapshot.hasError) {
                return _message('Não foi possível calcular os atrasos numéricos agora.');
              }

              final all = snapshot.data ?? const <NumberDelayEntry>[];
              if (all.isEmpty) {
                return _message(
                  'Os atrasos aparecem quando a base tiver extrações completas do 1º ao 5º prêmio.',
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
                  Row(
                    children: [
                      Expanded(
                        child: _SummaryCard(
                          label: 'Extrações completas',
                          value: '${all.first.completeDraws}',
                          icon: Icons.fact_check_rounded,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _SummaryCard(
                          label: 'Maior atraso atual',
                          value: '${all.first.delay} ext.',
                          icon: Icons.hourglass_disabled_rounded,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isTen ? 'Ranking das dezenas' : 'Ranking das centenas',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    query.isNotEmpty
                        ? '${visible.length} número(s) encontrado(s).'
                        : isTen
                            ? 'As 100 dezenas aparecem em ordem de maior atraso atual.'
                            : 'Mostrando as 100 centenas mais atrasadas. Use a busca para localizar qualquer outra.',
                    style: const TextStyle(color: Color(0xFF7F94AD), fontSize: 11),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Atraso é apenas uma medida histórica; não indica que um número esteja prestes a sair.',
                    style: TextStyle(color: Color(0xFF657D98), fontSize: 10),
                  ),
                  const SizedBox(height: 10),
                  if (visible.isEmpty)
                    _message('Nenhum número corresponde à busca.')
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

  Widget _message(String text) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF0B1523),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF1C2B41)),
        ),
        child: Text(text, style: const TextStyle(color: Color(0xFF9FB0C5))),
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
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1726),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFF1C2B41)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 19, color: const Color(0xFF79B4FF)),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: Color(0xFF8296AD), fontSize: 10)),
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
    return InkWell(
      onTap: () => showNumberDetails(
        context,
        mode: mode == NumberDelayMode.ten ? 'Dezena' : 'Centena',
        value: item.value,
      ),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF0B1523),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF182A40)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 34,
              child: Text(
                '#$position',
                style: const TextStyle(color: Color(0xFF657D98), fontSize: 11, fontWeight: FontWeight.w800),
              ),
            ),
            Container(
              constraints: const BoxConstraints(minWidth: 58),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFF12243A),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF244767)),
              ),
              child: Text(
                item.value,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1.0),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${item.delay} extrações sem aparecer',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    last == null
                        ? 'Sem ocorrência na base completa'
                        : 'Última: ${_date(last.date)} • ${last.time} • ${last.draw} • ${last.prize}º',
                    style: const TextStyle(color: Color(0xFF71869F), fontSize: 10),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFF536B85)),
          ],
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
