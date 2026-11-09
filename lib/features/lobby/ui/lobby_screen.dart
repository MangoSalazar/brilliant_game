import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../constantes.dart';
import '../../auth/models/usuario.dart';
import '../../home/ui/wip_screen.dart';
import '../bloc/lobby_bloc.dart';
import '../bloc/lobby_event.dart';
import '../bloc/lobby_state.dart';
import '../models/jugador_sala.dart';
import '../models/sala_partida.dart';

/// Pantalla de Sala de Espera (Lobby) sincronizada en tiempo real con el servidor Shelf.
class LobbyScreen extends StatelessWidget {
  final Usuario usuarioActual;

  const LobbyScreen({
    super.key,
    required this.usuarioActual,
  });

  static const List<Map<String, String>> _infoMapas = [
    {
      'titulo': 'Mapa 1 • Clásico',
      'regiones': 'Verde, Azul, Morado, Rojo, Amarillo',
    },
    {
      'titulo': 'Mapa 2 • Fortaleza Gris',
      'regiones': 'Incluye zonas Grises (números idénticos)',
    },
    {
      'titulo': 'Mapa 3 • Franjas Simétricas',
      'regiones': 'Bandas horizontales y bloques Grises',
    },
    {
      'titulo': 'Mapa 4 • Anillo Naranja',
      'regiones': 'Borde perimetral Naranja (rangos 1-3 / 4-6)',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<LobbyBloc, LobbyState>(
      listener: (context, state) {
        if (state.errorMessage != null && state.errorMessage!.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: const Color(0xFF7F1D1D),
              behavior: SnackBarBehavior.floating,
              content: Row(
                children: [
                  const FaIcon(
                    FontAwesomeIcons.triangleExclamation,
                    color: Color(0xFFFCA5A5),
                    size: 16,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      state.errorMessage!,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          );
          context.read<LobbyBloc>().add(const LobbyClearErrorRequested());
        }

        if (state.infoMessage != null && state.infoMessage!.isNotEmpty) {
          final isHostChange = state.infoMessage!.contains('Game Master');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: const Color(0xFF1E293B),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isHostChange
                      ? const Color(0xFFF59E0B)
                      : const Color(0xFF38BDF8),
                  width: 1.2,
                ),
              ),
              content: Row(
                children: [
                  FaIcon(
                    isHostChange
                        ? FontAwesomeIcons.crown
                        : FontAwesomeIcons.circleInfo,
                    color: isHostChange
                        ? const Color(0xFFFBBF24)
                        : const Color(0xFF38BDF8),
                    size: 16,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      state.infoMessage!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
          context.read<LobbyBloc>().add(const LobbyClearInfoRequested());
        }
      },
      builder: (context, state) {
        if (state.isInGame && state.sala != null) {
          return WipScreen(
            usuario: usuarioActual,
            sala: state.sala,
            onBackToMenu: () {
              context.read<LobbyBloc>().add(const LobbyLeaveRoomRequested());
            },
          );
        }

        final sala = state.sala;
        if (sala == null) {
          return Scaffold(
            backgroundColor: const Color(0xFF0C0E1A),
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(color: Color(0xFF7C3AED)),
                  const SizedBox(height: 16),
                  const Text(
                    'Sincronizando con el servidor Shelf...',
                    style: TextStyle(
                      color: Color(0xFFCBD5E1),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextButton.icon(
                    onPressed: () {
                      context
                          .read<LobbyBloc>()
                          .add(const LobbyLeaveRoomRequested());
                    },
                    icon: const FaIcon(
                      FontAwesomeIcons.arrowLeft,
                      size: 14,
                      color: Color(0xFF94A3B8),
                    ),
                    label: const Text(
                      'Cancelar y volver al menú',
                      style: TextStyle(color: Color(0xFF94A3B8)),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final esHost = sala.esGameMaster(usuarioActual.id);
        final jugadorActual = sala.jugadores.firstWhere(
          (j) => j.id == usuarioActual.id,
          orElse: () => JugadorSala(
            id: usuarioActual.id,
            nombre: usuarioActual.username,
          ),
        );

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) {
              _confirmLeaveRoom(context, sala, esHost);
            }
          },
          child: Scaffold(
            backgroundColor: const Color(0xFF0C0E1A),
            appBar: AppBar(
              backgroundColor: const Color(0xFF141728),
              elevation: 0,
              leading: IconButton(
                key: const Key('lobby_leave_button'),
                tooltip: 'Salir de la Sala',
                onPressed: () {
                  _confirmLeaveRoom(context, sala, esHost);
                },
                icon: const FaIcon(
                  FontAwesomeIcons.arrowLeft,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            title: Row(
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
                    FontAwesomeIcons.users,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'SALA DE ESPERA',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF334155)),
                    ),
                    child: Text(
                      '${sala.jugadores.length} / ${ConstantesJuego.maxJugadoresPorSala} Jugadores',
                      style: const TextStyle(
                        color: Color(0xFF38BDF8),
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 20,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 820),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 1. Banner del Código de 5 Dígitos
                      _buildRoomCodeBanner(context, sala, esHost),

                      const SizedBox(height: 20),

                      // 2. Selector de Mapa (1 al 4)
                      _buildMapSelectorSection(context, sala, esHost),

                      const SizedBox(height: 20),

                      // 3. Lista de Jugadores en Tiempo Real
                      _buildPlayersListSection(context, sala, esHost),

                      const SizedBox(height: 24),

                      // 4. Botones de Acción (Listo e Iniciar Partida)
                      _buildBottomActions(
                        context,
                        sala: sala,
                        esHost: esHost,
                        estoyListo: jugadorActual.esListo,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      },
    );
  }

  Future<void> _confirmLeaveRoom(
    BuildContext context,
    SalaPartida sala,
    bool esHost,
  ) async {
    final otrosJugadores =
        sala.jugadores.where((j) => j.id != usuarioActual.id).toList();
    final siguienteHost =
        otrosJugadores.isNotEmpty ? otrosJugadores.first.nombre : null;

    final String mensajeConfirmacion;
    if (esHost && siguienteHost != null) {
      mensajeConfirmacion =
          'Eres el Game Master actual. Si abandonas la sala, el rol de Game Master se transferirá automáticamente a $siguienteHost.';
    } else if (esHost) {
      mensajeConfirmacion =
          'Eres el único jugador en la sala. Si sales ahora, la sala #${sala.codigo} se cerrará.';
    } else {
      mensajeConfirmacion =
          '¿Estás seguro de que deseas abandonar la sala #${sala.codigo} y volver al menú principal?';
    }

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF141728),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: Color(0xFF2B3356), width: 1.5),
        ),
        title: Row(
          children: [
            FaIcon(
              esHost
                  ? FontAwesomeIcons.crown
                  : FontAwesomeIcons.rightFromBracket,
              color:
                  esHost ? const Color(0xFFF59E0B) : const Color(0xFFF43F5E),
              size: 18,
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                '¿Abandonar la sala?',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          mensajeConfirmacion,
          style: const TextStyle(
            color: Color(0xFFCBD5E1),
            fontSize: 14,
            height: 1.45,
          ),
        ),
        actions: [
          TextButton(
            key: const Key('cancel_leave_room_button'),
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text(
              'Permanecer',
              style: TextStyle(
                color: Color(0xFF94A3B8),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton.icon(
            key: const Key('confirm_leave_room_button'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE11D48),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            icon: const FaIcon(
              FontAwesomeIcons.arrowRightFromBracket,
              size: 13,
            ),
            label: const Text(
              'Salir de la sala',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (confirmar == true && context.mounted) {
      context.read<LobbyBloc>().add(const LobbyLeaveRoomRequested());
    }
  }

  Widget _buildRoomCodeBanner(
    BuildContext context,
    SalaPartida sala,
    bool esHost,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E1B4B), Color(0xFF172554)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF3B82F6), width: 1.3),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 16,
        runSpacing: 16,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FaIcon(
                    esHost ? FontAwesomeIcons.crown : FontAwesomeIcons.hashtag,
                    color: const Color(0xFFF59E0B),
                    size: 15,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    esHost
                        ? 'ERES EL GAME MASTER DE LA SALA'
                        : 'CONECTADO A LA SALA EN TIEMPO REAL',
                    style: const TextStyle(
                      color: Color(0xFFFBBF24),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Comparte este código de 5 dígitos para que otros clientes se unan:',
                style: TextStyle(
                  color: Color(0xFFCBD5E1),
                  fontSize: 13,
                ),
              ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                key: const Key('lobby_room_code_text'),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF0C0E1A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF7C3AED), width: 2),
                ),
                child: Text(
                  sala.codigo,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 8,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              const SizedBox(width: 10),
              IconButton(
                tooltip: 'Copiar código',
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: sala.codigo));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: const Color(0xFF1E293B),
                      behavior: SnackBarBehavior.floating,
                      content: Text(
                        'Código ${sala.codigo} copiado al portapapeles',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  );
                },
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFF1E293B),
                  padding: const EdgeInsets.all(14),
                ),
                icon: const FaIcon(
                  FontAwesomeIcons.copy,
                  color: Color(0xFF38BDF8),
                  size: 16,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMapSelectorSection(
    BuildContext context,
    SalaPartida sala,
    bool esHost,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF141728),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF222845)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const FaIcon(
                FontAwesomeIcons.map,
                color: Color(0xFF38BDF8),
                size: 15,
              ),
              const SizedBox(width: 8),
              const Text(
                'MAPA DE LA PARTIDA',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
              const Spacer(),
              Text(
                esHost
                    ? 'Toca para cambiar de mapa'
                    : 'Seleccionado por el Game Master',
                style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: List.generate(ConstantesJuego.totalMapas, (index) {
              final mapNumber = index + 1;
              final isSelected = sala.mapaSeleccionado == mapNumber;
              final info = _infoMapas[index];

              return InkWell(
                key: Key('lobby_map_option_$mapNumber'),
                onTap: esHost
                    ? () {
                        context
                            .read<LobbyBloc>()
                            .add(LobbySelectMapRequested(mapNumber));
                      }
                    : null,
                borderRadius: BorderRadius.circular(12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 180,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF2563EB).withValues(alpha: 0.2)
                        : const Color(0xFF0C0E1A),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF3B82F6)
                          : const Color(0xFF1E293B),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              info['titulo']!,
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : const Color(0xFFCBD5E1),
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          if (isSelected)
                            const FaIcon(
                              FontAwesomeIcons.circleCheck,
                              color: Color(0xFF38BDF8),
                              size: 14,
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        info['regiones']!,
                        style: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 11,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayersListSection(
    BuildContext context,
    SalaPartida sala,
    bool esHost,
  ) {
    final totalListos = sala.jugadores.where((j) => j.esListo).length;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF141728),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF222845)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const FaIcon(
                FontAwesomeIcons.userGroup,
                color: Color(0xFF10B981),
                size: 15,
              ),
              const SizedBox(width: 8),
              const Text(
                'JUGADORES EN LA SALA',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: sala.todosListos
                      ? const Color(0xFF10B981).withValues(alpha: 0.18)
                      : const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: sala.todosListos
                        ? const Color(0xFF10B981)
                        : const Color(0xFF334155),
                  ),
                ),
                child: Text(
                  '$totalListos / ${sala.jugadores.length} Listos',
                  style: TextStyle(
                    color: sala.todosListos
                        ? const Color(0xFF10B981)
                        : const Color(0xFFCBD5E1),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Column(
            children: List.generate(ConstantesJuego.maxJugadoresPorSala, (idx) {
              if (idx < sala.jugadores.length) {
                final jugador = sala.jugadores[idx];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _buildConnectedPlayerTile(
                    context,
                    jugador: jugador,
                    esUsuarioActual: jugador.id == usuarioActual.id,
                    puedoExpulsar: esHost && jugador.id != usuarioActual.id,
                  ),
                );
              }
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _buildEmptyPlayerSlot(idx + 1),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectedPlayerTile(
    BuildContext context, {
    required JugadorSala jugador,
    required bool esUsuarioActual,
    required bool puedoExpulsar,
  }) {
    // Regla del documento: Al marcarse como listo, el nombre del jugador se ilumina en color verde
    final Color readyGreen = const Color(0xFF10B981);
    final Color nameColor = jugador.esListo ? readyGreen : Colors.white;

    return AnimatedContainer(
      key: Key('player_tile_${jugador.id}'),
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: jugador.esListo
            ? readyGreen.withValues(alpha: 0.1)
            : const Color(0xFF0C0E1A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: jugador.esListo ? readyGreen : const Color(0xFF222845),
          width: jugador.esListo ? 1.8 : 1.0,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: jugador.esListo
                  ? readyGreen.withValues(alpha: 0.2)
                  : const Color(0xFF1E293B),
              shape: BoxShape.circle,
              border: Border.all(
                color: jugador.esListo ? readyGreen : const Color(0xFF475569),
              ),
            ),
            child: Center(
              child: FaIcon(
                jugador.esHost
                    ? FontAwesomeIcons.crown
                    : FontAwesomeIcons.userAstronaut,
                color: jugador.esListo
                    ? readyGreen
                    : (jugador.esHost
                        ? const Color(0xFFF59E0B)
                        : const Color(0xFF94A3B8)),
                size: 15,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        jugador.nombre,
                        key: Key('player_name_${jugador.id}'),
                        style: TextStyle(
                          color: nameColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (esUsuarioActual) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF312E81),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'TÚ',
                          style: TextStyle(
                            color: Color(0xFFA5B4FC),
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                    if (jugador.esHost) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: const Color(0xFFF59E0B),
                            width: 0.8,
                          ),
                        ),
                        child: const Text(
                          'GAME MASTER',
                          style: TextStyle(
                            color: Color(0xFFFBBF24),
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  jugador.esListo
                      ? 'Listo para iniciar la partida'
                      : 'Preparándose en la sala...',
                  style: TextStyle(
                    color: jugador.esListo
                        ? readyGreen.withValues(alpha: 0.9)
                        : const Color(0xFF64748B),
                    fontSize: 12,
                    fontWeight:
                        jugador.esListo ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),

          // Badge de estado LISTO / ESPERANDO (interactivo para el usuario actual)
          InkWell(
            key: Key('player_ready_badge_${jugador.id}'),
            borderRadius: BorderRadius.circular(20),
            onTap: esUsuarioActual
                ? () {
                    context.read<LobbyBloc>().add(
                          LobbyToggleReadyRequested(ready: !jugador.esListo),
                        );
                  }
                : null,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: jugador.esListo
                    ? readyGreen.withValues(alpha: 0.18)
                    : const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: jugador.esListo ? readyGreen : const Color(0xFF334155),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FaIcon(
                    jugador.esListo
                        ? FontAwesomeIcons.circleCheck
                        : FontAwesomeIcons.clock,
                    color:
                        jugador.esListo ? readyGreen : const Color(0xFF94A3B8),
                    size: 12,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    jugador.esListo ? 'LISTO' : 'PENDIENTE',
                    style: TextStyle(
                      color: jugador.esListo
                          ? readyGreen
                          : const Color(0xFF94A3B8),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Botón de expulsar exclusivo para el Game Master
          if (puedoExpulsar) ...[
            const SizedBox(width: 8),
            IconButton(
              key: Key('kick_player_${jugador.id}'),
              tooltip: 'Expulsar de la sala',
              onPressed: () {
                context
                    .read<LobbyBloc>()
                    .add(LobbyKickPlayerRequested(jugador.id));
              },
              icon: const FaIcon(
                FontAwesomeIcons.userXmark,
                color: Color(0xFFF43F5E),
                size: 15,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyPlayerSlot(int slotNumber) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0C0E1A).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF1E293B),
          style: BorderStyle.solid,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFF141728),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF1E293B)),
            ),
            child: Center(
              child: Text(
                '$slotNumber',
                style: const TextStyle(
                  color: Color(0xFF475569),
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          const Text(
            'Esperando jugador...',
            style: TextStyle(
              color: Color(0xFF475569),
              fontSize: 14,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions(
    BuildContext context, {
    required SalaPartida sala,
    required bool esHost,
    required bool estoyListo,
  }) {
    final bool puedeIniciar = esHost && sala.todosListos;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            // Botón para marcarse como Listo / Cancelar Listo
            Expanded(
              child: SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  key: const Key('lobby_toggle_ready_button'),
                  onPressed: () {
                    context.read<LobbyBloc>().add(
                          LobbyToggleReadyRequested(ready: !estoyListo),
                        );
                  },
                  icon: FaIcon(
                    estoyListo
                        ? FontAwesomeIcons.rotateLeft
                        : FontAwesomeIcons.hand,
                    size: 16,
                  ),
                  label: Text(
                    estoyListo
                        ? 'CANCELAR LISTO'
                        : 'MARCARME COMO LISTO',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      letterSpacing: 0.8,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: estoyListo
                        ? const Color(0xFF059669)
                        : const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    side: estoyListo
                        ? const BorderSide(
                            color: Color(0xFF34D399),
                            width: 1.5,
                          )
                        : null,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ),

            if (esHost) ...[
              const SizedBox(width: 14),
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    key: const Key('lobby_start_game_button'),
                    onPressed: puedeIniciar
                        ? () {
                            context
                                .read<LobbyBloc>()
                                .add(const LobbyStartGameRequested());
                          }
                        : null,
                    icon: const FaIcon(
                      FontAwesomeIcons.play,
                      size: 15,
                    ),
                    label: const Text(
                      'INICIAR PARTIDA',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        letterSpacing: 1,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7C3AED),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xFF1E293B),
                      disabledForegroundColor: const Color(0xFF64748B),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 10),
        Center(
          child: Text(
            sala.todosListos
                ? (esHost
                    ? '¡Todos los jugadores están en verde! Ya puedes iniciar la partida.'
                    : '¡Todos están listos! Esperando a que el Game Master inicie la partida...')
                : 'La partida solo podrá comenzar cuando todos los jugadores presentes estén marcados en verde como "Listo".',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: sala.todosListos
                  ? const Color(0xFF10B981)
                  : const Color(0xFF94A3B8),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
