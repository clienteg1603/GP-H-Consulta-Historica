import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_services.dart';
import '../data/animals.dart';
import '../models/animal.dart';
import '../models/history_result.dart';
import '../theme/animal_artwork.dart';
import '../theme/gph_theme.dart';

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

  void _clearResultState() {
    _results = null;
    _error = null;
  }

  void _changeMode(String mode) {
    if (_mode == mode) return;
    setState(() {
      _mode = mode;
      _queryController.clear();
      _clearResultState();
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
    if (range != null && mounted) {
      setState(() {
        _start = range.start;
        _end = range.end;
        _clearResultState();
      });
    }
  }

  void _changePrize(int? value) {
    setState(() {
      _prize = value;
      _clearResultState();
    });
  }

  void _changeDraw(String? value) {
    setState(() {
      _draw = value;
      _clearResultState();
    });
  }

  Future<void> _search() async {
    final query = _queryController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _results = null;
        _error = 'Escolha ou digite um valor para pesquisar.';
      });
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
      setState(() {
        _results = null;
        _error = 'Não foi possível executar a pesquisa.';
      });
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
      _clearResultState();
    });
  }

  Animal? _selectedAnimal() {
    if (_mode != 'Bicho' || _queryController.text.isEmpty) return null;
    for (final animal in gphAnimals) {
      if (animal.name == _queryController.text) return animal;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    const modes = ['Bicho', 'Grupo', 'Dezena', 'Centena', 'Milhar'];
    final selectedAnimal = _selectedAnimal();

    return ListView(
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
                      'Pesquisa histórica',
                      style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Encontre uma ocorrência e refine por período, prêmio e sorteio.',
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
        const SizedBox(height: 18),
        const Text(
          'O que você quer procurar?',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
        ),
        const SizedBox(height: 9),
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: modes.map((mode) {
            return _ModeChoice(
              label: mode,
              icon: _iconForMode(mode),
              selected: _mode == mode,
              onTap: () => _changeMode(mode),
            );
          }).toList(growable: false),
        ),
        const SizedBox(height: 15),
        if (_mode == 'Bicho')
          DropdownButtonFormField<String>(
            key: ValueKey('animal-${_queryController.text}'),
            initialValue: _queryController.text.isEmpty ? null : _queryController.text,
            isExpanded: true,
            menuMaxHeight: 420,
            decoration: const InputDecoration(
              labelText: 'Bicho',
              prefixIcon: Icon(Icons.pets_rounded),
            ),
            hint: const Text('Escolha um dos 25 bichos'),
            selectedItemBuilder: (context) => gphAnimals
                .map(
                  (animal) => Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '${animal.group.toString().padLeft(2, '0')} • ${animal.name}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                )
                .toList(growable: false),
            items: gphAnimals
                .map(
                  (animal) => DropdownMenuItem<String>(
                    value: animal.name,
                    child: Row(
                      children: [
                        SizedBox(
                          width: 42,
                          child: AnimalArtwork(
                            group: animal.group,
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
                                '${animal.group.toString().padLeft(2, '0')} • ${animal.name}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.w800),
                              ),
                              Text(
                                animal.dozens,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: GphTheme.textMuted,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(growable: false),
            onChanged: (value) {
              setState(() {
                _queryController.text = value ?? '';
                _clearResultState();
              });
            },
          )
        else
          TextField(
            controller: _queryController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            textInputAction: TextInputAction.search,
            onChanged: (_) {
              setState(_clearResultState);
            },
            onSubmitted: (_) => _search(),
            decoration: InputDecoration(
              labelText: 'Pesquisar por $_mode',
              hintText: _hintForMode(_mode),
              prefixIcon: Icon(_iconForMode(_mode)),
              counterText: '',
              suffixIcon: _queryController.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Limpar número',
                      onPressed: () {
                        setState(() {
                          _queryController.clear();
                          _clearResultState();
                        });
                      },
                      icon: const Icon(Icons.close_rounded),
                    ),
            ),
            maxLength: _maxLengthForMode(_mode),
          ),
        if (selectedAnimal != null) ...[
          const SizedBox(height: 10),
          _AnimalSelectionCard(animal: selectedAnimal),
        ],
        const SizedBox(height: 14),
        _FilterCard(
          prize: _prize,
          draw: _draw,
          drawOptions: _drawOptions,
          periodLabel: _periodLabel(),
          hasPeriod: _start != null || _end != null,
          onPrizeChanged: _changePrize,
          onDrawChanged: _changeDraw,
          onPickPeriod: _pickPeriod,
          onClear: _clearFilters,
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 50,
          child: FilledButton.icon(
            onPressed: _loading ? null : _search,
            icon: _loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.manage_search_rounded),
            label: Text(_loading ? 'Pesquisando...' : 'Pesquisar na base'),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 10),
          _StatusCard(
            text: _error!,
            icon: Icons.error_outline_rounded,
            accent: GphTheme.danger,
          ),
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

  static IconData _iconForMode(String mode) {
    switch (mode) {
      case 'Bicho':
        return Icons.pets_rounded;
      case 'Grupo':
        return Icons.grid_view_rounded;
      case 'Dezena':
        return Icons.pin_rounded;
      case 'Centena':
        return Icons.filter_3_rounded;
      case 'Milhar':
        return Icons.numbers_rounded;
      default:
        return Icons.search_rounded;
    }
  }
}

class _ModeChoice extends StatelessWidget {
  const _ModeChoice({
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
        color: selected ? GphTheme.primarySoft : GphTheme.surfaceRaised,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            constraints: const BoxConstraints(minHeight: 44),
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: selected ? GphTheme.primary : GphTheme.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: selected ? GphTheme.primary : GphTheme.textMuted,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    color: selected ? GphTheme.textPrimary : GphTheme.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
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
        child: const Icon(Icons.manage_search_rounded, color: GphTheme.primary, size: 25),
      );
}

class _AnimalSelectionCard extends StatelessWidget {
  const _AnimalSelectionCard({required this.animal});

  final Animal animal;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: GphTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: GphTheme.borderStrong),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 320;
            final art = SizedBox(
              width: compact ? 78 : 92,
              child: AnimalArtwork(
                group: animal.group,
                borderRadius: 11,
                showGlow: false,
              ),
            );
            final info = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  animal.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 2),
                Text(
                  'Grupo ${animal.group.toString().padLeft(2, '0')}',
                  style: const TextStyle(
                    color: GphTheme.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  animal.dozens,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: GphTheme.textSecondary, fontSize: 11),
                ),
              ],
            );

            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [art, const SizedBox(height: 8), info],
              );
            }
            return Row(
              children: [
                art,
                const SizedBox(width: 12),
                Expanded(child: info),
              ],
            );
          },
        ),
      );
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
    final prizeField = DropdownButtonFormField<int>(
      key: ValueKey('prize-$prize'),
      initialValue: prize,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Prêmio',
        prefixIcon: Icon(Icons.emoji_events_outlined),
      ),
      items: const [
        DropdownMenuItem<int>(value: null, child: Text('Todos')),
        DropdownMenuItem(value: 1, child: Text('1º prêmio')),
        DropdownMenuItem(value: 2, child: Text('2º prêmio')),
        DropdownMenuItem(value: 3, child: Text('3º prêmio')),
        DropdownMenuItem(value: 4, child: Text('4º prêmio')),
        DropdownMenuItem(value: 5, child: Text('5º prêmio')),
      ],
      onChanged: onPrizeChanged,
    );

    final drawField = FutureBuilder<List<String>>(
      future: drawOptions,
      builder: (context, snapshot) {
        final options = snapshot.data ?? const <String>[];
        final selected = draw != null && options.contains(draw) ? draw : null;
        return DropdownButtonFormField<String>(
          key: ValueKey('draw-${draw ?? ''}'),
          initialValue: selected,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: 'Sorteio',
            prefixIcon: const Icon(Icons.schedule_rounded),
            helperText: snapshot.hasError ? 'Lista indisponível' : null,
            helperStyle: const TextStyle(color: GphTheme.danger, fontSize: 9),
          ),
          items: [
            const DropdownMenuItem<String>(value: '', child: Text('Todos')),
            ...options.map(
              (value) => DropdownMenuItem<String>(
                value: value,
                child: Text(value, maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ),
          ],
          onChanged: snapshot.hasError
              ? null
              : (value) => onDrawChanged(value == null || value.isEmpty ? null : value),
        );
      },
    );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: GphTheme.surface,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: GphTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: GphTheme.primarySoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.tune_rounded, color: GphTheme.primary, size: 18),
              ),
              const SizedBox(width: 9),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Filtros', style: TextStyle(fontWeight: FontWeight.w900)),
                    Text('Opcionais', style: TextStyle(color: GphTheme.textMuted, fontSize: 10)),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: onClear,
                icon: const Icon(Icons.restart_alt_rounded, size: 17),
                label: const Text('Limpar'),
              ),
            ],
          ),
          const SizedBox(height: 11),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 410) {
                return Column(
                  children: [
                    prizeField,
                    const SizedBox(height: 10),
                    drawField,
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: prizeField),
                  const SizedBox(width: 10),
                  Expanded(child: drawField),
                ],
              );
            },
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onPickPeriod,
              icon: Icon(hasPeriod ? Icons.event_available_rounded : Icons.date_range_rounded),
              label: Text(periodLabel, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.text,
    required this.icon,
    this.accent = GphTheme.textMuted,
  });

  final String text;
  final IconData icon;
  final Color accent;

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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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

