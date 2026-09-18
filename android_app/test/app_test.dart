import 'package:flutter_test/flutter_test.dart';
import 'package:gph_consulta_android/data/animals.dart';

void main() {
  test('cadastro contém os 25 grupos', () {
    expect(gphAnimals.length, 25);
    expect(gphAnimals.first.group, 1);
    expect(gphAnimals.first.name, 'Avestruz');
    expect(gphAnimals.last.group, 25);
    expect(gphAnimals.last.name, 'Vaca');
  });
}
