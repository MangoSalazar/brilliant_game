import 'dart:math';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../tablero.dart';

// --- Estados ---

/// Casillas que se iluminan por completo porque la jugada las llenarÃ­a,
/// junto con los puntos que se obtendrÃ­an.
class RegionPorLlenar extends Equatable {
  final int indiceRegion;
  final int puntos;
  const RegionPorLlenar(this.indiceRegion, this.puntos);

  @override
  List<Object?> get props => [indiceRegion, puntos];
}

abstract class GamePlayState extends Equatable {
  const GamePlayState();

  @override
  List<Object?> get props => [];
}

class GamePlayInitial extends GamePlayState {
  const GamePlayInitial();
}

class GamePlayActive extends GamePlayState {
  /// Un tablero independiente por jugador.
  final List<Tablero> tableros;
  final int jugadorActual;
  final List<int> puntos;

  /// Resultado de los 2 dados del turno actual.
  final List<int> dados;

  /// Ãndice (0 o 1) del dado elegido como ancla, o null si aÃºn no se elige.
  final int? anclaIndex;

  /// Por Ã­ndice de regiÃ³n: jugadores en el orden en que la completaron.
  final Map<int, List<int>> ordenCompletado;
  final String? errorMessage;
  final bool terminada;

  /// Contador de jugadas; los tableros se mutan en sitio, así garantiza que
  /// cada jugada produzca un estado distinto.
  final int jugadas;

  const GamePlayActive({
    required this.tableros,
    required this.jugadorActual,
    required this.puntos,
    required this.dados,
    required this.anclaIndex,
    required this.ordenCompletado,
    this.errorMessage,
    this.terminada = false,
    this.jugadas = 0,
  });

  Tablero get tableroActual => tableros[jugadorActual];
  int? get ancla => anclaIndex == null ? null : dados[anclaIndex!];

  /// Casillas vacÃ­as de una regiÃ³n del jugador actual donde se puede colocar el ancla.
  List<Casilla> get casillasValidas {
    final valor = ancla;
    if (valor == null || terminada) return const [];
    return _calcularValidas(tableroActual, valor);
  }

  /// Regiones que quedarÃ­an llenas con una jugada vÃ¡lida, con su puntuaciÃ³n.
  List<RegionPorLlenar> get regionesPorLlenar {
    final valor = ancla;
    if (valor == null || terminada) return const [];
    final tablero = tableroActual;
    final validas = casillasValidas.toSet();
    final resultado = <RegionPorLlenar>[];
    for (var i = 0; i < tablero.regiones.length; i++) {
      final g = tablero.regiones[i];
      final vacias = g.casillas.where((c) => c.valor == null).toList();
      if (vacias.length == 1 && validas.contains(vacias.first)) {
        resultado.add(RegionPorLlenar(i, puntosParaCompletar(i, g)));
      }
    }
    return resultado;
  }

  /// Puntos que obtendrÃ­a el jugador actual al completar la regiÃ³n ahora.
  int puntosParaCompletar(int indiceRegion, GrupoRegion grupo) {
    final lugar = (ordenCompletado[indiceRegion]?.length ?? 0) + 1;
    return grupo.tipoRegion.puntuaciones[lugar] ?? 0;
  }

  GamePlayActive copyWith({
    List<int>? puntos,
    int? jugadorActual,
    List<int>? dados,
    int? Function()? anclaIndex,
    Map<int, List<int>>? ordenCompletado,
    String? Function()? errorMessage,
    bool? terminada,
    int? jugadas,
  }) {
    return GamePlayActive(
      tableros: tableros,
      jugadorActual: jugadorActual ?? this.jugadorActual,
      puntos: puntos ?? this.puntos,
      dados: dados ?? this.dados,
      anclaIndex: anclaIndex != null ? anclaIndex() : this.anclaIndex,
      ordenCompletado: ordenCompletado ?? this.ordenCompletado,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
      terminada: terminada ?? this.terminada,
      jugadas: jugadas ?? this.jugadas,
    );
  }

  @override
  List<Object?> get props => [
        tableros,
        jugadorActual,
        puntos,
        dados,
        anclaIndex,
        ordenCompletado,
        errorMessage,
        terminada,
        jugadas,
      ];
}

/// Casillas vacÃ­as, pertenecientes a una regiÃ³n, adyacentes a una casilla ocupada
/// y cuya regiÃ³n admite [valor].
List<Casilla> _calcularValidas(Tablero tablero, int valor) {
  final validas = <Casilla>[];
  for (final g in tablero.regiones) {
    if (!g.puedeAgregar(valor)) continue;
    for (final c in g.casillas) {
      if (c.valor == null && _tieneVecinaOcupada(tablero, c)) validas.add(c);
    }
  }
  return validas;
}

bool _tieneVecinaOcupada(Tablero tablero, Casilla c) {
  for (final (dx, dy) in const [(1, 0), (-1, 0), (0, 1), (0, -1)]) {
    final x = c.x + dx;
    final y = c.y + dy;
    if (x < 0 || x >= tablero.ancho || y < 0 || y >= tablero.alto) continue;
    if (tablero.celdas[y][x].valor != null) return true;
  }
  return false;
}

// --- Eventos ---