class _ResultsPanel extends StatelessWidget {
  const _ResultsPanel({required this.results});

  final List<HistoryResult>? results;

  @override
  Widget build(BuildContext context) {
    final rows = results;
    if (rows == null) {
      return const _StatusCard(
        text: 'Faça uma consulta para ver as ocorrências.',
        icon: Icons.search_rounded,
      );
    }
    if (rows.isEmpty) {
      return const _StatusCard(
        text: 'Nenhuma ocorrência encontrada com esses filtros.',
        icon: Icons.search_off_rounded,
      );
    }

    final grouped = <String, List<HistoryResult>>{};
    for (final row in rows) {
      final key = '${row.date}|${row.time}|${row.draw}';
      grouped.putIfAbsent(key, () => []).add(row);
    }

    final occurrenceLabel = rows.length == 1 ? 'ocorrência' : 'ocorrências';
    final drawLabel = grouped.length == 1 ? 'extração' : 'extrações';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: GphTheme.primarySoft,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.history_rounded, size: 18, color: GphTheme.primary),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                '${rows.length} $occurrenceLabel em ${grouped.length} $drawLabel',
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
              ),
            ),
            if (rows.length >= 250) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                decoration: BoxDecoration(
                  color: GphTheme.surfaceRaised,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'limite 250',
                  style: TextStyle(color: GphTheme.textMuted, fontSize: 10),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 11),
        ...grouped.values.map(
          (group) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _ResultDrawCard(rows: group),
          ),
        ),
      ],
    );
  }
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
        color: GphTheme.surfaceRaised,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: GphTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 5,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(_date(first.date), style: const TextStyle(fontWeight: FontWeight.w900)),
              Text(first.time, style: const TextStyle(color: GphTheme.textSecondary)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                decoration: BoxDecoration(
                  color: GphTheme.primarySoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  first.draw,
                  style: const TextStyle(
                    color: GphTheme.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...ordered.map(
            (row) => Container(
              margin: const EdgeInsets.only(bottom: 5),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(
                color: GphTheme.surface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 32,
                    child: Text('${row.prize}º', style: const TextStyle(color: GphTheme.textMuted)),
                  ),
                  SizedBox(
                    width: 58,
                    child: Text(row.thousand, style: const TextStyle(fontWeight: FontWeight.w900)),
                  ),
                  Expanded(
                    child: Text(
                      _titleCase(row.animal),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: GphTheme.primarySoft,
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Text(
                      'G${row.group.toString().padLeft(2, '0')}',
                      style: const TextStyle(
                        color: GphTheme.primary,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
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

String _date(String iso) {
  final parts = iso.split('-');
  if (parts.length != 3) return iso;
  return '${parts[2]}/${parts[1]}/${parts[0]}';
}

String _titleCase(String value) {
  final trimmed = value.trim().toLowerCase();
  if (trimmed.isEmpty) return value;
  return '${trimmed[0].toUpperCase()}${trimmed.substring(1)}';
}
