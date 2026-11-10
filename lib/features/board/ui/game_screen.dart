import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../constantes.dart';
import '../../../mapas_juego.dart';
import '../../../region.dart' as domain;
import '../../../tablero.dart';
import '../../auth/models/usuario.dart';
import '../../lobby/models/jugador_sala.dart';
import '../../lobby/models/sala_partida.dart';
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
  int? _numeroSeleccionado = 1;
  bool _setupConfirmadoLocalmente = false;

  @override
  void initState() {
    super.initState();
    _mapaDefinicion =
        MapasJuego.obtenerDefinicion(widget.sala.mapaSeleccionado);
    final tablero = MapasJuego.crearTablero(widget.sala.mapaSeleccionado);
    _setupBloc = SetupBloc()..add(StartSetup(tablero));
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

  List<_ReglaZonaVisual> _obtenerReglasDelMapa(Tablero tablero) {
    final tiposVistos = <String>{};
    final lista = <_ReglaZonaVisual>[];

    for (final grupo in tablero.regiones) {
      final r = grupo.tipoRegion;
      late final String id;
      late final String nombre;

      if (r is domain.TipoRojo) {
        id = 'rojo';
        nombre = 'Zona Roja';
      } else if (r is domain.TipoMorado) {
        id = 'morado';
        nombre = 'Zona Morada';
      } else if (r is domain.TipoAzul) {
        id = 'azul';
        nombre = 'Zona Azul';
      } else if (r is domain.TipoAmarillo) {
        id = 'amarillo';
        nombre = 'Zona Amarilla';
      } else if (r is domain.TipoGris) {
        id = 'gris';
        nombre = 'Zona Gris';
      } else if (r is domain.TipoNaranjaAlto) {
        id = 'naranja_alto';
        nombre = 'Naranja Alto (4-6)';
      } else if (r is domain.TipoNaranjaBajo) {
        id = 'naranja_bajo';
        nombre = 'Naranja Bajo (1-3)';
      } else if (r is domain.TipoVerde) {
        id = 'verde';
        nombre = 'Zona Verde';
      } else {
        id = r.runtimeType.toString();
        nombre = 'Zona';
      }

      if (tiposVistos.add(id)) {
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
            indiceEnDisputa: 0, // 1.er lugar encendido inicialmente en disputa
          ),
        );
      }
    }

    return lista;
  }

  void _onCasillaTapped(Casilla casilla, SetupState state) {
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
          final Tablero tablero = switch (setupState) {
            SetupAwaitingInputs(:final tablero) => tablero,
            SetupCompleted(:final tablero) => tablero,
            _ => MapasJuego.crearTablero(widget.sala.mapaSeleccionado),
          };

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
                  final rightColumn = _buildRightSetupActionPanel(
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
                color: _setupConfirmadoLocalmente
                    ? const Color(0xFF10B981).withValues(alpha: 0.18)
                    : const Color(0xFFF59E0B).withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _setupConfirmadoLocalmente
                      ? const Color(0xFF10B981)
                      : const Color(0xFFF59E0B),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FaIcon(
                    _setupConfirmadoLocalmente
                        ? FontAwesomeIcons.circleCheck
                        : FontAwesomeIcons.sliders,
                    size: 12,
                    color: _setupConfirmadoLocalmente
                        ? const Color(0xFF10B981)
                        : const Color(0xFFFBBF24),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _setupConfirmadoLocalmente
                        ? 'SETUP CONFIRMADO'
                        : 'FASE DE SETUP',
                    style: TextStyle(
                      color: _setupConfirmadoLocalmente
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
              final listoEnFase = esTu ? _setupConfirmadoLocalmente : false;

              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF0C0E1A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: esTu
                        ? const Color(0xFF3B82F6)
                        : const Color(0xFF1E293B),
                    width: esTu ? 1.5 : 1.0,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FaIcon(
                      j.esHost
                          ? FontAwesomeIcons.crown
                          : FontAwesomeIcons.userAstronaut,
                      color: j.esHost
                          ? const Color(0xFFF59E0B)
                          : const Color(0xFF38BDF8),
                      size: 12,
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          esTu ? '${j.nombre} (TÚ)' : j.nombre,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          listoEnFase ? 'Setup listo' : 'En preparación',
                          style: TextStyle(
                            color: listoEnFase
                                ? const Color(0xFF10B981)
                                : const Color(0xFF94A3B8),
                            fontSize: 10,
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
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                        ),
                      ),
                      child: const Text(
                        '0 pts',
                        style: TextStyle(
                          color: Color(0xFFFBBF24),
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
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
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FaIcon(
                    FontAwesomeIcons.dice,
                    color: Color(0xFFA855F7),
                    size: 14,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'RESULTADOS DE LOS DADOS',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.9,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 4),
              Text(
                'Se lanzarán al finalizar la fase de Setup de todos los jugadores',
                style: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 11,
                ),
              ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDiePlaceholderBox(label: 'DADO 1'),
              const SizedBox(width: 10),
              _buildDiePlaceholderBox(label: 'DADO 2'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDiePlaceholderBox({required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0C0E1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF312E81), width: 1.4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const FaIcon(
            FontAwesomeIcons.diceD6,
            color: Color(0xFF6366F1),
            size: 16,
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Text(
                '-',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
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
          const Text(
            'Las 6 casillas con borde dorado son tus casillas iniciales de preparación',
            textAlign: TextAlign.center,
            style: TextStyle(
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
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(3.0),
                            child: _buildBoardCell(
                              casilla: casilla,
                              grupo: grupo,
                              esCasillaInicial: esInicial,
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
    required SetupState setupState,
  }) {
    final colorRegion = grupo != null
        ? _colorFlutterDeRegion(grupo.tipoRegion)
        : const Color(0xFF334155);
    final tieneValor = casilla.valor != null;

    return InkWell(
      key: Key('board_cell_${casilla.x}_${casilla.y}'),
      borderRadius: BorderRadius.circular(12),
      onTap: () => _onCasillaTapped(casilla, setupState),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        decoration: BoxDecoration(
          color: esCasillaInicial
              ? colorRegion.withValues(alpha: tieneValor ? 0.92 : 0.68)
              : colorRegion.withValues(alpha: 0.32),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: esCasillaInicial
                ? const Color(0xFFFDE047)
                : colorRegion.withValues(alpha: 0.75),
            width: esCasillaInicial ? 2.6 : 1.2,
          ),
          boxShadow: esCasillaInicial
              ? [
                  BoxShadow(
                    color: const Color(0xFFFACC15).withValues(alpha: 0.35),
                    blurRadius: 8,
                    spreadRadius: 0.5,
                  ),
                ]
              : null,
        ),
        child: Stack(
          children: [
            if (esCasillaInicial)
              Positioned(
                top: 4,
                right: 4,
                child: FaIcon(
                  FontAwesomeIcons.solidStar,
                  size: 8,
                  color: const Color(0xFFFEF08A).withValues(alpha: 0.95),
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
                  : (esCasillaInicial
                      ? Text(
                          '?',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.75),
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        )
                      : const SizedBox.shrink()),
            ),
          ],
        ),
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