abstract class GamePlayEvent extends Equatable {
  const GamePlayEvent();

  @override
  List<Object?> get props => [];
}

/// Inicia la partida a partir del tablero ya preparado (SetupCompleted).
class StartGame extends GamePlayEvent {
  final Tablero tableroPreparado;
  final int jugadores;
  const StartGame(this.tableroPreparado, {this.jugadores = 2});

  @override
  List<Object?> get props => [tableroPreparado, jugadores];
}

/// Elige cuÃ¡l de los dos dados (0 o 1) actÃºa como ancla.
class SelectAnchor extends GamePlayEvent {
  final int dadoIndex;
  const SelectAnchor(this.dadoIndex);

  @override
  List<Object?> get props => [dadoIndex];
}

/// Coloca el valor del ancla en una casilla del tablero del jugador actual.
class PlaceNumber extends GamePlayEvent {
  final int x;
  final int y;
  const PlaceNumber(this.x, this.y);

  @override
  List<Object?> get props => [x, y];
}

class PassTurn extends GamePlayEvent {
  const PassTurn();
}

class ResetGame extends GamePlayEvent {
  const ResetGame();
}

// --- Bloc ---

class GamePlayBloc extends Bloc<GamePlayEvent, GamePlayState> {
  final Random _random;
  Tablero? _base;
  int _jugadores = 2;

  GamePlayBloc({Random? random})
      : _random = random ?? Random(),
        super(const GamePlayInitial()) {
    on<StartGame>(_onStartGame);
    on<SelectAnchor>(_onSelectAnchor);
    on<PlaceNumber>(_onPlaceNumber);
    on<PassTurn>(_onPassTurn);
    on<ResetGame>(_onResetGame);
  }

  List<int> _tirarDados() => [_random.nextInt(6) + 1, _random.nextInt(6) + 1];

  void _iniciar(Emitter<GamePlayState> emit) {
    final base = _base!;
    emit(GamePlayActive(
      tableros: List.generate(_jugadores, (_) => base.clonar()),
      jugadorActual: 0,
      puntos: List.filled(_jugadores, 0),
      dados: _tirarDados(),
      anclaIndex: null,
      ordenCompletado: const {},
    ));
  }

  void _onStartGame(StartGame event, Emitter<GamePlayState> emit) {
    if (event.jugadores < 1) return;
    // Se guarda una copia para que ResetGame parta del tablero preparado.
    _base = event.tableroPreparado.clonar();
    _jugadores = event.jugadores;
    _iniciar(emit);
  }

  void _onResetGame(ResetGame event, Emitter<GamePlayState> emit) {
    if (_base == null) return;
    _iniciar(emit);
  }

  void _onSelectAnchor(SelectAnchor event, Emitter<GamePlayState> emit) {
    final s = state;
    if (s is! GamePlayActive || s.terminada) return;
    if (event.dadoIndex < 0 || event.dadoIndex > 1) return;
    emit(s.copyWith(anclaIndex: () => event.dadoIndex, errorMessage: () => null));
  }

  void _onPlaceNumber(PlaceNumber event, Emitter<GamePlayState> emit) {
    final s = state;
    if (s is! GamePlayActive || s.terminada) return;

    final valor = s.ancla;
    if (valor == null) {
      emit(s.copyWith(errorMessage: () => 'Elige primero un dado como ancla.'));
      return;
    }

    final tablero = s.tableroActual;
    if (event.x < 0 || event.x >= tablero.ancho || event.y < 0 || event.y >= tablero.alto) {
      return;
    }
    final casilla = tablero.getCasilla(event.x, event.y);
    if (!s.casillasValidas.contains(casilla)) {
      emit(s.copyWith(
        errorMessage: () => 'No puedes colocar el $valor en esa casilla.',
      ));
      return;
    }

    final indice = tablero.regiones.indexWhere((g) => g.casillas.contains(casilla));
    final grupo = tablero.regiones[indice];
    grupo.agregarValor(casilla, valor);

    var puntos = s.puntos;
    var orden = s.ordenCompletado;
    if (grupo.estaLlena) {
      final ganados = s.puntosParaCompletar(indice, grupo);
      puntos = List<int>.from(puntos)..[s.jugadorActual] += ganados;
      orden = {
        ...orden,
        indice: [...(orden[indice] ?? const []), s.jugadorActual],
      };
    }

    final terminada = s.tableros.every(
      (t) => t.regiones.every((g) => g.estaLlena),
    );

    emit(s.copyWith(
      puntos: puntos,
      ordenCompletado: orden,
      terminada: terminada,
      jugadas: s.jugadas + 1,
      errorMessage: () => null,
    ));
    if (!terminada) _siguienteTurno(emit);
  }

  void _onPassTurn(PassTurn event, Emitter<GamePlayState> emit) {
    if (state is! GamePlayActive || (state as GamePlayActive).terminada) return;
    _siguienteTurno(emit);
  }

  void _siguienteTurno(Emitter<GamePlayState> emit) {
    final s = state as GamePlayActive;
    emit(s.copyWith(
      jugadorActual: (s.jugadorActual + 1) % s.tableros.length,
      dados: _tirarDados(),
      anclaIndex: () => null,
      errorMessage: () => null,
    ));
  }
}
