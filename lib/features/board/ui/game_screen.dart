import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../constantes.dart';
import '../../../mapas_juego.dart';
import '../../../region.dart' as domain;
import '../../../tablero.dart';
import '../../auth/models/usuario.dart';
import '../../lobby/bloc/lobby_bloc.dart';
import '../../lobby/bloc/lobby_event.dart';
import '../../lobby/models/jugador_sala.dart';
import '../../lobby/models/sala_partida.dart';
import '../bloc/game_play_bloc.dart';
import '../bloc/setup_bloc.dart';

/// Información visual de una regla de región y sus puntuaciones en disputa.
class _ReglaZonaVisual {
  final String id;
  final String nombre;
  final String regla;
  final Color colorZona;
  final List<int> puntuaciones;
  final int indiceEnDisputa; // 0 = 1.er lugar, 1 = 2.º lugar, 2 = 3.er lugar

  const _ReglaZonaVisual({
    required this.id,
    required this.nombre,
    required this.regla,
    required this.colorZona,
    required this.puntuaciones,
    this.indiceEnDisputa = 0,
  });
}

/// Pantalla principal de Partida con distribución de 3 columnas (Opción A):
/// - Izquierda: Jugadores en vivo + Reglas y Puntos (con la puntuación en disputa encendida en el color de la zona).
/// - Centro: Tablero interactivo 7x7 del mapa elegido.
/// - Derecha: Panel de Acción (Fichas 1-6 en Fase de Setup).
class GameScreen extends StatefulWidget {
  final Usuario usuario;
  final SalaPartida sala;
  final VoidCallback onLeaveGame;

