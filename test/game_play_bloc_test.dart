import 'package:flutter_test/flutter_test.dart';
import 'package:brilliant_game/region.dart' hide Color;
import 'package:brilliant_game/tablero.dart';
import 'package:brilliant_game/features/board/bloc/game_play_bloc.dart';

Tablero _tablero() {
  final t = Tablero(ancho: 7, alto: 7);
  // Región morada de 2 casillas: (0,0) y (1,0)
  t.agregarRegion(TipoMorado(), [t.getCasilla(0, 0), t.getCasilla(1, 0)]);
  // Región verde de 3 casillas lejos de la anterior
  t.agregarRegion(TipoVerde(), [
    t.getCasilla(3, 3),
    t.getCasilla(4, 3),
    t.getCasilla(5, 3),
  ]);
  t.getCasilla(0, 0).valor = 4; // casilla inicial
  t.getCasilla(3, 3).valor = 2;
  return t;
}

GamePlayBloc _bloc() {
  final b = GamePlayBloc();
  b.add(StartGame(_tablero(), jugadores: 2));
  return b;
}

void main() {
  test('StartGame crea un tablero por jugador con dados', () async {
    final b = _bloc();
    await Future<void>.delayed(Duration.zero);
    final s = b.state as GamePlayActive;
    expect(s.tableros.length, 2);
    expect(s.dados.length, 2);
    expect(s.ancla, isNull);
    expect(s.tableros[0], isNot(same(s.tableros[1])));
    expect(s.casillasValidas, isEmpty);
    await b.close();
  });

  test('PlaceNumber sin ancla da error y no cambia turno', () async {
    final b = _bloc();
    await Future<void>.delayed(Duration.zero);
    b.add(const PlaceNumber(1, 0));
    await Future<void>.delayed(Duration.zero);
    final s = b.state as GamePlayActive;
    expect(s.errorMessage, isNotNull);
    expect(s.jugadorActual, 0);
    await b.close();
  });

  test('casillas válidas respetan región (morado exige idénticos) y adyacencia', () async {
    final b = _bloc();
    await Future<void>.delayed(Duration.zero);
    final inicial = b.state as GamePlayActive;
    // Fuerza el ancla a un valor conocido eligiendo el dado cuyo valor sea 4 o no.
    b.add(const SelectAnchor(0));
    await Future<void>.delayed(Duration.zero);
    final s = b.state as GamePlayActive;
    final valor = s.ancla!;
    final coords = s.casillasValidas.map((c) => (c.x, c.y)).toSet();
    // Morado: solo si el ancla es 4; (1,0) es adyacente a (0,0).
    expect(coords.contains((1, 0)), valor == 4);
    // Verde acepta cualquier número; (4,3) adyacente a (3,3).
    expect(coords.contains((4, 3)), isTrue);
    // (5,3) no es adyacente a ninguna ocupada.
    expect(coords.contains((5, 3)), isFalse);
    expect(inicial.jugadorActual, 0);
    await b.close();
  });

  test('completar región da puntos por orden: 1.º más que 2.º', () async {
    final base = Tablero(ancho: 7, alto: 7);
    base.agregarRegion(TipoVerde(), [base.getCasilla(0, 0), base.getCasilla(1, 0)]);
    base.getCasilla(0, 0).valor = 1;

    final b = GamePlayBloc();
    b.add(StartGame(base, jugadores: 2));
    await Future<void>.delayed(Duration.zero);

    // Cada turno: ancla = dado 0 y colocar en (1,0) (verde acepta todo).
    b.add(const SelectAnchor(0));
    b.add(const PlaceNumber(1, 0)); // jugador 0 completa primero
    await Future<void>.delayed(Duration.zero);
    var s = b.state as GamePlayActive;
    expect(s.puntos[0], 4); // verde: 1.er lugar = 4
    expect(s.jugadorActual, 1);

    b.add(const SelectAnchor(0));
    b.add(const PlaceNumber(1, 0)); // jugador 1 completa segundo
    await Future<void>.delayed(Duration.zero);
    s = b.state as GamePlayActive;
    expect(s.puntos[1], 3); // 2.º lugar = 3
    expect(s.terminada, isTrue);
    await b.close();
  });

  test('regionesPorLlenar muestra la puntuación de la región a punto de llenarse', () async {
    final base = Tablero(ancho: 7, alto: 7);
    base.agregarRegion(TipoVerde(), [base.getCasilla(0, 0), base.getCasilla(1, 0)]);
    base.getCasilla(0, 0).valor = 1;

    final b = GamePlayBloc();
    b.add(StartGame(base, jugadores: 2));
    b.add(const SelectAnchor(1));
    await Future<void>.delayed(Duration.zero);
    final s = b.state as GamePlayActive;
    expect(s.regionesPorLlenar, [const RegionPorLlenar(0, 4)]);
    await b.close();
  });

  test('PassTurn avanza jugador y ResetGame reinicia', () async {
    final b = _bloc();
    await Future<void>.delayed(Duration.zero);
    b.add(const PassTurn());
    await Future<void>.delayed(Duration.zero);
    expect((b.state as GamePlayActive).jugadorActual, 1);
    b.add(const ResetGame());
    await Future<void>.delayed(Duration.zero);
    expect((b.state as GamePlayActive).jugadorActual, 0);
    await b.close();
  });
}
