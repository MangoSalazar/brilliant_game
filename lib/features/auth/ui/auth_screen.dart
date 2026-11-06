import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import 'widgets/auth_header.dart';
import 'widgets/auth_tabs.dart';
import 'widgets/brilliant_text_field.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _submit(AuthMode mode) {
    FocusScope.of(context).unfocus();
    final bloc = context.read<AuthBloc>();

    if (mode == AuthMode.login) {
      bloc.add(AuthLoginRequested(
        username: _usernameController.text,
        password: _passwordController.text,
      ));
    } else {
      bloc.add(AuthRegisterRequested(
        username: _usernameController.text,
        password: _passwordController.text,
        confirmPassword: _confirmPasswordController.text,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0C0E1A),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: BlocConsumer<AuthBloc, AuthState>(
                listener: (context, state) {
                  // Manejo adicional de notificaciones si fuera necesario
                },
                builder: (context, state) {
                  final isRegister = state.mode == AuthMode.register;
                  final isLoading = state.isLoading;

                  return Container(
                    padding: const EdgeInsets.all(28),
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
                        // Encabezado
                        const AuthHeader(),
                        const SizedBox(height: 28),

                        // Selector de Modo (Iniciar Sesión / Crear Cuenta)
                        AuthTabs(
                          currentMode: state.mode,
                          onModeSelected: (mode) {
                            context.read<AuthBloc>().add(AuthModeChanged(mode));
                          },
                        ),
                        const SizedBox(height: 24),

                        // Mensaje de Error (si existe)
                        if (state.errorMessage != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF451A22),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color(0xFFE11D48).withValues(alpha: 0.5),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                const FaIcon(
                                  FontAwesomeIcons.circleExclamation,
                                  color: Color(0xFFFB7185),
                                  size: 16,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    state.errorMessage!,
                                    style: const TextStyle(
                                      color: Color(0xFFFECDD3),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                        ],

                        // Campo: Usuario
                        BrilliantTextField(
                          controller: _usernameController,
                          label: 'NOMBRE DE USUARIO',
                          hintText: 'Ej. jugador1',
                          prefixIcon: FontAwesomeIcons.user,
                          enabled: !isLoading,
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 16),

                        // Campo: Contraseña
                        BrilliantTextField(
                          controller: _passwordController,
                          label: 'CONTRASEÑA',
                          hintText: 'Mínimo 6 caracteres',
                          prefixIcon: FontAwesomeIcons.lock,
                          isPassword: true,
                          obscureText: _obscurePassword,
                          enabled: !isLoading,
                          textInputAction: isRegister
                              ? TextInputAction.next
                              : TextInputAction.done,
                          onToggleVisibility: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                          onSubmitted: (_) {
                            if (!isRegister && !isLoading) {
                              _submit(state.mode);
                            }
                          },
                        ),

                        // Campo Adicional: Confirmar Contraseña (solo en registro)
                        if (isRegister) ...[
                          const SizedBox(height: 16),
                          BrilliantTextField(
                            controller: _confirmPasswordController,
                            label: 'CONFIRMAR CONTRASEÑA',
                            hintText: 'Repite tu contraseña',
                            prefixIcon: FontAwesomeIcons.shieldHalved,
                            isPassword: true,
                            obscureText: _obscureConfirmPassword,
                            enabled: !isLoading,
                            textInputAction: TextInputAction.done,
                            onToggleVisibility: () {
                              setState(() {
                                _obscureConfirmPassword = !_obscureConfirmPassword;
                              });
                            },
                            onSubmitted: (_) {
                              if (!isLoading) {
                                _submit(state.mode);
                              }
                            },
                          ),
                        ],
                        const SizedBox(height: 28),

                        // Botón Principal de Acción
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : () => _submit(state.mode),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB),
                              foregroundColor: Colors.white,
                              disabledBackgroundColor:
                                  const Color(0xFF2563EB).withValues(alpha: 0.5),
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: isLoading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white,
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      FaIcon(
                                        isRegister
                                            ? FontAwesomeIcons.userPlus
                                            : FontAwesomeIcons.rightToBracket,
                                        size: 15,
                                      ),
                                      const SizedBox(width: 8),
                                      Flexible(
                                        child: Text(
                                          isRegister ? 'REGISTRARSE' : 'ENTRAR A LA PARTIDA',
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 0.8,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Indicador de Servidor Shelf
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFF10B981),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Flexible(
                              child: Text(
                                'Servidor Shelf • v1.0.0',
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Color(0xFF64748B),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
