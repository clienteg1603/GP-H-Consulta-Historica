import 'dart:convert';

import 'package:flutter/material.dart';

import 'animal_sheet_data.dart';
import 'gph_theme.dart';

/// Exibe somente a célula correspondente ao grupo dentro da folha 5x5.
///
/// A folha é usada em vez de 25 arquivos separados para manter o APK leve e
/// garantir que todos os bichos tenham exatamente o mesmo tratamento visual.
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

  static final _sheetBytes = base64Decode(
    gphAnimalSheetBase64.replaceAll('\n', '').trim(),
  );
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
                    child: Image.memory(
                      _sheetBytes,
                      width: fullWidth,
                      height: fullHeight,
                      fit: BoxFit.fill,
                      alignment: Alignment.topLeft,
                      filterQuality: FilterQuality.medium,
                      gaplessPlayback: true,
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
