import 'package:flutter/material.dart';

import '../app_services.dart';
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
  bool _loading = false;
  List<HistoryResult>? _results;
  String? _error;

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
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
      setState(() => _error = 'Digite um valor para pesquisar.');
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

  @override
  Widget build(BuildContext context) {
    const modes = ['Bicho', 'Grupo', 'Dezena', 'Centena', 'Milhar'];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        const Text('Pesquisa histórica', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
        const SizedBox(height: 5),
        const Text('Consulta diretamente a base SQLite salva no aparelho.', style: TextStyle(color: Color(0xFF9FB0C5))),
        const SizedBox(height: 18),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: modes.map((mode) {
            return ChoiceChip(
              label: Text(mode),
              selected: _mode == mode,
              onSelected: (_) => setState(() => _mode = mode),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _queryController,
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => _search(),
          decoration: InputDecoration(
            labelText: 'Pesquisar por $_mode',
            hintText: _hintForMode(_mode),
            prefixIcon: const Icon(Icons.search_rounded),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _pickPeriod,
          icon: const Icon(Icons.date_range_rounded),
          label: Text(_periodLabel()),
        ),
        if (_start != null || _end != null)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => setState(() {
                _start = null;
                _end = null;
              }),
              child: const Text('Limpar período'),
            ),
          ),
        const SizedBox(height: 6),
        FilledButton.icon(
          onPressed: _loading ? null : _search,
          icon: _loading
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.manage_search_rounded),
          label: Text(_loading ? 'Pesquisando...' : 'Pesquisar'),
        ),
        if (_error != null) ...[
          const SizedBox(height: 10),
          Text(_error!, style: const TextStyle(color: Color(0xFFFCA5A5))),
        ],
        const SizedBox(height: 24),
        _ResultsPanel(results: _results),
      ],
    );
  }

  String _periodLabel() {
    if (_start == null || _end == null) return 'Selecionar período';
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
        return 'Ex.: Gato';
    }
  }
}

class _ResultsPanel extends StatelessWidget {
  const _ResultsPanel({required this.results});

  final List<HistoryResult>? results;

  @override
  Widget build(BuildContext context) {
    final rows = results;
    if (rows == null) return _box('Nenhuma consulta executada ainda.');
    if (rows.isEmpty) return _box('Nenhuma ocorrência encontrada.');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${rows.length} ocorrência(s)', style: const TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        ...rows.take(100).map(
          (row) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF0B1523),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF1C2B41)),
            ),
            child: Row(
              children: [
                SizedBox(width: 82, child: Text(_date(row.date), style: const TextStyle(color: Color(0xFF9FB0C5)))),
                SizedBox(width: 48, child: Text(row.time)),
                SizedBox(width: 34, child: Text('${row.prize}º')),
                SizedBox(width: 56, child: Text(row.thousand, style: const TextStyle(fontWeight: FontWeight.w900))),
                Expanded(child: Text(row.animal, overflow: TextOverflow.ellipsis)),
              ],
            ),
          ),
        ),
        if (rows.length > 100)
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Text('Exibindo as 100 ocorrências mais recentes.', style: TextStyle(color: Color(0xFF7F94AD))),
          ),
      ],
    );
  }

  Widget _box(String text) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF0B1523),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF1C2B41)),
        ),
        child: Text(text, style: const TextStyle(color: Color(0xFF879BB4))),
      );

  String _date(String iso) {
    final parts = iso.split('-');
    if (parts.length != 3) return iso;
    return '${parts[2]}/${parts[1]}/${parts[0]}';
  }
}
