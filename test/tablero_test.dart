import 'package:test/test.dart';
import '../lib/region.dart';
import '../lib/tablero.dart';

void main() {
  group('Tablero y Casillas', () {
    test('Se crea un tablero por defecto de 7x7', () {
      final tablero = Tablero();
      expect(tablero.ancho, 7);
      expect(tablero.alto, 7);
      expect(tablero.celdas.length, 7);
      expect(tablero.celdas[0].length, 7);
    });

    test('Se puede acceder a las casillas por coordenadas', () {
      final tablero = Tablero();
      final casilla = tablero.getCasilla(3, 4);
      expect(casilla.x, 3);
      expect(casilla.y, 4);
    });

    test('Lanza error si la coordenada está fuera de los límites', () {
      final tablero = Tablero();
      expect(() => tablero.getCasilla(7, 7), throwsArgumentError);
      expect(() => tablero.getCasilla(-1, 0), throwsArgumentError);
    });
  });

  group('GrupoRegion', () {
    late Tablero tablero;

    setUp(() {
      tablero = Tablero();
    });

    test('Permite agregar una región con casillas conectadas', () {
      final casillas = [
        tablero.getCasilla(0, 0),
        tablero.getCasilla(0, 1),
        tablero.getCasilla(1, 1),
      ];
      expect(() => tablero.agregarRegion(TipoVerde(), casillas), returnsNormally);
      expect(tablero.regiones.length, 1);
    });

    test('Lanza error al agregar una región con casillas desconectadas', () {
      final casillas = [
        tablero.getCasilla(0, 0),
        tablero.getCasilla(2, 2), // No está conectada a (0,0)
      ];
      expect(() => tablero.agregarRegion(TipoVerde(), casillas), throwsArgumentError);
    });

    test('Permite agregar casillas desconectadas si la región es Amarilla', () {
      final casillas = [
        tablero.getCasilla(0, 0),
        tablero.getCasilla(6, 6),
      ];
      expect(() => tablero.agregarRegion(TipoAmarillo(), casillas), returnsNormally);
    });

    test('Lanza error si una casilla ya pertenece a otra región', () {
      final casillas1 = [tablero.getCasilla(0, 0), tablero.getCasilla(0, 1)];
      final casillas2 = [tablero.getCasilla(0, 1), tablero.getCasilla(1, 1)];
      tablero.agregarRegion(TipoVerde(), casillas1);
      expect(() => tablero.agregarRegion(TipoAzul(), casillas2), throwsArgumentError);
    });
  });

  group('Reglas de Inserción en GrupoRegion', () {
    late Tablero tablero;

    setUp(() {
      tablero = Tablero();
    });

    test('Validación al agregar valor según reglas de región', () {
      final casillas = [tablero.getCasilla(0, 0), tablero.getCasilla(0, 1)];
      tablero.agregarRegion(TipoMorado(), casillas); // Todos deben ser iguales
      final grupo = tablero.regiones.first;

      grupo.agregarValor(casillas[0], 5);
      expect(casillas[0].valor, 5);

      expect(() => grupo.agregarValor(casillas[1], 4), throwsArgumentError);
      grupo.agregarValor(casillas[1], 5); // Sí permite porque es igual
      expect(casillas[1].valor, 5);
      expect(grupo.estaLlena, isTrue);
    });

    test('Lanza error si el valor no está entre 1 y 6', () {
      final casillas = [tablero.getCasilla(0, 0)];
      tablero.agregarRegion(TipoVerde(), casillas);
      final grupo = tablero.regiones.first;

      expect(() => grupo.agregarValor(casillas[0], 7), throwsArgumentError);
      expect(() => grupo.agregarValor(casillas[0], 0), throwsArgumentError);
    });
  });
}
