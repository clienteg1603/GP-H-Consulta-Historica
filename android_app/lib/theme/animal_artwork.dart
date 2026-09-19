import 'package:flutter/material.dart';

import 'gph_theme.dart';

/// Exibe somente a célula correspondente ao grupo dentro da folha 5x5.
///
/// A folha é carregada como asset real do Flutter. Isso evita a decodificação
/// de uma imagem grande embutida em Base64 durante a execução e mantém as
/// ilustrações disponíveis offline.
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

  static const String _sheetAsset = 'assets/animals/cartoon_sheet.jpg';
  static const double _cellAspectRatio = 250 / 146;

  @override
  Widget build(BuildContext context) {
    final index = group - 1;
    final row = index ~/ 5;
    final column = index % 5;

    return AspectRatio(
      aspectRatio: _cellAspectRatio,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;
          final fullWidth = width * 5;
          final fullHeight = height * 5;

          return DecoratedBox(
            decoration: BoxDecoration(
              color: GphTheme.surfaceSoft,
              borderRadius: BorderRadius.circular(borderRadius),
              boxShadow: showGlow
                  ? const [
                      BoxShadow(
                        color: Color(0x1A4EA1FF),
                        blurRadius: 16,
                        spreadRadius: -4,
                      ),
                    ]
                  : null,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(borderRadius),
              child: ClipRect(
                child: OverflowBox(
                  minWidth: fullWidth,
                  maxWidth: fullWidth,
                  minHeight: fullHeight,
                  maxHeight: fullHeight,
                  alignment: Alignment.topLeft,
                  child: Transform.translate(
                    offset: Offset(-column * width, -row * height),
                    child: Image.asset(
                      _sheetAsset,
                      width: fullWidth,
                      height: fullHeight,
                      fit: BoxFit.fill,
                      alignment: Alignment.topLeft,
                      filterQuality: FilterQuality.high,
                      gaplessPlayback: true,
                      errorBuilder: (context, error, stackTrace) {
                        return ColoredBox(
                          color: GphTheme.surfaceSoft,
                          child: const Center(
                            child: Icon(Icons.pets_outlined),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
