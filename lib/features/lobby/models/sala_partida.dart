import 'package:equatable/equatable.dart';
import '../../../constantes.dart';
import 'jugador_sala.dart';

/// Estados posibles del ciclo de vida de una sala de juego.
enum EstadoSala {
  esperando,
  todosListos,
  enSetup,
  enJuego,
  finalizada;

  String toJson() => name;

  static EstadoSala fromJson(String value) {
    return EstadoSala.values.firstWhere(
      (e) => e.name == value,
      orElse: () => EstadoSala.esperando,
    );
  }
}

/// Entidad que representa una Sala de Partida (Lobby) y su estado sincronizado.
class SalaPartida extends Equatable {
  final String codigo;
  final String gameMasterId;
  final int mapaSeleccionado;
  final List<JugadorSala> jugadores;
  final EstadoSala estadoSala;
  final int rondaActual;
  final List<int> dadosActuales;
  final Map<String, int> indicesEnDisputaPorColor;
  final String? ganadorId;

  const SalaPartida({
    required this.codigo,
    required this.gameMasterId,
    this.mapaSeleccionado = 1,
    this.jugadores = const [],
    this.estadoSala = EstadoSala.esperando,
    this.rondaActual = 0,
    this.dadosActuales = const [],
    this.indicesEnDisputaPorColor = const {},
    this.ganadorId,
  });

  /// Indica si todos los jugadores presentes en la sala han marcado su estado como "Listo".
  bool get todosListos =>
      jugadores.isNotEmpty && jugadores.every((j) => j.esListo);

  /// Indica si la sala ha alcanzado el límite máximo de 6 jugadores.
  bool get estaLlena =>
      jugadores.length >= ConstantesJuego.maxJugadoresPorSala;

  /// Indica si la partida ya fue iniciada y no admite el ingreso de jugadores.
  bool get partidaIniciada =>
      estadoSala == EstadoSala.enSetup ||
      estadoSala == EstadoSala.enJuego ||
      estadoSala == EstadoSala.finalizada;

  /// Indica si la partida se encuentra en la fase inicial de preparación (Setup).
  bool get enFaseSetup =>
      estadoSala == EstadoSala.enSetup ||
      (estadoSala == EstadoSala.enJuego && rondaActual == 0);

  /// Indica si la partida se encuentra en fase activa de rondas con dados.
  bool get enFaseRondas =>
      estadoSala == EstadoSala.enJuego && rondaActual >= 1;

  /// Verifica si el identificador corresponde al Game Master actual de la sala.
  bool esGameMaster(String jugadorId) => gameMasterId == jugadorId;

  SalaPartida copyWith({
    String? codigo,
    String? gameMasterId,
    int? mapaSeleccionado,
    List<JugadorSala>? jugadores,
    EstadoSala? estadoSala,
    int? rondaActual,
    List<int>? dadosActuales,
    Map<String, int>? indicesEnDisputaPorColor,
    String? ganadorId,
    bool clearGanador = false,
  }) {
    return SalaPartida(
      codigo: codigo ?? this.codigo,
      gameMasterId: gameMasterId ?? this.gameMasterId,
      mapaSeleccionado: mapaSeleccionado ?? this.mapaSeleccionado,
      jugadores: jugadores ?? this.jugadores,
      estadoSala: estadoSala ?? this.estadoSala,
      rondaActual: rondaActual ?? this.rondaActual,
      dadosActuales: dadosActuales ?? this.dadosActuales,
      indicesEnDisputaPorColor:
          indicesEnDisputaPorColor ?? this.indicesEnDisputaPorColor,
      ganadorId: clearGanador ? null : (ganadorId ?? this.ganadorId),
    );
  }

  Map<String, dynamic> toJson() => {
        'codigo': codigo,
        'gameMasterId': gameMasterId,
        'mapaSeleccionado': mapaSeleccionado,
        'jugadores': jugadores.map((j) => j.toJson()).toList(),
        'estadoSala': estadoSala.toJson(),
        'rondaActual': rondaActual,
        'dadosActuales': dadosActuales,
        'indicesEnDisputaPorColor': indicesEnDisputaPorColor,
        'ganadorId': ganadorId,
      };

  factory SalaPartida.fromJson(Map<String, dynamic> json) {
    final listaJugadores = (json['jugadores'] as List<dynamic>? ?? [])
        .map((item) => JugadorSala.fromJson(item as Map<String, dynamic>))
        .toList();

    final listaDados = (json['dadosActuales'] as List<dynamic>? ?? [])
        .map((item) => (item as num).toInt())
        .toList();

    final rawDisputa =
        json['indicesEnDisputaPorColor'] as Map<String, dynamic>? ?? const {};
    final mapaDisputa = <String, int>{
      for (final entry in rawDisputa.entries)
        entry.key: (entry.value as num).toInt(),
    };

    return SalaPartida(
      codigo: json['codigo'] as String,
      gameMasterId: json['gameMasterId'] as String,
      mapaSeleccionado: json['mapaSeleccionado'] as int? ?? 1,
      jugadores: listaJugadores,
      estadoSala: json['estadoSala'] != null
          ? EstadoSala.fromJson(json['estadoSala'] as String)
          : EstadoSala.esperando,
      rondaActual: json['rondaActual'] as int? ?? 0,
      dadosActuales: listaDados,
      indicesEnDisputaPorColor: mapaDisputa,
      ganadorId: json['ganadorId'] as String?,
    );
  }

  @override
  List<Object?> get props => [
        codigo,
        gameMasterId,
        mapaSeleccionado,
        jugadores,
        estadoSala,
        rondaActual,
        dadosActuales,
        indicesEnDisputaPorColor,
        ganadorId,
      ];
}
