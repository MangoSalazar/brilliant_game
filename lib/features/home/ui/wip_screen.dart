import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_event.dart';
import '../../auth/models/usuario.dart';

class WipScreen extends StatelessWidget {
  final Usuario usuario;

  const WipScreen({
    super.key,
    required this.usuario,
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
              icon: const Icon(
                Icons.logout_rounded,
                color: Color(0xFFF43F5E),
                size: 18,
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
              constraints: const BoxConstraints(maxWidth: 480),
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
                          const Icon(
                            Icons.check_circle_rounded,
                            color: Color(0xFF10B981),
                            size: 18,
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
                    const SizedBox(height: 32),

                    // Emblema WIP
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFF59E0B),
                          width: 2,
                        ),
                      ),
                      child: const Center(
                        child: Text(
                          '🚧',
                          style: TextStyle(fontSize: 42),
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
                      'WORK IN PROGRESS • EN DESARROLLO',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFFF59E0B),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Descripción
                    const Text(
                      'Has iniciado sesión correctamente. La siguiente sección (Menú Principal, Lobbies con código de 5 dígitos y selección de mapas) se encuentra en desarrollo.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Botón volver / cerrar sesión
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          context.read<AuthBloc>().add(const AuthLogoutRequested());
                        },
                        icon: const Icon(Icons.arrow_back_rounded, size: 18),
                        label: const Text(
                          'VOLVER AL LOGIN',
                          style: TextStyle(
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