  const GameScreen({
    super.key,
    required this.usuario,
    required this.sala,
    required this.onLeaveGame,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final SetupBloc _setupBloc;
  late final MapaDefinicion _mapaDefinicion;
  late final Tablero _tablero;
  int? _numeroSeleccionado = 1;
  bool _setupConfirmadoLocalmente = false;

  // Estado de ronda activa (Fase 2: Gameplay)
  int _rondaProcesada = 0;
  int? _anclaIndex = 0;
  Casilla? _casillaJugadaEnRonda;
  bool _turnoConfirmadoEnRonda = false;

  @override
  void initState() {
    super.initState();
    _mapaDefinicion =
        MapasJuego.obtenerDefinicion(widget.sala.mapaSeleccionado);
    _tablero = MapasJuego.crearTablero(widget.sala.mapaSeleccionado);
    _setupBloc = SetupBloc()..add(StartSetup(_tablero));
    _sincronizarConSala(widget.sala);
  }

  @override
  void didUpdateWidget(covariant GameScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sala != widget.sala) {
      _sincronizarConSala(widget.sala);
    }
  }

  void _sincronizarConSala(SalaPartida sala) {
    final yo = sala.jugadores
        .where((j) => j.id == widget.usuario.id)
        .firstOrNull;
    if (yo != null && yo.setupListo) {
      _setupConfirmadoLocalmente = true;
    }

    if (sala.rondaActual != _rondaProcesada) {
      _rondaProcesada = sala.rondaActual;
      _casillaJugadaEnRonda = null;
      _turnoConfirmadoEnRonda = yo?.turnoListo ?? false;

      if (sala.dadosActuales.length >= 2) {
        final d0 = sala.dadosActuales[0];
        final d1 = sala.dadosActuales[1];
        final jugadaValida0 = calcularCasillasValidas(
          tablero: _tablero,
          valorAncla: d0,
          valorAColocar: d1,
        ).isNotEmpty;
        final jugadaValida1 = calcularCasillasValidas(
          tablero: _tablero,
          valorAncla: d1,
          valorAColocar: d0,
        ).isNotEmpty;

        if (jugadaValida0) {
          _anclaIndex = 0;
        } else if (jugadaValida1) {
          _anclaIndex = 1;
        } else {
          _anclaIndex = 0;
        }
      }
    }
  }

  void _despacharEventoLobby(LobbyEvent event) {
    try {
      context.read<LobbyBloc>().add(event);
    } catch (_) {
      // En pruebas aisladas de widget donde no se inyecta LobbyBloc
    }
  }

  @override
  void dispose() {
    _setupBloc.close();
    super.dispose();
  }

  Color _colorFlutterDeRegion(domain.Region region) {
    if (region is domain.TipoRojo) return const Color(0xFFEF4444);
    if (region is domain.TipoAzul) return const Color(0xFF3B82F6);
    if (region is domain.TipoVerde) return const Color(0xFF22C55E);
    if (region is domain.TipoAmarillo) return const Color(0xFFEAB308);
    if (region is domain.TipoMorado) return const Color(0xFFA855F7);
    if (region is domain.TipoGris) return const Color(0xFF94A3B8);
    if (region is domain.TipoNaranjaAlto) return const Color(0xFFF97316);
    if (region is domain.TipoNaranjaBajo) return const Color(0xFFFB923C);
    if (region is domain.TipoNaranja) return const Color(0xFFF97316);
    return const Color(0xFF64748B);
  }

  String _idColorDeRegion(domain.Region r) {
    if (r is domain.TipoRojo) return 'rojo';
    if (r is domain.TipoMorado) return 'morado';
    if (r is domain.TipoAzul) return 'azul';
    if (r is domain.TipoAmarillo) return 'amarillo';
    if (r is domain.TipoGris) return 'gris';
    if (r is domain.TipoNaranjaAlto) return 'naranja_alto';
    if (r is domain.TipoNaranjaBajo) return 'naranja_bajo';
    if (r is domain.TipoVerde) return 'verde';
    return r.runtimeType.toString().toLowerCase();
  }

  String _nombreDeRegion(domain.Region r) {
    if (r is domain.TipoRojo) return 'Zona Roja';
    if (r is domain.TipoMorado) return 'Zona Morada';
    if (r is domain.TipoAzul) return 'Zona Azul';
    if (r is domain.TipoAmarillo) return 'Zona Amarilla';
    if (r is domain.TipoGris) return 'Zona Gris';
    if (r is domain.TipoNaranjaAlto) return 'Naranja Alto (4-6)';
    if (r is domain.TipoNaranjaBajo) return 'Naranja Bajo (1-3)';
    if (r is domain.TipoVerde) return 'Zona Verde';
    return 'Zona';
  }

  List<_ReglaZonaVisual> _obtenerReglasDelMapa(Tablero tablero) {
    final tiposVistos = <String>{};
    final lista = <_ReglaZonaVisual>[];

    for (final grupo in tablero.regiones) {
      final r = grupo.tipoRegion;
      final id = _idColorDeRegion(r);
      final nombre = _nombreDeRegion(r);

      if (tiposVistos.add(id)) {
        final indiceEnDisputa =
            widget.sala.indicesEnDisputaPorColor[id] ?? 0;
        lista.add(
          _ReglaZonaVisual(
            id: id,
            nombre: nombre,
            regla: r.descripcion,
            colorZona: _colorFlutterDeRegion(r),
            puntuaciones: [
              r.puntuaciones[1] ?? 0,
              r.puntuaciones[2] ?? 0,
              r.puntuaciones[3] ?? 0,
            ],
            indiceEnDisputa: indiceEnDisputa,
          ),
        );
      }
    }

    return lista;
  }

  int? get _valorAnclaActual {
    if (widget.sala.dadosActuales.length < 2 || _anclaIndex == null) {
      return null;
    }
    return widget.sala.dadosActuales[_anclaIndex!];
  }

  int? get _valorAColocarActual {
    if (widget.sala.dadosActuales.length < 2 || _anclaIndex == null) {
      return null;
    }
    return widget.sala.dadosActuales[1 - _anclaIndex!];
  }

  /// Calcula las casillas válidas en la ronda actual (ignorando temporalmente la jugada provisional de esta misma ronda).
  List<Casilla> _calcularCasillasValidasRondaActual(Tablero tablero) {
    if (!widget.sala.enFaseRondas || _turnoConfirmadoEnRonda) {
      return const [];
    }
    final vAncla = _valorAnclaActual;
    final vColocar = _valorAColocarActual;
    if (vAncla == null || vColocar == null) return const [];

    final casillaProvisional = _casillaJugadaEnRonda;
    final valorProvisional = casillaProvisional?.valor;
    if (casillaProvisional != null) {
      casillaProvisional.valor = null;
    }

    final validas = calcularCasillasValidas(
      tablero: tablero,
      valorAncla: vAncla,
      valorAColocar: vColocar,
    );

    if (casillaProvisional != null) {
      casillaProvisional.valor = valorProvisional;
    }
    return validas;
  }

  void _seleccionarDadoAncla(int index) {
    if (_turnoConfirmadoEnRonda || !widget.sala.enFaseRondas) return;
    setState(() {
      if (_casillaJugadaEnRonda != null) {
        _casillaJugadaEnRonda!.valor = null;
        _casillaJugadaEnRonda = null;
      }
      _anclaIndex = index;
    });
  }

  void _deshacerJugadaEnRonda() {
    if (_turnoConfirmadoEnRonda || _casillaJugadaEnRonda == null) return;
    setState(() {
      _casillaJugadaEnRonda!.valor = null;
      _casillaJugadaEnRonda = null;
    });
  }

  void _confirmarJugadaRonda() {
    final casilla = _casillaJugadaEnRonda;
    if (casilla == null || _turnoConfirmadoEnRonda) return;

    final grupo = _tablero.regionDeCasilla(casilla.x, casilla.y);
    final coloresCompletados = <String>[];
    if (grupo != null && grupo.estaLlena) {
      coloresCompletados.add(_idColorDeRegion(grupo.tipoRegion));
    }

    final tableroLleno = _tablero.regiones.every((g) => g.estaLlena);

    setState(() {
      _turnoConfirmadoEnRonda = true;
    });

    _despacharEventoLobby(
      LobbyCompleteTurnRequested(
        coloresCompletados: coloresCompletados,
        tableroLleno: tableroLleno,
      ),
    );
  }

  void _pasarTurnoRonda() {
    if (_turnoConfirmadoEnRonda) return;
    setState(() {
      if (_casillaJugadaEnRonda != null) {
        _casillaJugadaEnRonda!.valor = null;
        _casillaJugadaEnRonda = null;
      }
      _turnoConfirmadoEnRonda = true;
    });

    final tableroLleno = _tablero.regiones.every((g) => g.estaLlena);
    _despacharEventoLobby(
      LobbyPassTurnRequested(tableroLleno: tableroLleno),
    );
  }

  void _onCasillaTapped(Casilla casilla, SetupState state) {
    if (widget.sala.estadoSala == EstadoSala.finalizada) return;

    if (widget.sala.enFaseRondas) {
      _onCasillaTappedEnRonda(casilla);
      return;
    }

    if (_setupConfirmadoLocalmente) return;

    final List<Casilla> requeridas;
    final Map<Casilla, int> ingresados;

    if (state is SetupAwaitingInputs) {
      requeridas = state.casillasRequeridas;
      ingresados = state.valoresIngresados;
    } else if (state is SetupCompleted) {
      requeridas = state.tablero.casillasInicialesPredefinidas;
      ingresados = {
        for (final c in requeridas)
          if (c.valor != null) c: c.valor!,
      };
    } else {
      return;
    }

    if (!requeridas.contains(casilla)) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF7F1D1D),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
          content: Text(
            'En la fase de Setup solo puedes colocar números en las 6 casillas iniciales resaltadas.',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
      return;
    }

    // Si la casilla ya tiene un valor y se toca de nuevo, lo quitamos
    if (ingresados.containsKey(casilla)) {
      final valorAnterior = ingresados[casilla];
      _setupBloc.add(ClearValue(casilla));
      setState(() {
        _numeroSeleccionado = valorAnterior;
      });
      return;
    }

    // Si hay un número seleccionado disponible, lo colocamos en la casilla
    final valorElegido = _numeroSeleccionado;
    if (valorElegido == null) return;

    if (ingresados.values.contains(valorElegido)) {
      return;
    }

    _setupBloc.add(InputValue(casilla, valorElegido));

    // Seleccionar automáticamente el siguiente número libre del 1 al 6
    final usadosAhora = {...ingresados.values, valorElegido};
    int? siguienteLibre;
    for (int n = 1; n <= 6; n++) {
      if (!usadosAhora.contains(n)) {
        siguienteLibre = n;
        break;
      }
    }
    setState(() {
      _numeroSeleccionado = siguienteLibre;
    });
  }

