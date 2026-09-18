import 'package:flutter_test/flutter_test.dart';
import 'package:gph_consulta_android/data/animals.dart';
import 'package:gph_consulta_android/main.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('cadastro contém os 25 grupos', () {
    expect(gphAnimals.length, 25);
    expect(gphAnimals.first.group, 1);
    expect(gphAnimals.first.name, 'Avestruz');
    expect(gphAnimals.last.group, 25);
    expect(gphAnimals.last.name, 'Vaca');
  });

  testWidgets('abre a tela inicial do GP-H', (tester) async {
    await tester.pumpWidget(const GphAndroidApp());
    await tester.pump();
    expect(find.text('GP-H Consulta Histórica'), findsOneWidget);
    expect(find.text('25 bichos'), findsOneWidget);
    expect(find.text('Avestruz'), findsOneWidget);
  });
}
