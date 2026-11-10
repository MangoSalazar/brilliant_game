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

  test('casillas válidas exigen adyacencia al valor del dado Ancla y colocan el OTRO dado', () async {
    final b = _bloc();
    await Future<void>.delayed(Duration.zero);
    final inicial = b.state as GamePlayActive;
    // Asegurar que la casilla (0,0) tenga el valor del dado 0 (ancla) y (3,3) otro valor
    final d0 = inicial.dados[0];
    final d1 = inicial.dados[1];
    inicial.tableroActual.getCasilla(0, 0).valor = d0;
    inicial.tableroActual.getCasilla(3, 3).valor = d0;

    b.add(const SelectAnchor(0));
    await Future<void>.delayed(Duration.zero);
    final s = b.state as GamePlayActive;
    expect(s.ancla, equals(d0));
    expect(s.valorAColocar, equals(d1));

    final coords = s.casillasValidas.map((c) => (c.x, c.y)).toSet();
    // Morado en (0,0)-(1,0): (0,0) tiene d0; solo admite colocar d1 en (1,0) si d1 == d0.
    expect(coords.contains((1, 0)), d1 == d0);
    // Verde en (3,3)-(4,3)-(5,3): (3,3) tiene d0 (ancla), por lo que (4,3) es adyacente al ancla y acepta cualquier d1.
    expect(coords.contains((4, 3)), isTrue);
    // (5,3) no es adyacente a ninguna casilla con el valor del ancla.
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

    // Ajustar la casilla (0,0) del jugador 0 al valor de dados[0] para que dados[0] sea ancla válido
    var s = b.state as GamePlayActive;
    s.tableroActual.getCasilla(0, 0).valor = s.dados[0];

    b.add(const SelectAnchor(0));
    b.add(const PlaceNumber(1, 0)); // jugador 0 completa primero colocando dados[1]
    await Future<void>.delayed(Duration.zero);
    s = b.state as GamePlayActive;
    expect(s.puntos[0], 4); // verde: 1.er lugar = 4
    expect(s.jugadorActual, 1);

    // Ajustar la casilla (0,0) del jugador 1 al valor de dados[0] del nuevo turno
    s.tableroActual.getCasilla(0, 0).valor = s.dados[0];
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
    await Future<void>.delayed(Duration.zero);
    final inicial = b.state as GamePlayActive;
    inicial.tableroActual.getCasilla(0, 0).valor = inicial.dados[1];

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
