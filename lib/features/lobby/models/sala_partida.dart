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

  const SalaPartida({
    required this.codigo,
    required this.gameMasterId,
    this.mapaSeleccionado = 1,
    this.jugadores = const [],
    this.estadoSala = EstadoSala.esperando,
  });

  /// Indica si todos los jugadores presentes en la sala han marcado su estado como "Listo".
  bool get todosListos =>
      jugadores.isNotEmpty && jugadores.every((j) => j.esListo);

  /// Indica si la sala ha alcanzado el límite máximo de 6 jugadores.
  bool get estaLlena =>
      jugadores.length >= ConstantesJuego.maxJugadoresPorSala;

  /// Verifica si el identificador corresponde al Game Master actual de la sala.
  bool esGameMaster(String jugadorId) => gameMasterId == jugadorId;

  SalaPartida copyWith({
    String? codigo,
    String? gameMasterId,
    int? mapaSeleccionado,
    List<JugadorSala>? jugadores,
    EstadoSala? estadoSala,
  }) {
    return SalaPartida(
      codigo: codigo ?? this.codigo,
      gameMasterId: gameMasterId ?? this.gameMasterId,
      mapaSeleccionado: mapaSeleccionado ?? this.mapaSeleccionado,
      jugadores: jugadores ?? this.jugadores,
      estadoSala: estadoSala ?? this.estadoSala,
    );
  }

  Map<String, dynamic> toJson() => {
        'codigo': codigo,
        'gameMasterId': gameMasterId,
        'mapaSeleccionado': mapaSeleccionado,
        'jugadores': jugadores.map((j) => j.toJson()).toList(),
        'estadoSala': estadoSala.toJson(),
      };

  factory SalaPartida.fromJson(Map<String, dynamic> json) {
    final listaJugadores = (json['jugadores'] as List<dynamic>? ?? [])
        .map((item) => JugadorSala.fromJson(item as Map<String, dynamic>))
        .toList();

    return SalaPartida(
      codigo: json['codigo'] as String,
      gameMasterId: json['gameMasterId'] as String,
      mapaSeleccionado: json['mapaSeleccionado'] as int? ?? 1,
      jugadores: listaJugadores,
      estadoSala: json['estadoSala'] != null
          ? EstadoSala.fromJson(json['estadoSala'] as String)
          : EstadoSala.esperando,
    );
  }

  @override
  List<Object?> get props => [
        codigo,
        gameMasterId,
        mapaSeleccionado,
        jugadores,
        estadoSala,
      ];
}