  void _onCasillaTappedEnRonda(Casilla casilla) {
    if (_turnoConfirmadoEnRonda) return;

    // Si toca la misma casilla donde acaba de poner su jugada provisional, la deshace
    if (identical(_casillaJugadaEnRonda, casilla)) {
      _deshacerJugadaEnRonda();
      return;
    }

    final vAncla = _valorAnclaActual;
    final vColocar = _valorAColocarActual;
    if (vAncla == null || vColocar == null) return;

    final validas = _calcularCasillasValidasRondaActual(_tablero);
    if (!validas.contains(casilla)) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF7F1D1D),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          content: Text(
            'Casilla inválida: debes colocar el $vColocar en una casilla vacía adyacente a un $vAncla (Ancla) respetando la regla de color.',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
      return;
    }

    setState(() {
      if (_casillaJugadaEnRonda != null) {
        _casillaJugadaEnRonda!.valor = null;
      }
      casilla.valor = vColocar;
      _casillaJugadaEnRonda = casilla;
    });
  }

  void _limpiarTodoSetup(SetupState state) {
    if (_setupConfirmadoLocalmente) return;
    final Tablero? tablero = switch (state) {
      SetupAwaitingInputs(:final tablero) => tablero,
      SetupCompleted(:final tablero) => tablero,
      _ => null,
    };
    if (tablero == null) return;

    for (final c in tablero.casillasInicialesPredefinidas) {
      c.valor = null;
    }
    _setupBloc.add(StartSetup(tablero));
    setState(() {
      _numeroSeleccionado = 1;
    });
  }

  Future<void> _confirmarSalidaPartida() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF141728),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: Color(0xFF2B3356), width: 1.5),
        ),
        title: const Row(
          children: [
            FaIcon(
              FontAwesomeIcons.rightFromBracket,
              color: Color(0xFFF43F5E),
              size: 18,
            ),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                '¿Salir de la partida?',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        content: const Text(
          '¿Estás seguro de que deseas abandonar la partida actual y volver al menú principal?',
          style: TextStyle(
            color: Color(0xFFCBD5E1),
            fontSize: 14,
            height: 1.45,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text(
              'Continuar jugando',
              style: TextStyle(color: Color(0xFF94A3B8)),
            ),
          ),
          ElevatedButton(
            key: const Key('confirm_leave_game_button'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE11D48),
              foregroundColor: Colors.white,
            ),
            child: const Text('Salir al menú'),
          ),
        ],
      ),
    );

    if (confirmar == true && mounted) {
      widget.onLeaveGame();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SetupBloc>.value(
      value: _setupBloc,
      child: BlocBuilder<SetupBloc, SetupState>(
        builder: (context, setupState) {
          final Tablero tablero = _tablero;

          final List<Casilla> casillasIniciales = switch (setupState) {
            SetupAwaitingInputs(:final casillasRequeridas) =>
              casillasRequeridas,
            SetupCompleted(:final tablero) =>
              tablero.casillasInicialesPredefinidas,
            _ => tablero.casillasInicialesPredefinidas,
          };

          final Map<Casilla, int> valoresColocados = {
            for (final c in casillasIniciales)
              if (c.valor != null) c: c.valor!,
          };

          final bool todosColocados =
              valoresColocados.length == ConstantesJuego.cantidadValoresIniciales;

          return Scaffold(
            backgroundColor: const Color(0xFF0C0E1A),
            appBar: _buildHeaderAppBar(),
            body: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final bool isWide = constraints.maxWidth >= 980;

                  final leftRulesColumn = _buildLeftRulesColumn(
                    tablero: tablero,
                  );
                  final topScoresSection = _buildTopPlayersScoresSection();
                  final diceResultsSection = _buildDiceResultsSection();
                  final centerBoard = _buildCenterBoardSection(
                    tablero: tablero,
                    casillasIniciales: casillasIniciales,
                    setupState: setupState,
                  );
                  final rightColumn = _buildRightActionColumn(
                    tablero: tablero,
                    setupState: setupState,
                    valoresColocados: valoresColocados,
                    todosColocados: todosColocados,
                  );

                  final centerStack = Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 1. Apartado de Puntuaciones (encima de todo en la columna central)
                      topScoresSection,
                      const SizedBox(height: 14),
                      // 2. Apartado de Resultados de los Dados (entre las puntuaciones y el tablero)
                      diceResultsSection,
                      const SizedBox(height: 14),
                      // 3. Tablero 7x7 (debajo de los dados)
                      centerBoard,
                    ],
                  );

                  if (isWide) {
                    return Padding(
                      padding: const EdgeInsets.all(18),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 290,
                            child: SingleChildScrollView(
                              child: leftRulesColumn,
                            ),
                          ),
                          const SizedBox(width: 18),
                          Expanded(
                            child: SingleChildScrollView(
                              child: Center(
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 560,
                                  ),
                                  child: centerStack,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 18),
                          SizedBox(
                            width: 280,
                            child: SingleChildScrollView(child: rightColumn),
                          ),
                        ],
                      ),
                    );
                  }

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        centerStack,
                        const SizedBox(height: 16),
                        rightColumn,
                        const SizedBox(height: 16),
                        leftRulesColumn,
                      ],
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildHeaderAppBar() {
    final bool enRondas = widget.sala.enFaseRondas;
    final bool finalizada = widget.sala.estadoSala == EstadoSala.finalizada;
    final bool badgeVerde = finalizada ||
        (enRondas ? _turnoConfirmadoEnRonda : _setupConfirmadoLocalmente);

    final String textoFase;
    if (finalizada) {
      textoFase = 'PARTIDA FINALIZADA';
    } else if (enRondas) {
      textoFase = _turnoConfirmadoEnRonda
          ? 'RONDA ${widget.sala.rondaActual} • JUGADA LISTA'
          : 'RONDA ${widget.sala.rondaActual} EN JUEGO';
    } else {
      textoFase = _setupConfirmadoLocalmente
          ? 'SETUP CONFIRMADO'
          : 'FASE DE SETUP';
    }

    return AppBar(
      backgroundColor: const Color(0xFF141728),
      elevation: 0,
      leading: IconButton(
        key: const Key('game_leave_button'),
        tooltip: 'Salir de la Partida',
        onPressed: _confirmarSalidaPartida,
        icon: const FaIcon(
          FontAwesomeIcons.arrowLeft,
          color: Colors.white,
          size: 16,
        ),
      ),
      title: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 10,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const FaIcon(
              FontAwesomeIcons.diceD6,
              color: Colors.white,
              size: 14,
            ),
          ),
          Text(
            'Sala #${widget.sala.codigo} • ${_mapaDefinicion.titulo}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: badgeVerde
                    ? const Color(0xFF10B981).withValues(alpha: 0.18)
                    : const Color(0xFFF59E0B).withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: badgeVerde
                      ? const Color(0xFF10B981)
                      : const Color(0xFFF59E0B),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FaIcon(
                    badgeVerde
                        ? FontAwesomeIcons.circleCheck
                        : (enRondas
                            ? FontAwesomeIcons.dice
                            : FontAwesomeIcons.sliders),
                    size: 12,
                    color: badgeVerde
                        ? const Color(0xFF10B981)
                        : const Color(0xFFFBBF24),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    textoFase,
                    style: TextStyle(
                      color: badgeVerde
                          ? const Color(0xFF10B981)
                          : const Color(0xFFFBBF24),
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Apartado de Puntuaciones ubicado encima del tablero (con resultados de dados en medio).
  Widget _buildTopPlayersScoresSection() {
    return Container(
      key: const Key('players_scores_top_section'),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF141728),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF222845)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              FaIcon(
                FontAwesomeIcons.trophy,
                color: Color(0xFFF59E0B),
                size: 13,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'PUNTUACIONES DE LA SALA (META: 21 PUNTOS)',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: widget.sala.jugadores.map((JugadorSala j) {
              final esTu = j.id == widget.usuario.id;
              final haAbandonado = j.abandono;
              final esGanador =
                  widget.sala.estadoSala == EstadoSala.finalizada &&
                  widget.sala.ganadorId == j.id;

              late final String textoEstado;
              late final Color colorEstado;

              if (haAbandonado) {
                textoEstado = 'Abandonó la partida';
                colorEstado = const Color(0xFFF43F5E);
              } else if (widget.sala.estadoSala == EstadoSala.finalizada) {
                textoEstado = esGanador ? '¡GANADOR!' : 'Partida finalizada';
                colorEstado = esGanador
                    ? const Color(0xFFFBBF24)
                    : const Color(0xFF94A3B8);
              } else if (widget.sala.enFaseRondas) {
                final turnoListo =
                    j.turnoListo || (esTu && _turnoConfirmadoEnRonda);
                textoEstado = turnoListo
                    ? 'Jugada lista'
                    : 'Ronda ${widget.sala.rondaActual}';
                colorEstado = turnoListo
                    ? const Color(0xFF10B981)
                    : const Color(0xFF38BDF8);
              } else {
                final listoEnSetup =
                    j.setupListo || (esTu && _setupConfirmadoLocalmente);
                textoEstado = listoEnSetup ? 'Setup listo' : 'En preparación';
                colorEstado = listoEnSetup
                    ? const Color(0xFF10B981)
                    : const Color(0xFF94A3B8);
              }

              return Opacity(
                opacity: haAbandonado ? 0.6 : 1.0,
                child: Container(
                  key: Key('game_player_score_card_${j.id}'),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0C0E1A),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: haAbandonado
                          ? const Color(0xFF7F1D1D)
                          : (esGanador
                              ? const Color(0xFFFBBF24)
                              : (esTu
                                  ? const Color(0xFF3B82F6)
                                  : const Color(0xFF1E293B))),
                      width: (esTu || esGanador) ? 1.5 : 1.0,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FaIcon(
                        haAbandonado
                            ? FontAwesomeIcons.userSlash
                            : (esGanador
                                ? FontAwesomeIcons.trophy
                                : (j.esHost
                                    ? FontAwesomeIcons.crown
                                    : FontAwesomeIcons.userAstronaut)),
                        color: haAbandonado
                            ? const Color(0xFFF43F5E)
                            : (esGanador
                                ? const Color(0xFFFBBF24)
                                : (j.esHost
                                    ? const Color(0xFFF59E0B)
                                    : const Color(0xFF38BDF8))),
                        size: 12,
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            esTu ? '${j.nombre} (TÚ)' : j.nombre,
                            style: TextStyle(
                              color: haAbandonado
                                  ? const Color(0xFF94A3B8)
                                  : Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                              decoration: haAbandonado
                                  ? TextDecoration.lineThrough
                                  : TextDecoration.none,
                            ),
                          ),
                          Text(
                            textoEstado,
                            style: TextStyle(
                              color: colorEstado,
                              fontSize: 10,
                              fontWeight: (haAbandonado || esGanador)
                                  ? FontWeight.w700
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFFF59E0B)
                                .withValues(alpha: 0.4),
                          ),
                        ),
                        child: Text(
                          '${j.puntos} pts',
                          style: const TextStyle(
                            color: Color(0xFFFBBF24),
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  /// Apartado de Resultados de los Dados ubicado entre las puntuaciones y el tablero.
  Widget _buildDiceResultsSection() {
    final hayDados = widget.sala.dadosActuales.length >= 2;
    final dado1 = hayDados ? widget.sala.dadosActuales[0] : null;
    final dado2 = hayDados ? widget.sala.dadosActuales[1] : null;

    final subtexto = hayDados
        ? 'Ronda ${widget.sala.rondaActual} • Toca un dado para elegirlo como ANCLA y colocar el OTRO en una casilla vecina'
        : 'Se lanzarán al finalizar la fase de Setup de todos los jugadores';

    return Container(
      key: const Key('dice_results_section'),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E1B4B), Color(0xFF141728)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF4338CA), width: 1.3),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 16,
        runSpacing: 12,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const FaIcon(
                    FontAwesomeIcons.dice,
                    color: Color(0xFFA855F7),
                    size: 14,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    hayDados
                        ? 'RESULTADOS DE LOS DADOS • RONDA ${widget.sala.rondaActual}'
                        : 'RESULTADOS DE LOS DADOS',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.9,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                subtexto,
                style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 11,
                ),
              ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDieBox(
                index: 0,
                label: 'DADO 1',
                valor: dado1,
              ),
              const SizedBox(width: 10),
              _buildDieBox(
                index: 1,
                label: 'DADO 2',
                valor: dado2,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDieBox({
    required int index,
    required String label,
    required int? valor,
  }) {
    final bool activo = valor != null && widget.sala.enFaseRondas;
    final bool esAncla = activo && _anclaIndex == index;
    final bool esColocar =
        activo && _anclaIndex != null && _anclaIndex != index;

    return InkWell(
      key: Key('die_card_$index'),
      borderRadius: BorderRadius.circular(12),
      onTap: (activo && !_turnoConfirmadoEnRonda)
          ? () => _seleccionarDadoAncla(index)
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: esAncla
              ? const Color(0xFF312E81)
              : (esColocar
                  ? const Color(0xFF064E3B)
                  : const Color(0xFF0C0E1A)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: esAncla
                ? const Color(0xFF818CF8)
                : (esColocar
                    ? const Color(0xFF10B981)
                    : const Color(0xFF312E81)),
            width: (esAncla || esColocar) ? 2.0 : 1.4,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FaIcon(
              esAncla ? FontAwesomeIcons.anchor : FontAwesomeIcons.diceD6,
              color: esAncla
                  ? const Color(0xFFA5B4FC)
                  : (esColocar
                      ? const Color(0xFF34D399)
                      : const Color(0xFF6366F1)),
              size: 16,
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  esAncla
                      ? '$label • ANCLA'
                      : (esColocar ? '$label • COLOCAR' : label),
                  style: TextStyle(
                    color: esAncla
                        ? const Color(0xFFC7D2FE)
                        : (esColocar
                            ? const Color(0xFF6EE7B7)
                            : const Color(0xFF94A3B8)),
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  valor != null ? '$valor' : '-',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Columna Izquierda: Reglas y Puntos en Disputa (con puntuación en disputa encendida del color de la zona).
  Widget _buildLeftRulesColumn({required Tablero tablero}) {
    final reglas = _obtenerReglasDelMapa(tablero);

    return Container(
      key: const Key('rules_and_points_panel'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF141728),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF222845)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              FaIcon(
                FontAwesomeIcons.palette,
                color: Color(0xFF38BDF8),
                size: 14,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'REGLAS Y PUNTOS EN DISPUTA',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'El puntaje encendido en el color de la zona es el que está actualmente en juego:',
            style: TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 11,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),
          ...reglas.map(_buildReglaZonaCard),
        ],
      ),
    );
  }

  /// Construye la tarjeta de una zona mostrando sus 3 escalas (1.º, 2.º, 3.º)
  /// y encendiendo en el color de la zona únicamente la puntuación en disputa.
  Widget _buildReglaZonaCard(_ReglaZonaVisual regla) {
    return Container(
      key: Key('rule_card_${regla.id}'),
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0C0E1A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: regla.colorZona.withValues(alpha: 0.45),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: regla.colorZona,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: regla.colorZona.withValues(alpha: 0.6),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  regla.nombre,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
              // Los 3 puestos de puntuación (1.º, 2.º, 3.º): el que está en disputa se enciende con el color de la zona
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(regla.puntuaciones.length, (idx) {
                  final pts = regla.puntuaciones[idx];
                  final bool enDisputa = idx == regla.indiceEnDisputa;

                  return Container(
                    key: Key('score_badge_${regla.id}_${idx + 1}'),
                    margin: const EdgeInsets.only(left: 6),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: enDisputa
                          ? regla.colorZona
                          : const Color(0xFF141728),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: enDisputa
                            ? Colors.white.withValues(alpha: 0.85)
                            : const Color(0xFF262D47),
                        width: enDisputa ? 1.5 : 1.0,
                      ),
                      boxShadow: enDisputa
                          ? [
                              BoxShadow(
                                color: regla.colorZona.withValues(alpha: 0.55),
                                blurRadius: 10,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                    ),
                    child: Text(
                      '$pts',
                      style: TextStyle(
                        color: enDisputa
                            ? Colors.white
                            : const Color(0xFF475569),
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            regla.regla,
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 11,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }

  /// Columna Central: Tablero interactivo de 7x7 con las 6 casillas iniciales resaltadas.
  Widget _buildCenterBoardSection({
    required Tablero tablero,
    required List<Casilla> casillasIniciales,
    required SetupState setupState,
  }) {
    final inicialesSet = casillasIniciales.toSet();
    final validasRondaSet =
        _calcularCasillasValidasRondaActual(tablero).toSet();
    final vAncla = _valorAnclaActual;
    final vColocar = _valorAColocarActual;

    final String subtituloTablero;
    if (widget.sala.estadoSala == EstadoSala.finalizada) {
      final ganador = widget.sala.jugadores
          .where((j) => j.id == widget.sala.ganadorId)
          .firstOrNull;
      subtituloTablero = ganador != null
          ? '¡Partida finalizada! Ganador: ${ganador.nombre} (${ganador.puntos} pts)'
          : '¡Partida finalizada!';
    } else if (widget.sala.enFaseRondas) {
      if (_turnoConfirmadoEnRonda) {
        subtituloTablero =
            'Jugada de la Ronda ${widget.sala.rondaActual} confirmada • Esperando a los demás jugadores...';
      } else if (vAncla != null && vColocar != null) {
        subtituloTablero =
            'Toca una casilla con borde verde brillante (vecina de un $vAncla) para colocar el $vColocar';
      } else {
        subtituloTablero =
            'Selecciona un dado como Ancla para ver tus casillas disponibles';
      }
    } else {
      subtituloTablero =
          'Las 6 casillas con borde dorado son tus casillas iniciales de preparación';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF141728),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF2B3356), width: 1.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const FaIcon(
                FontAwesomeIcons.tableCells,
                color: Color(0xFF38BDF8),
                size: 15,
              ),
              const SizedBox(width: 8),
              Text(
                _mapaDefinicion.titulo.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            subtituloTablero,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 470, maxHeight: 470),
            child: AspectRatio(
              aspectRatio: 1.0,
              child: Column(
                children: List.generate(tablero.alto, (y) {
                  return Expanded(
                    child: Row(
                      children: List.generate(tablero.ancho, (x) {
                        final casilla = tablero.getCasilla(x, y);
                        final grupo = tablero.regionDeCasilla(x, y);
                        final esInicial = inicialesSet.contains(casilla);
                        final esValidaRonda = validasRondaSet.contains(casilla);
                        final esJugadaActual =
                            identical(_casillaJugadaEnRonda, casilla);
                        final esAnclaEnTablero = widget.sala.enFaseRondas &&
                            !esJugadaActual &&
                            vAncla != null &&
                            casilla.valor == vAncla;

                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(3.0),
                            child: _buildBoardCell(
                              casilla: casilla,
                              grupo: grupo,
                              esCasillaInicial: esInicial,
                              esValidaRonda: esValidaRonda,
                              esJugadaActual: esJugadaActual,
                              esAnclaEnTablero: esAnclaEnTablero,
                              valorAColocar: vColocar,
                              setupState: setupState,
                            ),
                          ),
                        );
                      }),
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBoardCell({
    required Casilla casilla,
    required GrupoRegion? grupo,
    required bool esCasillaInicial,
    required bool esValidaRonda,
    required bool esJugadaActual,
    required bool esAnclaEnTablero,
    required int? valorAColocar,
    required SetupState setupState,
  }) {
    final colorRegion = grupo != null
        ? _colorFlutterDeRegion(grupo.tipoRegion)
        : const Color(0xFF334155);
    final tieneValor = casilla.valor != null;
    final enSetup = widget.sala.enFaseSetup;

    Color borderColor = colorRegion.withValues(alpha: 0.75);
    double borderWidth = 1.2;
    List<BoxShadow>? shadows;

    if (esJugadaActual) {
      borderColor = const Color(0xFF34D399);
      borderWidth = 2.8;
      shadows = [
        BoxShadow(
          color: const Color(0xFF10B981).withValues(alpha: 0.55),
          blurRadius: 10,
          spreadRadius: 1,
        ),
      ];
    } else if (esValidaRonda && !_turnoConfirmadoEnRonda) {
      borderColor = const Color(0xFF6EE7B7);
      borderWidth = 2.4;
      shadows = [
        BoxShadow(
          color: const Color(0xFF10B981).withValues(alpha: 0.35),
          blurRadius: 8,
          spreadRadius: 0.5,
        ),
      ];
    } else if (esAnclaEnTablero) {
      borderColor = const Color(0xFFA5B4FC);
      borderWidth = 2.3;
    } else if (esCasillaInicial && enSetup) {
      borderColor = const Color(0xFFFDE047);
      borderWidth = 2.6;
      shadows = [
        BoxShadow(
          color: const Color(0xFFFACC15).withValues(alpha: 0.35),
          blurRadius: 8,
          spreadRadius: 0.5,
        ),
      ];
    }

    return InkWell(
      key: Key('board_cell_${casilla.x}_${casilla.y}'),
      borderRadius: BorderRadius.circular(12),
      onTap: () => _onCasillaTapped(casilla, setupState),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        decoration: BoxDecoration(
          color: tieneValor
              ? colorRegion.withValues(alpha: 0.90)
              : (esValidaRonda
                  ? colorRegion.withValues(alpha: 0.58)
                  : (esCasillaInicial && enSetup
                      ? colorRegion.withValues(alpha: 0.68)
                      : colorRegion.withValues(alpha: 0.32))),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: borderColor,
            width: borderWidth,
          ),
          boxShadow: shadows,
        ),
        child: Stack(
          children: [
            if (esCasillaInicial && enSetup)
              Positioned(
                top: 4,
                right: 4,
                child: FaIcon(
                  FontAwesomeIcons.solidStar,
                  size: 8,
                  color: const Color(0xFFFEF08A).withValues(alpha: 0.95),
                ),
              ),
            if (esAnclaEnTablero)
              Positioned(
                top: 4,
                right: 4,
                child: FaIcon(
                  FontAwesomeIcons.anchor,
                  size: 8,
                  color: const Color(0xFFC7D2FE).withValues(alpha: 0.95),
                ),
              ),
            Center(
              child: tieneValor
                  ? Text(
                      '${casilla.valor}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        shadows: [
                          Shadow(
                            color: Colors.black54,
                            blurRadius: 4,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                    )
                  : (esValidaRonda &&
                          !_turnoConfirmadoEnRonda &&
                          valorAColocar != null
                      ? Text(
                          '+$valorAColocar',
                          style: TextStyle(
                            color: const Color(0xFFD1FAE5)
                                .withValues(alpha: 0.85),
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                          ),
                        )
                      : (esCasillaInicial && enSetup
                          ? Text(
                              '?',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.75),
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            )
                          : const SizedBox.shrink())),
            ),
          ],
        ),
      ),
    );
  }

  /// Selecciona qué panel derecho mostrar según la fase de la partida.
  Widget _buildRightActionColumn({
    required Tablero tablero,
    required SetupState setupState,
    required Map<Casilla, int> valoresColocados,
    required bool todosColocados,
  }) {
    if (widget.sala.estadoSala == EstadoSala.finalizada) {
      return _buildRightGameOverPanel();
    }
    if (widget.sala.enFaseRondas) {
      return _buildRightGameplayActionPanel(tablero: tablero);
    }
    return _buildRightSetupActionPanel(
      setupState: setupState,
      valoresColocados: valoresColocados,
      todosColocados: todosColocados,
    );
  }

  /// Columna Derecha durante Fase 2 (Rondas con Dados): Elección de Ancla, Confirmar Jugada y Pasar Turno.
  Widget _buildRightGameplayActionPanel({required Tablero tablero}) {
    final hayDados = widget.sala.dadosActuales.length >= 2;
    final d0 = hayDados ? widget.sala.dadosActuales[0] : 1;
    final d1 = hayDados ? widget.sala.dadosActuales[1] : 1;
    final vAncla = _valorAnclaActual;
    final vColocar = _valorAColocarActual;
    final validas = _calcularCasillasValidasRondaActual(tablero);

    GrupoRegion? grupoCompletadoProvisional;
    if (_casillaJugadaEnRonda != null) {
      final g = tablero.regionDeCasilla(
        _casillaJugadaEnRonda!.x,
        _casillaJugadaEnRonda!.y,
      );
      if (g != null && g.estaLlena) {
        grupoCompletadoProvisional = g;
      }
    }

    return Container(
      key: const Key('gameplay_action_panel'),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF141728),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF222845)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const FaIcon(
                FontAwesomeIcons.compass,
                color: Color(0xFF38BDF8),
                size: 14,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'PANEL DE ACCIÓN • RONDA ${widget.sala.rondaActual}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            '1. Elige cuál dado usarás como ANCLA (debe estar en tu tablero).\n'
            '2. Toca una casilla vecina válida para colocar el OTRO dado.\n'
            '3. Confirma tu jugada o pasa el turno.',
            style: TextStyle(
              color: Color(0xFFCBD5E1),
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),

          // Botones selectores de combinación Ancla -> Colocar
          _buildAnchorOptionTile(
            index: 0,
            valorAncla: d0,
            valorColocar: d1,
            seleccionado: _anclaIndex == 0,
          ),
          const SizedBox(height: 8),
          _buildAnchorOptionTile(
            index: 1,
            valorAncla: d1,
            valorColocar: d0,
            seleccionado: _anclaIndex == 1,
          ),

          const SizedBox(height: 14),

          // Resumen de casillas válidas o jugada colocada
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF0C0E1A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _casillaJugadaEnRonda != null
                    ? const Color(0xFF10B981)
                    : const Color(0xFF1E293B),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _casillaJugadaEnRonda != null
                      ? 'Número $vColocar colocado en (${_casillaJugadaEnRonda!.y + 1}, ${_casillaJugadaEnRonda!.x + 1})'
                      : 'Casillas disponibles con este Ancla: ${validas.length}',
                  style: TextStyle(
                    color: _casillaJugadaEnRonda != null
                        ? const Color(0xFF34D399)
                        : Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
                if (grupoCompletadoProvisional != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    '¡Completas ${_nombreDeRegion(grupoCompletadoProvisional.tipoRegion)}!',
                    style: const TextStyle(
                      color: Color(0xFFFBBF24),
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                    ),
                  ),
                ],
                if (_casillaJugadaEnRonda == null &&
                    validas.isEmpty &&
                    vAncla != null) ...[
                  const SizedBox(height: 4),
                  const Text(
                    'Prueba cambiando al otro dado Ancla o pasa tu turno si no tienes jugada posible.',
                    style: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 14),

          if (_casillaJugadaEnRonda != null && !_turnoConfirmadoEnRonda) ...[
            OutlinedButton.icon(
              key: const Key('undo_turn_move_button'),
              onPressed: _deshacerJugadaEnRonda,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFCBD5E1),
                side: const BorderSide(color: Color(0xFF334155)),
                padding: const EdgeInsets.symmetric(vertical: 11),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const FaIcon(FontAwesomeIcons.rotateLeft, size: 12),
              label: const Text(
                'Cambiar casilla',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 10),
          ],

          // Botón Confirmar Jugada
          SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              key: const Key('confirm_turn_button'),
              onPressed:
                  (_casillaJugadaEnRonda != null && !_turnoConfirmadoEnRonda)
                      ? _confirmarJugadaRonda
                      : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFF1E293B),
                disabledForegroundColor: const Color(0xFF64748B),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: FaIcon(
                _turnoConfirmadoEnRonda
                    ? FontAwesomeIcons.lock
                    : FontAwesomeIcons.circleCheck,
                size: 15,
              ),
              label: Text(
                _turnoConfirmadoEnRonda
                    ? 'JUGADA CONFIRMADA'
                    : 'CONFIRMAR JUGADA',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Botón Pasar Turno
          OutlinedButton.icon(
            key: const Key('pass_turn_button'),
            onPressed: _turnoConfirmadoEnRonda ? null : _pasarTurnoRonda,
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFFBBF24),
              side: BorderSide(
                color: _turnoConfirmadoEnRonda
                    ? const Color(0xFF1E293B)
                    : const Color(0xFFF59E0B).withValues(alpha: 0.6),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const FaIcon(FontAwesomeIcons.forwardStep, size: 13),
            label: const Text(
              'PASAR TURNO',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnchorOptionTile({
    required int index,
    required int valorAncla,
    required int valorColocar,
    required bool seleccionado,
  }) {
    return InkWell(
      key: Key('select_anchor_${index}_button'),
      borderRadius: BorderRadius.circular(12),
      onTap: _turnoConfirmadoEnRonda
          ? null
          : () => _seleccionarDadoAncla(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: seleccionado
              ? const Color(0xFF312E81)
              : const Color(0xFF0C0E1A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: seleccionado
                ? const Color(0xFF818CF8)
                : const Color(0xFF1E293B),
            width: seleccionado ? 1.8 : 1.0,
          ),
        ),
        child: Row(
          children: [
            FaIcon(
              FontAwesomeIcons.anchor,
              size: 13,
              color: seleccionado
                  ? const Color(0xFFA5B4FC)
                  : const Color(0xFF64748B),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Ancla $valorAncla  ➔  Colocar $valorColocar',
                style: TextStyle(
                  color: seleccionado
                      ? Colors.white
                      : const Color(0xFF94A3B8),
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ),
            if (seleccionado)
              const FaIcon(
                FontAwesomeIcons.circleCheck,
                size: 13,
                color: Color(0xFF34D399),
              ),
          ],
        ),
      ),
    );
  }

  /// Panel derecho cuando la partida ha concluido (alguien alcanzó 21+ puntos).
  Widget _buildRightGameOverPanel() {
    final ordenados = List<JugadorSala>.from(widget.sala.jugadores)
      ..sort((a, b) => b.puntos.compareTo(a.puntos));

    return Container(
      key: const Key('game_over_panel'),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF141728),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF59E0B), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              FaIcon(
                FontAwesomeIcons.trophy,
                color: Color(0xFFFBBF24),
                size: 16,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'PODIO FINAL DE LA PARTIDA',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...List.generate(ordenados.length, (idx) {
            final j = ordenados[idx];
            final esGanador = j.id == widget.sala.ganadorId;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF0C0E1A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: esGanador
                      ? const Color(0xFFFBBF24)
                      : const Color(0xFF1E293B),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${idx + 1}.º ${j.nombre}',
                    style: TextStyle(
                      color: esGanador
                          ? const Color(0xFFFDE047)
                          : Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    '${j.puntos} pts',
                    style: const TextStyle(
                      color: Color(0xFFFBBF24),
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 12),
          SizedBox(
            height: 46,
            child: ElevatedButton.icon(
              key: const Key('return_menu_after_game_button'),
              onPressed: widget.onLeaveGame,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const FaIcon(FontAwesomeIcons.house, size: 14),
              label: const Text(
                'VOLVER AL MENÚ PRINCIPAL',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Columna Derecha: Panel de Acción de Setup (fichas del 1 al 6 y confirmación).
  Widget _buildRightSetupActionPanel({
    required SetupState setupState,
    required Map<Casilla, int> valoresColocados,
    required bool todosColocados,
  }) {
    final usados = valoresColocados.values.toSet();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF141728),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF222845)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              FaIcon(
                FontAwesomeIcons.handPointer,
                color: Color(0xFFA855F7),
                size: 14,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'PANEL DE ACCIÓN • SETUP',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            '1. Elige un número del 1 al 6.\n'
            '2. Toca cualquiera de las 6 casillas iniciales con borde dorado para colocarlo.\n'
            '3. Toca una casilla ocupada si deseas cambiar su número.',
            style: TextStyle(
              color: Color(0xFFCBD5E1),
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),

          // Cuadrícula de números 1 al 6
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: List.generate(6, (index) {
              final numero = index + 1;
              final yaColocado = usados.contains(numero);
              final seleccionado =
                  !yaColocado && _numeroSeleccionado == numero;

              return InkWell(
                key: Key('setup_number_chip_$numero'),
                borderRadius: BorderRadius.circular(14),
                onTap: (yaColocado || _setupConfirmadoLocalmente)
                    ? null
                    : () {
                        setState(() {
                          _numeroSeleccionado = numero;
                        });
                      },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 72,
                  height: 62,
                  decoration: BoxDecoration(
                    color: yaColocado
                        ? const Color(0xFF0C0E1A)
                        : (seleccionado
                            ? const Color(0xFF7C3AED)
                            : const Color(0xFF1E293B)),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: yaColocado
                          ? const Color(0xFF10B981).withValues(alpha: 0.5)
                          : (seleccionado
                              ? Colors.white
                              : const Color(0xFF334155)),
                      width: seleccionado ? 2.2 : 1.2,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$numero',
                        style: TextStyle(
                          color: yaColocado
                              ? const Color(0xFF475569)
                              : Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      if (yaColocado)
                        const FaIcon(
                          FontAwesomeIcons.check,
                          size: 10,
                          color: Color(0xFF10B981),
                        ),
                    ],
                  ),
                ),
              );
            }),
          ),

          const SizedBox(height: 18),

          // Indicador de progreso
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF0C0E1A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF1E293B)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Casillas iniciales listas:',
                  style: TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 12,
                  ),
                ),
                Text(
                  '${valoresColocados.length} / ${ConstantesJuego.cantidadValoresIniciales}',
                  style: TextStyle(
                    color: todosColocados
                        ? const Color(0xFF10B981)
                        : const Color(0xFF38BDF8),
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Botón Limpiar Todo
          OutlinedButton.icon(
            key: const Key('setup_clear_all_button'),
            onPressed:
                (_setupConfirmadoLocalmente || valoresColocados.isEmpty)
                    ? null
                    : () => _limpiarTodoSetup(setupState),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFCBD5E1),
              side: const BorderSide(color: Color(0xFF334155)),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const FaIcon(FontAwesomeIcons.trashCan, size: 13),
            label: const Text(
              'Limpiar Todo',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),

          const SizedBox(height: 10),

          // Botón Confirmar Setup
          SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              key: const Key('setup_confirm_button'),
              onPressed: (todosColocados && !_setupConfirmadoLocalmente)
                  ? () {
                      setState(() {
                        _setupConfirmadoLocalmente = true;
                      });
                      _despacharEventoLobby(
                        const LobbyCompleteSetupRequested(),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          backgroundColor: Color(0xFF065F46),
                          behavior: SnackBarBehavior.floating,
                          content: Text(
                            '¡Tablero inicial confirmado! Esperando al resto de jugadores...',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      );
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFF1E293B),
                disabledForegroundColor: const Color(0xFF64748B),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: FaIcon(
                _setupConfirmadoLocalmente
                    ? FontAwesomeIcons.lock
                    : FontAwesomeIcons.circleCheck,
                size: 15,
              ),
              label: Text(
                _setupConfirmadoLocalmente
                    ? 'SETUP CONFIRMADO'
                    : 'CONFIRMAR SETUP',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
