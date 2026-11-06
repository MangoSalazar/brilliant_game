import 'package:equatable/equatable.dart';
import 'auth_state.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Cambia entre la pestaña de Iniciar Sesión y Crear Cuenta.
class AuthModeChanged extends AuthEvent {
  final AuthMode mode;

  const AuthModeChanged(this.mode);

  @override
  List<Object?> get props => [mode];
}

/// Solicitud de inicio de sesión.
class AuthLoginRequested extends AuthEvent {
  final String username;
  final String password;

  const AuthLoginRequested({
    required this.username,
    required this.password,
  });

  @override
  List<Object?> get props => [username, password];
}

/// Solicitud de registro de una nueva cuenta.
class AuthRegisterRequested extends AuthEvent {
  final String username;
  final String password;
  final String confirmPassword;

  const AuthRegisterRequested({
    required this.username,
    required this.password,
    required this.confirmPassword,
  });

  @override
  List<Object?> get props => [username, password, confirmPassword];
}

/// Solicitud de cierre de sesión.
class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}
