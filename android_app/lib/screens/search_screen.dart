import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_services.dart';
import '../data/animals.dart';
import '../models/history_result.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  String _mode = 'Bicho';
  final TextEditingController _queryController = TextEditingController();
  DateTime? _start;
  DateTime? _end;
  int? _prize;
  String? _draw;
  bool _loading = false;
  List<HistoryResult>? _results;
  String? _error;
  late Future<List<String>> _drawOptions;

  @override
  void initState() {
    super.initState();
    _drawOptions = AppServices.history.availableDraws();
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  void _changeMode(String mode) {
    setState(() {
      _mode = mode;
      _queryController.clear();
      _results = null;
      _error = null;
    });
  }

  Future<void> _pickPeriod() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2026, 1, 2),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDateRange: _start != null && _end != null
          ? DateTimeRange(start: _start!, end: _end!)
          : null,
    );
    if (range != null) {
      setState(() {
        _start = range.start;
        _end = range.end;
      });
    }
  }

  Future<void> _search() async {
    final query = _queryController.text.trim();
    if (query.isEmpty) {
      setState(() => _error = 'Escolha ou digite um valor para pesquisar.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rows = await AppServices.history.search(
        mode: _mode,
        query: query,
        start: _start,
        end: _end,
        prize: _prize,
        draw: _draw,
      );
      if (!mounted) return;
      setState(() => _results = rows);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Não foi possível executar a pesquisa.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _clearFilters() {
    setState(() {
      _start = null;
      _end = null;
      _prize = null;
      _draw = null;
      _results = null;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    const modes = ['Bicho', 'Grupo', 'Dezena', 'Centena', 'Milhar'];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        const Text(
          'Pesquisa histórica',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 5),
        const Text(
          'Procure na base do aparelho e refine por período, prêmio e sorteio.',
          style: TextStyle(color: Color(0xFF9FB0C5)),
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: modes.map((mode) {
            return ChoiceChip(
              label: Text(mode),
              selected: _mode == mode,
              onSelected: (_) => _changeMode(mode),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        if (_mode == 'Bicho')
          DropdownButtonFormField<String>(
            key: ValueKey('animal-${_queryController.text}'),
            initialValue: _queryController.text.isEmpty ? null : _queryController.text,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Bicho',
              prefixIcon: Icon(Icons.pets_rounded),
            ),
            hint: const Text('Escolha um bicho'),
            items: gphAnimals
                .map(
                  (animal) => DropdownMenuItem<String>(
                    value: animal.name,
                    child: Text(
                      '${animal.group.toString().padLeft(2, '0')} • ${animal.name}',
                    ),
                  ),
                )
                .toList(),
            onChanged: (value) {
              setState(() {
                _queryController.text = value ?? '';
                _results = null;
                _error = null;
              });
            },
          )
        else
          TextField(
            controller: _queryController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _search(),
            decoration: InputDecoration(
              labelText: 'Pesquisar por $_mode',
              hintText: _hintForMode(_mode),
              prefixIcon: const Icon(Icons.search_rounded),
              counterText: '',
            ),
            maxLength: _maxLengthForMode(_mode),
          ),
        const SizedBox(height: 14),
        _FilterCard(
          prize: _prize,
          draw: _draw,
          drawOptions: _drawOptions,
          periodLabel: _periodLabel(),
          hasPeriod: _start != null || _end != null,
          onPrizeChanged: (value) => setState(() => _prize = value),
          onDrawChanged: (value) => setState(() => _draw = value),
          onPickPeriod: _pickPeriod,
          onClear: _clearFilters,
        ),
        const SizedBox(height: 14),
        FilledButton.icon(
          onPressed: _loading ? null : _search,
          icon: _loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.manage_search_rounded),
          label: Text(_loading ? 'Pesquisando...' : 'Pesquisar'),
        ),
        if (_error != null) ...[
          const SizedBox(height: 10),
          Text(_error!, style: const TextStyle(color: Color(0xFFFCA5A5))),
        ],
        const SizedBox(height: 22),
        _ResultsPanel(results: _results),
      ],
    );
  }

  String _periodLabel() {
    if (_start == null || _end == null) return 'Qualquer período';
    return '${_formatDate(_start!)} a ${_formatDate(_end!)}';
  }

  String _formatDate(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';

  String _hintForMode(String mode) {
    switch (mode) {
      case 'Grupo':
        return 'Ex.: 14';
      case 'Dezena':
        return 'Ex.: 54';
      case 'Centena':
        return 'Ex.: 254';
      case 'Milhar':
        return 'Ex.: 1254';
      default:
        return '';
    }
  }

  int _maxLengthForMode(String mode) {
    switch (mode) {
      case 'Grupo':
      case 'Dezena':
        return 2;
      case 'Centena':
        return 3;
      case 'Milhar':
        return 4;
      default:
        return 32;
    }
  }
}

class _FilterCard extends StatelessWidget {
  const _FilterCard({
    required this.prize,
    required this.draw,
    required this.drawOptions,
    required this.periodLabel,
    required this.hasPeriod,
    required this.onPrizeChanged,
    required this.onDrawChanged,
    required this.onPickPeriod,
    required this.onClear,
  });

  final int? prize;
  final String? draw;
  final Future<List<String>> drawOptions;
  final String periodLabel;
  final bool hasPeriod;
  final ValueChanged<int?> onPrizeChanged;
  final ValueChanged<String?> onDrawChanged;
  final VoidCallback onPickPeriod;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1523),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1C2B41)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.tune_rounded, color: Color(0xFF60A5FA), size: 20),
              const SizedBox(width: 7),
              const Expanded(
                child: Text('Filtros', style: TextStyle(fontWeight: FontWeight.w900)),
              ),
              TextButton(onPressed: onClear, child: const Text('Limpar')),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  key: ValueKey('prize-$prize'),
                  initialValue: prize,
                  decoration: const InputDecoration(labelText: 'Prêmio'),
                  items: const [
                    DropdownMenuItem<int>(value: null, child: Text('Todos')),
                    DropdownMenuItem(value: 1, child: Text('1º prêmio')),
                    DropdownMenuItem(value: 2, child: Text('2º prêmio')),
                    DropdownMenuItem(value: 3, child: Text('3º prêmio')),
                    DropdownMenuItem(value: 4, child: Text('4º prêmio')),
                    DropdownMenuItem(value: 5, child: Text('5º prêmio')),
                  ],
                  onChanged: onPrizeChanged,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FutureBuilder<List<String>>(
                  future: drawOptions,
                  builder: (context, snapshot) {
                    final options = snapshot.data ?? const <String>[];
                    final selected = draw != null && options.contains(draw) ? draw : null;
                    return DropdownButtonFormField<String>(
                      key: ValueKey('draw-${draw ?? ''}'),
                      initialValue: selected,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Sorteio'),
                      items: [
                        const DropdownMenuItem<String>(
                          value: '',
                          child: Text('Todos'),
                        ),
                        ...options.map(
                          (value) => DropdownMenuItem<String>(
                            value: value,
                            child: Text(value, overflow: TextOverflow.ellipsis),
                          ),
                        ),
                      ],
                      onChanged: (value) => onDrawChanged(
                        value == null || value.isEmpty ? null : value,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onPickPeriod,
              icon: Icon(hasPeriod ? Icons.event_available_rounded : Icons.date_range_rounded),
              label: Text(periodLabel),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultsPanel extends StatelessWidget {
  const _ResultsPanel({required this.results});

  final List<HistoryResult>? results;

  @override
  Widget build(BuildContext context) {
    final rows = results;
    if (rows == null) return _box('Faça uma consulta para ver as ocorrências.');
    if (rows.isEmpty) return _box('Nenhuma ocorrência encontrada com esses filtros.');

    final grouped = <String, List<HistoryResult>>{};
    for (final row in rows) {
      final key = '${row.date}|${row.time}|${row.draw}';
      grouped.putIfAbsent(key, () => []).add(row);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '${rows.length} ocorrência${rows.length == 1 ? '' : 's'} em ${grouped.length} extração${grouped.length == 1 ? '' : 'ões'}',
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
              ),
            ),
            if (rows.length >= 250)
              const Text(
                'limite 250',
                style: TextStyle(color: Color(0xFF7F94AD), fontSize: 11),
              ),
          ],
        ),
        const SizedBox(height: 10),
        ...grouped.values.map(
          (group) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _ResultDrawCard(rows: group),
          ),
        ),
      ],
    );
  }

  Widget _box(String text) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF0B1523),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF1C2B41)),
        ),
        child: Text(text, style: const TextStyle(color: Color(0xFF879BB4))),
      );
}

