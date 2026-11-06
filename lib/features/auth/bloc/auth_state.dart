import 'package:equatable/equatable.dart';
import '../models/usuario.dart';

enum AuthMode {
  login,
  register,
}

enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
}

class AuthState extends Equatable {
  final AuthMode mode;
  final AuthStatus status;
  final Usuario? usuario;
  final String? errorMessage;

  const AuthState({
    this.mode = AuthMode.login,
    this.status = AuthStatus.initial,
    this.usuario,
    this.errorMessage,
  });

  bool get isLoading => status == AuthStatus.loading;
  bool get isAuthenticated => status == AuthStatus.authenticated && usuario != null;

  AuthState copyWith({
    AuthMode? mode,
    AuthStatus? status,
    Usuario? usuario,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AuthState(
      mode: mode ?? this.mode,
      status: status ?? this.status,
      usuario: usuario ?? this.usuario,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [mode, status, usuario, errorMessage];
}
