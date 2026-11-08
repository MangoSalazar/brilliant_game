import 'dart:math';
import '../../constantes.dart';
import '../../features/lobby/models/jugador_sala.dart';
import '../../features/lobby/models/sala_partida.dart';

/// Excepción de negocio lanzada ante operaciones inválidas sobre una sala.
class RoomException implements Exception {
  final String message;
  const RoomException(this.message);

  @override
  String toString() => message;
}

/// Gestor en memoria de las salas de espera activas en el servidor (SRP).
/// Administra creación de códigos únicos de 5 dígitos, unión de hasta 6 jugadores,
/// selección de mapa, estados "Listo", expulsiones y arranque de partida.
class RoomManager {
  final Random _random;
  final Map<String, SalaPartida> _salas = {};

  RoomManager({Random? random}) : _random = random ?? Random();

  /// Retorna la lista de todas las salas activas actualmente.
  List<SalaPartida> get salasActivas => List.unmodifiable(_salas.values);

  /// Obtiene una sala por su código de 5 dígitos o `null` si no existe.
  SalaPartida? obtenerSala(String codigo) => _salas[codigo.trim()];

  /// Genera un código numérico único de 5 dígitos que no esté en uso.
  String _generarCodigoUnico() {
    String codigo;
    do {
      final numero = 10000 + _random.nextInt(90000);
      codigo = numero.toString();
    } while (_salas.containsKey(codigo));
    return codigo;
  }

  /// Crea una nueva sala asignando al creador como Game Master.
  SalaPartida crearSala({
    required String jugadorId,
    required String nombreJugador,
  }) {
    final codigo = _generarCodigoUnico();
    final host = JugadorSala(
      id: jugadorId,
      nombre: nombreJugador,
      esListo: false,
      esHost: true,
    );

    final nuevaSala = SalaPartida(
      codigo: codigo,
      gameMasterId: jugadorId,
      mapaSeleccionado: 1,
      jugadores: [host],
      estadoSala: EstadoSala.esperando,
    );

    _salas[codigo] = nuevaSala;
    return nuevaSala;
  }

  /// Une a un jugador a una sala existente validando código y cupo máximo (< 6).
  SalaPartida unirseASala({
    required String codigo,
    required String jugadorId,
    required String nombreJugador,
  }) {
    final codigoLimpio = codigo.trim();
    if (codigoLimpio.length != ConstantesJuego.longitudCodigoSala ||
        int.tryParse(codigoLimpio) == null) {
      throw const RoomException(ConstantesJuego.errorCodigoInvalido);
    }

    final sala = _salas[codigoLimpio];
    if (sala == null) {
      throw const RoomException(ConstantesJuego.errorSalaNoExiste);
    }

    // Si el jugador ya se encuentra dentro de la sala (reconexión), devolver la sala
    final indiceExistente =
        sala.jugadores.indexWhere((j) => j.id == jugadorId);
    if (indiceExistente != -1) {
      return sala;
    }

    if (sala.estaLlena) {
      throw const RoomException(ConstantesJuego.errorSalaLlena);
    }

    final nuevoJugador = JugadorSala(
      id: jugadorId,
      nombre: nombreJugador,
      esListo: false,
      esHost: false,
    );

    final listaActualizada = [...sala.jugadores, nuevoJugador];
    final salaActualizada = _recalcularEstadoSala(
      sala.copyWith(jugadores: listaActualizada),
    );

    _salas[codigoLimpio] = salaActualizada;
    return salaActualizada;
  }

  /// Alterna o fija el estado "Listo" de un jugador dentro de la sala.
  SalaPartida cambiarEstadoListo({
    required String codigo,
    required String jugadorId,
    bool? listo,
  }) {
    final sala = _obtenerSalaObligatoria(codigo);
    final indice = sala.jugadores.indexWhere((j) => j.id == jugadorId);
    if (indice == -1) {
      throw const RoomException('El jugador no pertenece a esta sala.');
    }

    final jugadorActual = sala.jugadores[indice];
    final nuevoValorListo = listo ?? !jugadorActual.esListo;

    final jugadoresActualizados = List<JugadorSala>.from(sala.jugadores);
    jugadoresActualizados[indice] = jugadorActual.copyWith(
      esListo: nuevoValorListo,
    );

    final salaActualizada = _recalcularEstadoSala(
      sala.copyWith(jugadores: jugadoresActualizados),
    );

    _salas[sala.codigo] = salaActualizada;
    return salaActualizada;
  }

