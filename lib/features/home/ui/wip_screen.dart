import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_event.dart';
import '../../auth/models/usuario.dart';
import '../../lobby/models/sala_partida.dart';

class WipScreen extends StatelessWidget {
  final Usuario usuario;
  final SalaPartida? sala;
  final VoidCallback? onBackToMenu;

  const WipScreen({
    super.key,
    required this.usuario,
    this.sala,
    this.onBackToMenu,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0C0E1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF141728),
        elevation: 0,
        title: const Text(
          'BRILLIANT',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton.icon(
              onPressed: () {
                context.read<AuthBloc>().add(const AuthLogoutRequested());
              },
              icon: const FaIcon(
                FontAwesomeIcons.arrowRightFromBracket,
                color: Color(0xFFF43F5E),
                size: 15,
              ),
              label: const Text(
                'Cerrar Sesión',
                style: TextStyle(
                  color: Color(0xFFF43F5E),
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: const Color(0xFF141728),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: const Color(0xFF222845),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Badge de usuario autenticado
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
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
                            FontAwesomeIcons.circleCheck,
                            color: Color(0xFF10B981),
                            size: 15,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Sesión iniciada: ${usuario.username}',
                            style: const TextStyle(
                              color: Color(0xFFE2E8F0),
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Emblema WIP
                    Container(
                      width: 86,
                      height: 86,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFF59E0B),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFF59E0B).withValues(alpha: 0.25),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: FaIcon(
                          FontAwesomeIcons.screwdriverWrench,
                          color: Color(0xFFF59E0B),
                          size: 34,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Título WIP
                    const Text(
                      'WIP',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'VISUALIZACIÓN DE PARTIDA • EN DESARROLLO',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFFF59E0B),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 18),

                    if (sala != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0C0E1A),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFF2B3356)),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Sala #${sala!.codigo} • Mapa ${sala!.mapaSeleccionado}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Jugadores sincronizados (${sala!.jugadores.length}): ${sala!.jugadores.map((j) => j.nombre).join(", ")}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Color(0xFF10B981),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                    ],

                    // Descripción
                    const Text(
                      '¡La sala se ha sincronizado e iniciado con éxito! La visualización interactiva del tablero de partida y tirada de dados se encuentra en desarrollo (WIP).',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Botón volver
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          if (onBackToMenu != null) {
                            onBackToMenu!();
                          } else {
                            context
                                .read<AuthBloc>()
                                .add(const AuthLogoutRequested());
                          }
                        },
                        icon: const FaIcon(
                          FontAwesomeIcons.arrowLeft,
                          size: 15,
                        ),
                        label: Text(
                          onBackToMenu != null
                              ? 'SALIR DE LA PARTIDA'
                              : 'VOLVER AL LOGIN',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(
                            color: Color(0xFF334155),
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
