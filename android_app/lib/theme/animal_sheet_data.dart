import 'animal_sheet_hd_part1.dart';
import 'animal_sheet_hd_part2.dart';
import 'animal_sheet_hd_part3.dart';
import 'animal_sheet_hd_part4.dart';
import 'animal_sheet_hd_part5.dart';
import 'animal_sheet_hd_part6.dart';
import 'animal_sheet_hd_part7.dart';
import 'animal_sheet_hd_part8.dart';

/// Folha 5x5 em alta resolução com as ilustrações dos 25 bichos.
///
/// A imagem continua embutida no aplicativo para funcionar offline. Ela foi
/// dividida em partes apenas para manter os arquivos-fonte menores e fáceis de
/// validar no pipeline.
const String gphAnimalSheetBase64 =
    gphAnimalSheetPart1 +
    gphAnimalSheetPart2 +
    gphAnimalSheetPart3 +
    gphAnimalSheetPart4 +
    gphAnimalSheetPart5 +
    gphAnimalSheetPart6 +
    gphAnimalSheetPart7 +
    gphAnimalSheetPart8;