  /// Permite exclusivamente al Game Master seleccionar uno de los 4 mapas.
  SalaPartida seleccionarMapa({
    required String codigo,
    required String solicitanteId,
    required int mapaId,
  }) {
    final sala = _obtenerSalaObligatoria(codigo);

    if (!sala.esGameMaster(solicitanteId)) {
      throw const RoomException(
        'Solo el Game Master puede cambiar el mapa de la sala.',
      );
    }

    if (mapaId < 1 || mapaId > ConstantesJuego.totalMapas) {
      throw const RoomException('El mapa seleccionado debe estar entre 1 y 4.');
    }

    final salaActualizada = sala.copyWith(mapaSeleccionado: mapaId);
    _salas[sala.codigo] = salaActualizada;
    return salaActualizada;
  }

  /// Permite exclusivamente al Game Master expulsar a otro participante de la sala.
  SalaPartida expulsarJugador({
    required String codigo,
    required String solicitanteId,
    required String objetivoId,
  }) {
    final sala = _obtenerSalaObligatoria(codigo);

    if (!sala.esGameMaster(solicitanteId)) {
      throw const RoomException(ConstantesJuego.errorSoloHostExpulsa);
    }

    if (solicitanteId == objetivoId) {
      throw const RoomException('El Game Master no puede expulsarse a sí mismo.');
    }

    final jugadoresRestantes =
        sala.jugadores.where((j) => j.id != objetivoId).toList();

    final salaActualizada = _recalcularEstadoSala(
      sala.copyWith(jugadores: jugadoresRestantes),
    );

    _salas[sala.codigo] = salaActualizada;
    return salaActualizada;
  }

  /// Inicia la partida validando que el solicitante sea el Game Master y que todos estén listos.
  SalaPartida iniciarPartida({
    required String codigo,
    required String solicitanteId,
  }) {
    final sala = _obtenerSalaObligatoria(codigo);

    if (!sala.esGameMaster(solicitanteId)) {
      throw const RoomException(ConstantesJuego.errorSoloHostInicia);
    }

    if (!sala.todosListos) {
      throw const RoomException(ConstantesJuego.errorJugadoresNoListos);
    }

    final salaEnJuego = sala.copyWith(estadoSala: EstadoSala.enJuego);
    _salas[sala.codigo] = salaEnJuego;
    return salaEnJuego;
  }

  /// Remueve a un jugador cuando sale voluntariamente o se desconecta.
  /// Si la sala queda vacía se elimina; si el Game Master sale, se transfiere el rol.
  SalaPartida? removerJugador({
    required String codigo,
    required String jugadorId,
  }) {
    final codigoLimpio = codigo.trim();
    final sala = _salas[codigoLimpio];
    if (sala == null) return null;

    final restantes =
        sala.jugadores.where((j) => j.id != jugadorId).toList();

    if (restantes.isEmpty) {
      _salas.remove(codigoLimpio);
      return null;
    }

    String nuevoGameMasterId = sala.gameMasterId;
    List<JugadorSala> listaAjustada = restantes;

    // Si quien salió era el Game Master, transferir el rol al jugador más antiguo
    if (sala.gameMasterId == jugadorId) {
      nuevoGameMasterId = restantes.first.id;
      listaAjustada = [
        restantes.first.copyWith(esHost: true),
        ...restantes.skip(1),
      ];
    }

    final salaActualizada = _recalcularEstadoSala(
      sala.copyWith(
        gameMasterId: nuevoGameMasterId,
        jugadores: listaAjustada,
      ),
    );

    _salas[codigoLimpio] = salaActualizada;
    return salaActualizada;
  }

  SalaPartida _obtenerSalaObligatoria(String codigo) {
    final sala = _salas[codigo.trim()];
    if (sala == null) {
      throw const RoomException(ConstantesJuego.errorSalaNoExiste);
    }
    return sala;
  }

  SalaPartida _recalcularEstadoSala(SalaPartida sala) {
    if (sala.estadoSala == EstadoSala.enJuego ||
        sala.estadoSala == EstadoSala.finalizada) {
      return sala;
    }
    final nuevoEstado =
        sala.todosListos ? EstadoSala.todosListos : EstadoSala.esperando;
    return sala.copyWith(estadoSala: nuevoEstado);
  }
}
