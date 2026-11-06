import 'package:test/test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:brilliant_game/features/auth/bloc/auth_bloc.dart';
import 'package:brilliant_game/features/auth/bloc/auth_event.dart';
import 'package:brilliant_game/features/auth/bloc/auth_state.dart';
import 'package:brilliant_game/features/auth/models/usuario.dart';
import 'package:brilliant_game/features/auth/repositories/auth_repository.dart';

void main() {
  group('AuthBloc', () {
    late LocalAuthRepository authRepository;

    setUp(() {
      authRepository = LocalAuthRepository(simulatedDelay: Duration.zero);
    });

    test('Estado inicial es AuthState() con mode login e initial', () {
      final bloc = AuthBloc(authRepository: authRepository);
      expect(bloc.state.mode, equals(AuthMode.login));
      expect(bloc.state.status, equals(AuthStatus.initial));
      expect(bloc.state.isAuthenticated, isFalse);
      bloc.close();
    });

    blocTest<AuthBloc, AuthState>(
      'Cambiar de modo actualiza el state.mode y limpia errores',
      build: () => AuthBloc(authRepository: authRepository),
      act: (bloc) => bloc.add(const AuthModeChanged(AuthMode.register)),
      expect: () => [
        const AuthState(
          mode: AuthMode.register,
          status: AuthStatus.initial,
        ),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'Login con campos vacíos emite error',
      build: () => AuthBloc(authRepository: authRepository),
      act: (bloc) => bloc.add(const AuthLoginRequested(
        username: '',
        password: '',
      )),
      expect: () => [
        predicate<AuthState>((state) =>
            state.status == AuthStatus.unauthenticated &&
            state.errorMessage!.contains('nombre de usuario')),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'Login exitoso con usuario precargado (jugador1 / Password123)',
      build: () => AuthBloc(authRepository: authRepository),
      act: (bloc) => bloc.add(const AuthLoginRequested(
        username: 'jugador1',
        password: 'Password123',
      )),
      expect: () => [
        predicate<AuthState>((state) => state.isLoading),
        predicate<AuthState>((state) =>
            state.isAuthenticated &&
            state.usuario?.username == 'jugador1'),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'Registro con contraseñas que no coinciden emite error',
      build: () => AuthBloc(authRepository: authRepository),
      act: (bloc) => bloc.add(const AuthRegisterRequested(
        username: 'nuevo_jugador',
        password: 'Password123',
        confirmPassword: 'Password999',
      )),
      expect: () => [
        predicate<AuthState>((state) =>
            state.status == AuthStatus.unauthenticated &&
            state.errorMessage!.contains('no coinciden')),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'Registro exitoso crea la cuenta y autentica al usuario',
      build: () => AuthBloc(authRepository: authRepository),
      act: (bloc) => bloc.add(const AuthRegisterRequested(
        username: 'novato',
        password: 'Password123',
        confirmPassword: 'Password123',
      )),
      expect: () => [
        predicate<AuthState>((state) => state.isLoading),
        predicate<AuthState>((state) =>
            state.isAuthenticated &&
            state.usuario!.username == 'novato'),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'Logout limpia la sesión',
      build: () => AuthBloc(authRepository: authRepository),
      seed: () => const AuthState(
        status: AuthStatus.authenticated,
        usuario: Usuario(id: '1', username: 'test'),
      ),
      act: (bloc) => bloc.add(const AuthLogoutRequested()),
      expect: () => [
        const AuthState(
          mode: AuthMode.login,
          status: AuthStatus.unauthenticated,
          usuario: null,
        ),
      ],
    );
  });
}
