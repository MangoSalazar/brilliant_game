import 'package:flutter_bloc/flutter_bloc.dart';
import '../repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;

  AuthBloc({
    required AuthRepository authRepository,
  })  : _authRepository = authRepository,
        super(const AuthState()) {
    on<AuthModeChanged>(_onModeChanged);
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthRegisterRequested>(_onRegisterRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
  }

  void _onModeChanged(AuthModeChanged event, Emitter<AuthState> emit) {
    if (state.mode == event.mode) return;
    emit(state.copyWith(
      mode: event.mode,
      status: AuthStatus.initial,
      clearError: true,
    ));
  }

  Future<void> _onLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    final username = event.username.trim();
    final password = event.password;

    if (username.isEmpty) {
      emit(state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: 'Por favor, ingresa tu nombre de usuario.',
      ));
      return;
    }

    if (password.isEmpty) {
      emit(state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: 'Por favor, ingresa tu contraseña.',
      ));
      return;
    }

    emit(state.copyWith(
      status: AuthStatus.loading,
      clearError: true,
    ));

    try {
      final user = await _authRepository.login(
        username: username,
        password: password,
      );
      emit(state.copyWith(
        status: AuthStatus.authenticated,
        usuario: user,
        clearError: true,
      ));
    } on AuthException catch (e) {
      emit(state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: e.message,
      ));
    } catch (_) {
      emit(state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: 'Error inesperado de conexión con el servidor.',
      ));
    }
  }

  Future<void> _onRegisterRequested(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    final username = event.username.trim();
    final password = event.password;
    final confirmPassword = event.confirmPassword;

    if (username.isEmpty) {
      emit(state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: 'Por favor, ingresa un nombre de usuario.',
      ));
      return;
    }

    if (username.length < 3 || username.length > 15) {
      emit(state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: 'El usuario debe tener entre 3 y 15 caracteres.',
      ));
      return;
    }

    final validUserRegex = RegExp(r'^[a-zA-Z0-9_]+$');
    if (!validUserRegex.hasMatch(username)) {
      emit(state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: 'El usuario solo permite letras, números y guión bajo.',
      ));
      return;
    }

    if (password.isEmpty) {
      emit(state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: 'Por favor, ingresa una contraseña.',
      ));
      return;
    }

    if (password.length < 6) {
      emit(state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: 'La contraseña debe tener al menos 6 caracteres.',
      ));
      return;
    }

    if (password != confirmPassword) {
      emit(state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: 'Las contraseñas no coinciden.',
      ));
      return;
    }

    emit(state.copyWith(
      status: AuthStatus.loading,
      clearError: true,
    ));

    try {
      final user = await _authRepository.register(
        username: username,
        password: password,
      );
      emit(state.copyWith(
        status: AuthStatus.authenticated,
        usuario: user,
        clearError: true,
      ));
    } on AuthException catch (e) {
      emit(state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: e.message,
      ));
    } catch (_) {
      emit(state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: 'Error al registrar usuario en el servidor.',
      ));
    }
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _authRepository.logout();
    emit(const AuthState(
      mode: AuthMode.login,
      status: AuthStatus.unauthenticated,
      usuario: null,
    ));
  }
}
