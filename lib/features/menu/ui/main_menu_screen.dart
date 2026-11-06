import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_event.dart';
import '../../auth/models/usuario.dart';
import 'widgets/game_info_banner.dart';
import 'widgets/join_room_dialog.dart';
import 'widgets/menu_action_card.dart';

/// Pantalla principal (Menú Principal) que se muestra tras autenticarse con éxito.
/// Permite al jugador crear una partida como Game Master o unirse a una con un código de 5 dígitos.
class MainMenuScreen extends StatelessWidget {
  final Usuario usuario;

  const MainMenuScreen({
    super.key,
    required this.usuario,
  });

  /// Genera un código de sala numérico simulado de 5 dígitos para pruebas locales.
  String _generateRandomRoomCode() {
    final random = Random();
    final code = 10000 + random.nextInt(90000);
    return code.toString();
  }

  void _handleCreateRoom(BuildContext context) {
    final roomCode = _generateRandomRoomCode();
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF141728),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFF2B3356), width: 1.5),
        ),
        title: Row(
          children: const [
            FaIcon(
              FontAwesomeIcons.crown,
              color: Color(0xFFF59E0B),
              size: 20,
            ),
            SizedBox(width: 10),
            Text(
              '¡Sala Creada!',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Eres el Game Master de la sala. Comparte este código de 5 dígitos con hasta 5 amigos en cualquier parte del mundo:',
              style: TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0C0E1A),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFF7C3AED),
                    width: 2,
                  ),
                ),
                child: Text(
                  roomCode,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 10,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            const Center(
              child: Text(
                'Próximo paso: Pantalla de Sala de Espera / Lobby (en desarrollo)',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFFF59E0B),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C3AED),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleJoinRoom(BuildContext context) async {
    final code = await JoinRoomDialog.show(context);
    if (code != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF1E293B),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFF2563EB), width: 1.2),
          ),
          content: Row(
            children: [
              const FaIcon(
                FontAwesomeIcons.circleCheck,
                color: Color(0xFF10B981),
                size: 16,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Conectando a la sala #$code...',
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
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0C0E1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF141728),
        elevation: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
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
                size: 16,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'BRILLIANT',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
        actions: [
          // Usuario autenticado
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF334155),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const FaIcon(
                    FontAwesomeIcons.user,
                    color: Color(0xFF38BDF8),
                    size: 12,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    usuario.username,
                    style: const TextStyle(
                      color: Color(0xFFF1F5F9),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Botón Cerrar Sesión
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton(
              tooltip: 'Cerrar Sesión',
              onPressed: () {
                context.read<AuthBloc>().add(const AuthLogoutRequested());
              },
              icon: const FaIcon(
                FontAwesomeIcons.arrowRightFromBracket,
                color: Color(0xFFF43F5E),
                size: 16,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Banner de Saludo
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1E1B4B), Color(0xFF172554)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFF312E81),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '¡Bienvenido, ${usuario.username}!',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Elige una de las opciones para comenzar a jugar. Las salas admiten hasta 6 jugadores conectados desde cualquier lugar del mundo.',
                                style: TextStyle(
                                  color: Color(0xFFCBD5E1),
                                  fontSize: 13,
                                  height: 1.45,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: const Color(0xFF4338CA).withValues(alpha: 0.35),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF6366F1),
                              width: 1.5,
                            ),
                          ),
                          child: const Center(
                            child: FaIcon(
                              FontAwesomeIcons.gamepad,
                              color: Color(0xFFA5B4FC),
                              size: 28,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Opciones principales (Crear Partida y Unirse a Partida)
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final bool isWide = constraints.maxWidth >= 560;

                      final createCard = MenuActionCard(
                        cardKey: const Key('menu_create_game_card'),
                        title: 'Crear Partida',
                        subtitle:
                            'Sé el Game Master, selecciona 1 de los 4 mapas y genera el código para tu sala.',
                        badgeText: 'Game Master',
                        icon: FontAwesomeIcons.chessRook,
                        buttonIcon: FontAwesomeIcons.plus,
                        buttonText: 'CREAR SALA',
                        gradientColors: const [
                          Color(0xFF7C3AED),
                          Color(0xFFC026D3),
                        ],
                        onTap: () => _handleCreateRoom(context),
                      );

                      final joinCard = MenuActionCard(
                        cardKey: const Key('menu_join_game_card'),
                        title: 'Unirse a Partida',
                        subtitle:
                            'Ingresa el código numérico de 5 dígitos para unirte a la sala de tu anfitrión.',
                        badgeText: 'Código 5 Dígitos',
                        icon: FontAwesomeIcons.doorOpen,
                        buttonIcon: FontAwesomeIcons.rightToBracket,
                        buttonText: 'INGRESAR CÓDIGO',
                        gradientColors: const [
                          Color(0xFF2563EB),
                          Color(0xFF06B6D4),
                        ],
                        onTap: () => _handleJoinRoom(context),
                      );

                      if (isWide) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: createCard),
                            const SizedBox(width: 20),
                            Expanded(child: joinCard),
                          ],
                        );
                      }

                      return Column(
                        children: [
                          createCard,
                          const SizedBox(height: 16),
                          joinCard,
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  // Barra de Información rápida del juego
                  const GameInfoBanner(),

                  const SizedBox(height: 20),

                  // Indicador de Conexión Global WAN
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF1E293B),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: const [
                        FaIcon(
                          FontAwesomeIcons.earthAmericas,
                          color: Color(0xFF38BDF8),
                          size: 15,
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Conexión Global WAN: Tus amigos pueden unirse a tu sala desde cualquier país ingresando el código de 5 dígitos sin estar en la misma red Wi-Fi.',
                            style: TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 12,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
