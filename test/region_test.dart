import 'package:test/test.dart';
import '../lib/region.dart';

void main() {
  group('Región Azul', () {
    late TipoAzul region;

    setUp(() {
      region = TipoAzul();
    });

    test('Permite agregar si hay menos de dos números distintos', () {
      expect(region.esPosibleAgregar([1, 1], 1), isTrue); // Mismo número (1 distinto total)
      expect(region.esPosibleAgregar([1, 1], 2), isTrue); // Nuevo número (2 distintos en total)
      expect(region.esPosibleAgregar([1, 2, 1], 2), isTrue); // Siguen siendo 2 distintos
    });

    test('No permite agregar si excede dos números distintos', () {
      expect(region.esPosibleAgregar([1, 2], 3), isFalse); // Serían 3 distintos
    });
  });

  group('Región Verde', () {
    late TipoVerde region;

    setUp(() {
      region = TipoVerde();
    });

    test('Permite agregar cualquier número', () {
      expect(region.esPosibleAgregar([], 1), isTrue);
      expect(region.esPosibleAgregar([1, 2, 3], 4), isTrue);
      expect(region.esPosibleAgregar([6, 6], 6), isTrue);
    });
  });

  group('Región Amarilla', () {
    late TipoAmarillo region;

    setUp(() {
      region = TipoAmarillo();
    });

    test('Permite agregar si es un número distinto a todos', () {
      expect(region.esPosibleAgregar([1, 2, 3], 4), isTrue);
    });

    test('No permite agregar si el número ya existe', () {
      expect(region.esPosibleAgregar([1, 2, 3], 2), isFalse);
    });
  });

  group('Región Morada', () {
    late TipoMorado region;

    setUp(() {
      region = TipoMorado();
    });

    test('Permite agregar si es idéntico a los actuales', () {
      expect(region.esPosibleAgregar([4, 4], 4), isTrue);
    });

    test('No permite agregar si es distinto a los actuales', () {
      expect(region.esPosibleAgregar([4, 4], 5), isFalse);
    });
  });

  group('Región Roja', () {
    late TipoRojo region;

    setUp(() {
      region = TipoRojo();
    });

    test('Permite agregar si es distinto a todos', () {
      expect(region.esPosibleAgregar([5, 6], 1), isTrue);
    });

    test('No permite agregar si el número ya existe', () {
      expect(region.esPosibleAgregar([5, 6], 5), isFalse);
    });
  });
}
