import 'package:test/test.dart';
import 'package:brilliant_game/constantes.dart';
import 'package:brilliant_game/region.dart';

void main() {
  group('Región Azul', () {
    late TipoAzul region;

    setUp(() {
      region = const TipoAzul();
    });

    test('Permite agregar si hay menos de dos números distintos', () {
      expect(region.esPosibleAgregar([1, 1], 1), isTrue);
      expect(region.esPosibleAgregar([1, 1], 2), isTrue);
      expect(region.esPosibleAgregar([1, 2, 1], 2), isTrue);
    });

    test('No permite agregar si excede dos números distintos', () {
      expect(region.esPosibleAgregar([1, 2], 3), isFalse);
    });
  });

  group('Región Verde', () {
    late TipoVerde region;

    setUp(() {
      region = const TipoVerde();
    });

    test('Permite agregar cualquier número', () {
      expect(region.esPosibleAgregar([], 1), isTrue);
      expect(region.esPosibleAgregar([1, 2, 3], 4), isTrue);
      expect(region.esPosibleAgregar([6, 6], 6), isTrue);
    });

    test('Puntuaciones corresponden a la escala verde (4, 3, 2)', () {
      expect(region.puntuaciones, ConstantesJuego.puntuacionesVerde);
    });
  });

  group('Región Amarilla', () {
    late TipoAmarillo region;

    setUp(() {
      region = const TipoAmarillo();
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
      region = const TipoMorado();
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
      region = const TipoRojo();
    });

    test('Permite agregar si es distinto a todos', () {
      expect(region.esPosibleAgregar([5, 6], 1), isTrue);
    });

    test('No permite agregar si el número ya existe', () {
      expect(region.esPosibleAgregar([5, 6], 5), isFalse);
    });
  });

  group('Región Gris (Nueva)', () {
    late TipoGris region;

    setUp(() {
      region = const TipoGris();
    });

    test('Permite agregar si es idéntico a los actuales', () {
      expect(region.esPosibleAgregar([3, 3], 3), isTrue);
      expect(region.esPosibleAgregar([], 5), isTrue);
    });

    test('No permite agregar si es distinto a los actuales', () {
      expect(region.esPosibleAgregar([3, 3], 2), isFalse);
    });

    test('Puntuaciones corresponden a la escala estándar (8, 6, 4)', () {
      expect(region.puntuaciones, ConstantesJuego.puntuacionesEstandar);
    });
  });

  group('Región Naranja (Nueva)', () {
    test('Variante Alta (4-6) acepta solo números 4, 5 y 6', () {
      const naranjaAlto = TipoNaranja.alto();
      expect(naranjaAlto.esPosibleAgregar([], 4), isTrue);
      expect(naranjaAlto.esPosibleAgregar([4], 5), isTrue);
      expect(naranjaAlto.esPosibleAgregar([4, 5], 6), isTrue);
      expect(naranjaAlto.esPosibleAgregar([], 1), isFalse);
      expect(naranjaAlto.esPosibleAgregar([], 3), isFalse);
      expect(naranjaAlto.puntuaciones, ConstantesJuego.puntuacionesNaranja);
    });

    test('Variante Baja (1-3) acepta solo números 1, 2 y 3', () {
      const naranjaBajo = TipoNaranja.bajo();
      expect(naranjaBajo.esPosibleAgregar([], 1), isTrue);
      expect(naranjaBajo.esPosibleAgregar([1], 2), isTrue);
      expect(naranjaBajo.esPosibleAgregar([1, 2], 3), isTrue);
      expect(naranjaBajo.esPosibleAgregar([], 4), isFalse);
      expect(naranjaBajo.esPosibleAgregar([], 6), isFalse);
      expect(naranjaBajo.puntuaciones, ConstantesJuego.puntuacionesNaranja);
    });

    test('Subclases TipoNaranjaAlto y TipoNaranjaBajo heredan el comportamiento', () {
      const alto = TipoNaranjaAlto();
      const bajo = TipoNaranjaBajo();
      expect(alto.esPosibleAgregar([], 5), isTrue);
      expect(alto.esPosibleAgregar([], 2), isFalse);
      expect(bajo.esPosibleAgregar([], 2), isTrue);
      expect(bajo.esPosibleAgregar([], 5), isFalse);
    });
  });

  group('Fábrica Region.desdeNombre', () {
    test('Crea instancias correctas para todos los colores', () {
      expect(Region.desdeNombre('gris'), isA<TipoGris>());
      expect(Region.desdeNombre('naranja'), isA<TipoNaranja>());
      expect(Region.desdeNombre('naranja_bajo'), isA<TipoNaranjaBajo>());
      expect(Region.desdeNombre('naranja_alto'), isA<TipoNaranjaAlto>());
      expect(Region.desdeNombre('rojo'), isA<TipoRojo>());
      expect(Region.desdeNombre('azul'), isA<TipoAzul>());
      expect(Region.desdeNombre('verde'), isA<TipoVerde>());
      expect(Region.desdeNombre('morado'), isA<TipoMorado>());
      expect(Region.desdeNombre('amarillo'), isA<TipoAmarillo>());
    });

    test('Lanza ArgumentError para nombres inválidos', () {
      expect(() => Region.desdeNombre('desconocido'), throwsArgumentError);
    });
  });
}
