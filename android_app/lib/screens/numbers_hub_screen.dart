import 'package:flutter/material.dart';

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
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          child: Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: const SizedBox(
                    width: double.infinity,
                    child: Center(child: Text('Fortes por bicho')),
                  ),
                  selected: _view == _NumbersView.strong,
                  onSelected: (_) => setState(() => _view = _NumbersView.strong),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ChoiceChip(
                  label: const SizedBox(
                    width: double.infinity,
                    child: Center(child: Text('Mais atrasados')),
                  ),
                  selected: _view == _NumbersView.delayed,
                  onSelected: (_) => setState(() => _view = _NumbersView.delayed),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: IndexedStack(
            index: _view == _NumbersView.strong ? 0 : 1,
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
