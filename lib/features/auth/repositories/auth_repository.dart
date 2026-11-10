import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../constantes.dart';
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

  /// Token de sesión JWT expedido por el servidor (si aplica).
  String? get currentToken => null;
}

/// Implementación remota que se comunica por HTTP REST con el Servidor Shelf.
/// Si el servidor no responde, utiliza [LocalAuthRepository] como respaldo local.
class RemoteAuthRepository implements AuthRepository {
  final String baseUrl;
  final http.Client _httpClient;
  final LocalAuthRepository _fallbackLocal;

  Usuario? _currentUser;
  String? _currentToken;

  RemoteAuthRepository({
    this.baseUrl = const String.fromEnvironment(
      'SERVER_URL',
      defaultValue: ConstantesJuego.urlServidorPorDefecto,
    ),
    http.Client? httpClient,
  })  : _httpClient = httpClient ?? http.Client(),
        _fallbackLocal = LocalAuthRepository(simulatedDelay: Duration.zero);

  @override
  Usuario? get currentUser => _currentUser;

  @override
  String? get currentToken => _currentToken;

  @override
  Future<Usuario> login({
    required String username,
    required String password,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/api/auth/login');
      final response = await _httpClient
          .post(
            uri,
            headers: {'content-type': 'application/json; charset=utf-8'},
            body: jsonEncode({
              'username': username.trim(),
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 5));

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) {
        _currentToken = data['token'] as String?;
        _currentUser = Usuario.fromJson(data['usuario'] as Map<String, dynamic>);
        return _currentUser!;
      } else {
        throw AuthException(
          data['error'] as String? ?? ConstantesJuego.errorCredencialesInvalidas,
        );
      }
    } on AuthException {
      rethrow;
    } catch (_) {
      // Si el servidor Shelf no está encendido aún, usar validación local de respaldo
      final user = await _fallbackLocal.login(
        username: username,
        password: password,
      );
      _currentUser = user;
      return user;
    }
  }

  @override
  Future<Usuario> register({
    required String username,
    required String password,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/api/auth/register');
      final response = await _httpClient
          .post(
            uri,
            headers: {'content-type': 'application/json; charset=utf-8'},
            body: jsonEncode({
              'username': username.trim(),
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 5));

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 201 || response.statusCode == 200) {
        _currentToken = data['token'] as String?;
        _currentUser = Usuario.fromJson(data['usuario'] as Map<String, dynamic>);
        return _currentUser!;
      } else {
        throw AuthException(
          data['error'] as String? ?? 'No fue posible registrar el usuario.',
        );
      }
    } on AuthException {
      rethrow;
    } catch (_) {
      final user = await _fallbackLocal.register(
        username: username,
        password: password,
      );
      _currentUser = user;
      return user;
    }
  }

  @override
  Future<void> logout() async {
    final user = _currentUser;
    final token = _currentToken;
    _currentUser = null;
    _currentToken = null;

    try {
      final uri = Uri.parse('$baseUrl/api/auth/logout');
      await _httpClient
          .post(
            uri,
            headers: {
              'content-type': 'application/json; charset=utf-8',
              if (token != null && token.isNotEmpty)
                'authorization': 'Bearer $token',
            },
            body: jsonEncode({
              if (user != null) 'userId': user.id,
              if (user != null) 'username': user.username,
              if (token != null) 'token': token,
            }),
          )
          .timeout(const Duration(seconds: 3));
    } catch (_) {
      // Ignorar si el servidor está apagado al cerrar sesión
    }

    await _fallbackLocal.logout();
  }
}

/// Implementación local / en memoria de autenticación para desarrollo y pruebas.
/// Valida credenciales, almacena usuarios creados y simula la respuesta de red.
class LocalAuthRepository implements AuthRepository {
  final Duration simulatedDelay;

  LocalAuthRepository({
    this.simulatedDelay = const Duration(milliseconds: 500),
  });

  final Map<String, String> _usersDb = {
    // Usuarios de prueba precargados
    'mango': 'mango123',
    'mango2': 'mango123',
    'jugador1': 'Password123',
    'jugador2': 'Password123',
    'admin': 'admin123',
  };

  Usuario? _currentUser;

  @override
  Usuario? get currentUser => _currentUser;

  @override
  String? get currentToken => null;

  @override
  Future<Usuario> login({
    required String username,
    required String password,
  }) async {
    if (simulatedDelay > Duration.zero) {
      await Future.delayed(simulatedDelay);
    }

    final normalizedUser = username.trim().toLowerCase();
    if (!_usersDb.containsKey(normalizedUser)) {
      throw const AuthException(
        'Usuario no encontrado. Verifica tus credenciales o regístrate.',
      );
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
    if (simulatedDelay > Duration.zero) {
      await Future.delayed(simulatedDelay);
    }

    final cleanUser = username.trim();
    final normalizedUser = cleanUser.toLowerCase();

    if (cleanUser.length < 3 || cleanUser.length > 15) {
      throw const AuthException(
        'El nombre de usuario debe tener entre 3 y 15 caracteres.',
      );
    }

    final validUsernameRegex = RegExp(r'^[a-zA-Z0-9_]+$');
    if (!validUsernameRegex.hasMatch(cleanUser)) {
      throw const AuthException(
        'El usuario solo puede contener letras, números y guión bajo.',
      );
    }

    if (password.length < 6) {
      throw const AuthException(
        'La contraseña debe tener al menos 6 caracteres.',
      );
    }

    if (_usersDb.containsKey(normalizedUser)) {
      throw const AuthException(
        'El nombre de usuario ya está registrado. Elige otro.',
      );
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