class _ResultDrawCard extends StatelessWidget {
  const _ResultDrawCard({required this.rows});

  final List<HistoryResult> rows;

  @override
  Widget build(BuildContext context) {
    final ordered = [...rows]..sort((a, b) => a.prize.compareTo(b.prize));
    final first = ordered.first;
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
          Row(
            children: [
              Text(
                _date(first.date),
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              const SizedBox(width: 8),
              Text(first.time, style: const TextStyle(color: Color(0xFFB9CBE0))),
              const Spacer(),
              Flexible(
                child: Text(
                  first.draw,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Color(0xFF7DB6FF), fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...ordered.map(
            (row) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  SizedBox(
                    width: 32,
                    child: Text('${row.prize}º', style: const TextStyle(color: Color(0xFF7F94AD))),
                  ),
                  SizedBox(
                    width: 58,
                    child: Text(row.thousand, style: const TextStyle(fontWeight: FontWeight.w900)),
                  ),
                  Expanded(
                    child: Text(row.animal, overflow: TextOverflow.ellipsis),
                  ),
                  Text(
                    'G${row.group.toString().padLeft(2, '0')}',
                    style: const TextStyle(color: Color(0xFF9FB0C5)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _date(String iso) {
    final parts = iso.split('-');
    if (parts.length != 3) return iso;
    return '${parts[2]}/${parts[1]}/${parts[0]}';
  }
}
