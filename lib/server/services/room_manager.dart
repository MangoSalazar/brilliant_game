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

  /// Por código de sala: mapa de `colorId -> Set<jugadorId>` que completaron esa región en la ronda actual.
  final Map<String, Map<String, Set<String>>> _coloresCompletadosEnRonda = {};

  /// Por código de sala: conjunto de `jugadorId` que ya llenaron todas las casillas de su tablero.
  final Map<String, Set<String>> _tablerosLlenos = {};

  RoomManager({Random? random}) : _random = random ?? Random();

  List<int> _tirarDados() => [
        _random.nextInt(ConstantesJuego.valorDadoMaximo) +
            ConstantesJuego.valorDadoMinimo,
        _random.nextInt(ConstantesJuego.valorDadoMaximo) +
            ConstantesJuego.valorDadoMinimo,
      ];

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

    if (sala.partidaIniciada) {
      throw const RoomException(ConstantesJuego.errorPartidaYaIniciada);
    }

    // Rechazar si ya hay un jugador activo con esa misma cuenta/nombre en la sala
    final indiceExistente = sala.jugadores.indexWhere(
      (j) =>
          !j.abandono &&
          (j.id == jugadorId ||
              j.nombre.trim().toLowerCase() ==
                  nombreJugador.trim().toLowerCase()),
    );
    if (indiceExistente != -1) {
      throw const RoomException(ConstantesJuego.errorSesionYaActiva);
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

    _coloresCompletadosEnRonda[sala.codigo] = {};
    _tablerosLlenos[sala.codigo] = {};

    final jugadoresReiniciados = sala.jugadores
        .map(
          (j) => j.copyWith(
            setupListo: false,
            turnoListo: false,
            puntos: 0,
            abandono: false,
          ),
        )
        .toList();

    final salaEnJuego = sala.copyWith(
      estadoSala: EstadoSala.enJuego,
      jugadores: jugadoresReiniciados,
      rondaActual: 0,
      dadosActuales: const [],
      indicesEnDisputaPorColor: const {},
      clearGanador: true,
    );
    _salas[sala.codigo] = salaEnJuego;
    return salaEnJuego;
  }

  /// Registra que un jugador ha confirmado sus 6 números iniciales de Setup.
  /// Si todos los jugadores activos ya confirmaron su Setup, inicia la Ronda 1 y tira los 2 dados.
  SalaPartida confirmarSetupJugador({
    required String codigo,
    required String jugadorId,
  }) {
    final sala = _obtenerSalaObligatoria(codigo);
    final indice = sala.jugadores.indexWhere((j) => j.id == jugadorId);
    if (indice == -1) {
      throw const RoomException('El jugador no pertenece a esta sala.');
    }

    final jugadoresActualizados = List<JugadorSala>.from(sala.jugadores);
    jugadoresActualizados[indice] = jugadoresActualizados[indice].copyWith(
      setupListo: true,
    );

    final salaActualizada = _verificarAvanceDeFaseORonda(
      sala.copyWith(jugadores: jugadoresActualizados),
    );
    _salas[sala.codigo] = salaActualizada;
    return salaActualizada;
  }

  /// Registra que un jugador completó una región de color [colorId] durante la ronda actual.
  SalaPartida registrarRegionCompletada({
    required String codigo,
    required String jugadorId,
    required String colorId,
  }) {
    final sala = _obtenerSalaObligatoria(codigo);
    final colorKey = colorId.trim().toLowerCase();
    if (colorKey.isNotEmpty) {
      final mapaRonda = _coloresCompletadosEnRonda.putIfAbsent(
        sala.codigo,
        () => {},
      );
      mapaRonda.putIfAbsent(colorKey, () => <String>{}).add(jugadorId);
    }
    return sala;
  }

  /// Registra que un jugador terminó su jugada (o pasó turno) en la ronda actual.
  /// Cuando todos los jugadores activos han completado su turno:
  /// 1. Adjudica los puntos de las regiones completadas en esa ronda (resolviendo empates simultáneos).
  /// 2. Avanza el puntaje en disputa de cada color completado (1.º -> 2.º -> 3.º).
  /// 3. Verifica la condición de victoria (21+ puntos o todos los tableros llenos) o lanza los dados de la siguiente ronda.
  SalaPartida completarTurnoJugador({
    required String codigo,
    required String jugadorId,
    List<String> coloresCompletados = const [],
    bool tableroLleno = false,
  }) {
    final sala = _obtenerSalaObligatoria(codigo);
    final indice = sala.jugadores.indexWhere((j) => j.id == jugadorId);
    if (indice == -1) {
      throw const RoomException('El jugador no pertenece a esta sala.');
    }

    final mapaRonda = _coloresCompletadosEnRonda.putIfAbsent(
      sala.codigo,
      () => {},
    );
    for (final rawColor in coloresCompletados) {
      final colorKey = rawColor.trim().toLowerCase();
      if (colorKey.isNotEmpty) {
        mapaRonda.putIfAbsent(colorKey, () => <String>{}).add(jugadorId);
      }
    }

    if (tableroLleno) {
      _tablerosLlenos.putIfAbsent(sala.codigo, () => <String>{}).add(jugadorId);
    }

    final jugadoresActualizados = List<JugadorSala>.from(sala.jugadores);
    jugadoresActualizados[indice] = jugadoresActualizados[indice].copyWith(
      turnoListo: true,
    );

    final salaActualizada = _verificarAvanceDeFaseORonda(
      sala.copyWith(jugadores: jugadoresActualizados),
    );
    _salas[sala.codigo] = salaActualizada;
    return salaActualizada;
  }

  SalaPartida _verificarAvanceDeFaseORonda(SalaPartida sala) {
    if (sala.estadoSala == EstadoSala.finalizada || !sala.partidaIniciada) {
      return sala;
    }

    final activos = sala.jugadores.where((j) => !j.abandono).toList();
    if (activos.isEmpty) {
      return sala;
    }

    // Caso 1: Fase de Setup -> pasar a Ronda 1 cuando todos los activos tengan setupListo
    if (sala.rondaActual == 0) {
      final todosSetupListos = activos.every((j) => j.setupListo);
      if (!todosSetupListos) {
        return sala;
      }

      final jugadoresRonda1 = sala.jugadores
          .map((j) => j.copyWith(turnoListo: false))
          .toList();

      return sala.copyWith(
        estadoSala: EstadoSala.enJuego,
        rondaActual: 1,
        dadosActuales: _tirarDados(),
        jugadores: jugadoresRonda1,
      );
    }

    // Caso 2: Fase de Rondas (rondaActual >= 1) -> cerrar ronda cuando todos los activos tengan turnoListo
    final todosTurnoListo = activos.every((j) => j.turnoListo);
    if (!todosTurnoListo) {
      return sala;
    }

    final indicesDisputa =
        Map<String, int>.from(sala.indicesEnDisputaPorColor);
    final puntosAcumulados = <String, int>{
      for (final j in sala.jugadores) j.id: j.puntos,
    };

    final completadosRonda = _coloresCompletadosEnRonda[sala.codigo];
    if (completadosRonda != null && completadosRonda.isNotEmpty) {
      for (final entry in completadosRonda.entries) {
        final colorId = entry.key;
        final jugadoresQueCompletaron = entry.value;
        if (jugadoresQueCompletaron.isEmpty) continue;

        final indiceEnDisputaActual = indicesDisputa[colorId] ?? 0;
        final lugar = indiceEnDisputaActual + 1;
        final puntosOtorgados = lugar <= 3
            ? ConstantesJuego.puntosPorColorYLugar(colorId, lugar)
            : 0;

        for (final jId in jugadoresQueCompletaron) {
          puntosAcumulados[jId] =
              (puntosAcumulados[jId] ?? 0) + puntosOtorgados;
        }

        // Avanza la puntuación en disputa para este color (0 -> 1 -> 2 -> 3)
        indicesDisputa[colorId] = (indiceEnDisputaActual + 1).clamp(0, 3);
      }
      completadosRonda.clear();
    }

    final jugadoresActualizados = sala.jugadores.map((j) {
      return j.copyWith(
        puntos: puntosAcumulados[j.id] ?? j.puntos,
        turnoListo: false,
      );
    }).toList();

    final activosActualizados =
        jugadoresActualizados.where((j) => !j.abandono).toList();
    final alguienAlcanzo21 = activosActualizados.any(
      (j) => j.puntos >= ConstantesJuego.puntosParaGanar,
    );
    final llenosSet = _tablerosLlenos[sala.codigo] ?? const <String>{};
    final todosTablerosLlenos = activosActualizados.isNotEmpty &&
        activosActualizados.every((j) => llenosSet.contains(j.id));

    if (alguienAlcanzo21 || todosTablerosLlenos) {
      JugadorSala ganador = activosActualizados.first;
      for (final candidato in activosActualizados.skip(1)) {
        if (candidato.puntos > ganador.puntos) {
          ganador = candidato;
        }
      }

      return sala.copyWith(
        estadoSala: EstadoSala.finalizada,
        jugadores: jugadoresActualizados,
        indicesEnDisputaPorColor: indicesDisputa,
        ganadorId: ganador.id,
      );
    }

    return sala.copyWith(
      estadoSala: EstadoSala.enJuego,
      rondaActual: sala.rondaActual + 1,
      dadosActuales: _tirarDados(),
      jugadores: jugadoresActualizados,
      indicesEnDisputaPorColor: indicesDisputa,
    );
  }

  /// Remueve a un jugador cuando sale voluntariamente o se desconecta.
  /// - Si la partida aún NO ha iniciado (Lobby): lo remueve de la lista.
  /// - Si la partida YA está iniciada: no lo elimina de la lista ni cierra la partida;
  ///   lo marca con `abandono: true` para que los demás jugadores puedan seguir jugando.
  /// - Solo si todos los jugadores han abandonado o la sala queda vacía se elimina la sala.
  SalaPartida? removerJugador({
    required String codigo,
    required String jugadorId,
  }) {
    final codigoLimpio = codigo.trim();
    final sala = _salas[codigoLimpio];
    if (sala == null) return null;

    if (sala.partidaIniciada) {
      final jugadoresMarcados = sala.jugadores.map((j) {
        if (j.id == jugadorId) {
          return j.copyWith(abandono: true, esHost: false);
        }
        return j;
      }).toList();

      final activos = jugadoresMarcados.where((j) => !j.abandono).toList();
      if (activos.isEmpty) {
        _salas.remove(codigoLimpio);
        _coloresCompletadosEnRonda.remove(codigoLimpio);
        _tablerosLlenos.remove(codigoLimpio);
        return null;
      }

      String nuevoGameMasterId = sala.gameMasterId;
      List<JugadorSala> listaFinal = jugadoresMarcados;

      if (sala.gameMasterId == jugadorId) {
        nuevoGameMasterId = activos.first.id;
        listaFinal = jugadoresMarcados.map((j) {
          if (j.id == nuevoGameMasterId) {
            return j.copyWith(esHost: true);
          }
          return j.copyWith(esHost: false);
        }).toList();
      }

      final salaEnCurso = _verificarAvanceDeFaseORonda(
        sala.copyWith(
          gameMasterId: nuevoGameMasterId,
          jugadores: listaFinal,
        ),
      );
      _salas[codigoLimpio] = salaEnCurso;
      return salaEnCurso;
    }

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
