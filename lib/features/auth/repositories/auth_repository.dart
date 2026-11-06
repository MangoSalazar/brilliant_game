import 'dart:async';
import '../models/usuario.dart';

/// Excepción personalizada para errores del flujo de autenticación.
class AuthException implements Exception {
  final String message;
  const AuthException(this.message);

  @override
  String toString() => message;
}

/// Contrato abstracto para la capa de autenticación (Principio DIP de SOLID).
abstract class AuthRepository {
  /// Inicia sesión con credenciales.
  Future<Usuario> login({
    required String username,
    required String password,
  });

  /// Registra una nueva cuenta de usuario.
  Future<Usuario> register({
    required String username,
    required String password,
  });

  /// Cierra la sesión activa.
  Future<void> logout();

  /// Retorna el usuario autenticado actualmente en memoria o null si no hay sesión.
  Usuario? get currentUser;
}

/// Implementación local / en memoria de autenticación para desarrollo y pruebas.
/// Valida credenciales, almacena usuarios creados y simula la respuesta de red.
class LocalAuthRepository implements AuthRepository {
  final Duration simulatedDelay;

  LocalAuthRepository({
    this.simulatedDelay = const Duration(milliseconds: 500),
  });

  final Map<String, String> _usersDb = {
    // Usuario de prueba precargado
    'jugador1': 'Password123',
    'admin': 'Admin123',
  };

  Usuario? _currentUser;

  @override
  Usuario? get currentUser => _currentUser;

  @override
  Future<Usuario> login({
    required String username,
    required String password,
  }) async {
    // Simular latencia de red si aplica
    if (simulatedDelay > Duration.zero) {
      await Future.delayed(simulatedDelay);
    }

    final normalizedUser = username.trim().toLowerCase();
    if (!_usersDb.containsKey(normalizedUser)) {
      throw const AuthException('Usuario no encontrado. Verifica tus credenciales o regístrate.');
    }

    if (_usersDb[normalizedUser] != password) {
      throw const AuthException('Contraseña incorrecta.');
    }

    _currentUser = Usuario(
      id: 'usr_${normalizedUser.hashCode.abs()}',
      username: username.trim(),
    );
    return _currentUser!;
  }

  @override
  Future<Usuario> register({
    required String username,
    required String password,
  }) async {
    // Simular latencia de red si aplica
    if (simulatedDelay > Duration.zero) {
      await Future.delayed(simulatedDelay);
    }

    final cleanUser = username.trim();
    final normalizedUser = cleanUser.toLowerCase();

    if (cleanUser.length < 3 || cleanUser.length > 15) {
      throw const AuthException('El nombre de usuario debe tener entre 3 y 15 caracteres.');
    }

    final validUsernameRegex = RegExp(r'^[a-zA-Z0-9_]+$');
    if (!validUsernameRegex.hasMatch(cleanUser)) {
      throw const AuthException('El usuario solo puede contener letras, números y guión bajo.');
    }

    if (password.length < 6) {
      throw const AuthException('La contraseña debe tener al menos 6 caracteres.');
    }

    if (_usersDb.containsKey(normalizedUser)) {
      throw const AuthException('El nombre de usuario ya está registrado. Elige otro.');
    }

    _usersDb[normalizedUser] = password;
    _currentUser = Usuario(
      id: 'usr_${normalizedUser.hashCode.abs()}',
      username: cleanUser,
    );
    return _currentUser!;
  }

  @override
  Future<void> logout() async {
    _currentUser = null;
  }
}
