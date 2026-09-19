import 'package:flutter/material.dart';

import 'gph_theme.dart';

/// Ilustração visual dos 25 grupos.
///
/// A Alpha 14 deixa de depender de uma folha de imagem externa/embutida para
/// evitar falhas de decodificação no Android. Os animais são renderizados com
/// glifos nativos do sistema, permanecendo nítidos em qualquer tamanho e
/// funcionando totalmente offline.
class AnimalArtwork extends StatelessWidget {
  const AnimalArtwork({
    super.key,
    required this.group,
    this.borderRadius = 14,
    this.showGlow = true,
  }) : assert(group >= 1 && group <= 25);

  final int group;
  final double borderRadius;
  final bool showGlow;

  static const double _cellAspectRatio = 250 / 146;

  static const Map<int, String> _animalGlyph = {
    1: '🐦', // Avestruz
    2: '🦅', // Águia
    3: '🐴', // Burro
    4: '🦋', // Borboleta
    5: '🐕', // Cachorro
    6: '🐐', // Cabra
    7: '🐏', // Carneiro
    8: '🐫', // Camelo
    9: '🐍', // Cobra
    10: '🐇', // Coelho
    11: '🐎', // Cavalo
    12: '🐘', // Elefante
    13: '🐓', // Galo
    14: '🐈', // Gato
    15: '🐊', // Jacaré
    16: '🦁', // Leão
    17: '🐒', // Macaco
    18: '🐖', // Porco
    19: '🦚', // Pavão
    20: '🦃', // Peru
    21: '🐂', // Touro
    22: '🐅', // Tigre
    23: '🐻', // Urso
    24: '🦌', // Veado
    25: '🐄', // Vaca
  };

  @override
  Widget build(BuildContext context) {
    final glyph = _animalGlyph[group] ?? '🐾';

    return AspectRatio(
      aspectRatio: _cellAspectRatio,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final shortest = constraints.biggest.shortestSide;
          final fontSize = shortest.clamp(46.0, 94.0);

          return DecoratedBox(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF12253C), Color(0xFF091522)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(color: GphTheme.border),
              boxShadow: showGlow
                  ? const [
                      BoxShadow(
                        color: Color(0x244EA1FF),
                        blurRadius: 18,
                        spreadRadius: -6,
                      ),
                    ]
                  : null,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(borderRadius),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Positioned(
                    right: -18,
                    top: -26,
                    child: Container(
                      width: 92,
                      height: 92,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0x124EA1FF),
                      ),
                    ),
                  ),
                  Center(
                    child: FittedBox(
                      fit: BoxFit.contain,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                        child: Text(
                          glyph,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: fontSize,
                            height: 1,
                            shadows: const [
                              Shadow(
                                color: Color(0x66000000),
                                blurRadius: 12,
                                offset: Offset(0, 5),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
