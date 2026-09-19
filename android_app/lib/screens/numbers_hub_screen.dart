import 'package:flutter/material.dart';

import '../theme/gph_theme.dart';
import 'numeric_delays_screen.dart';
import 'strong_numbers_screen.dart';

enum _NumbersView { strong, delayed }

class NumbersHubScreen extends StatefulWidget {
  const NumbersHubScreen({super.key});

  @override
  State<NumbersHubScreen> createState() => _NumbersHubScreenState();
}

class _NumbersHubScreenState extends State<NumbersHubScreen> {
  _NumbersView _view = _NumbersView.strong;

  @override
  Widget build(BuildContext context) {
    final strong = _view == _NumbersView.strong;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: GphTheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: GphTheme.border),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _ModeButton(
                        icon: Icons.auto_graph_rounded,
                        label: 'Fortes por bicho',
                        selected: strong,
                        onTap: () => setState(() => _view = _NumbersView.strong),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: _ModeButton(
                        icon: Icons.hourglass_bottom_rounded,
                        label: 'Mais atrasados',
                        selected: !strong,
                        onTap: () => setState(() => _view = _NumbersView.delayed),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 9),
              Row(
                children: [
                  Icon(
                    strong ? Icons.info_outline_rounded : Icons.schedule_rounded,
                    size: 15,
                    color: GphTheme.textMuted,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      strong
                          ? 'Consulte dezenas, centenas e milhares com maior presença histórica em cada bicho.'
                          : 'Veja dezenas e centenas ordenadas pelo atraso atual na base histórica.',
                      style: const TextStyle(color: GphTheme.textMuted, fontSize: 11, height: 1.3),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: IndexedStack(
            index: strong ? 0 : 1,
            children: const [
              StrongNumbersScreen(),
              NumericDelaysScreen(),
            ],
          ),
        ),
      ],
    );
  }
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: selected ? GphTheme.primarySoft : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: selected ? GphTheme.primary : GphTheme.textMuted,
                ),
                const SizedBox(width: 7),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: selected ? GphTheme.textPrimary : GphTheme.textSecondary,
                      fontSize: 12,
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
