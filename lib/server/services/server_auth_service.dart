import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../../constantes.dart';
import '../../features/auth/models/usuario.dart';
import '../../features/auth/repositories/auth_repository.dart';

/// Resultado de una operación exitosa de autenticación en el servidor.
class ServerAuthResult {
  final Usuario usuario;
  final String token;

  const ServerAuthResult({
    required this.usuario,
    required this.token,
  });

  Map<String, dynamic> toJson() => {
        'token': token,
        'usuario': usuario.toJson(),
      };
}

/// Servicio de autenticación del servidor (SRP: gestión de cuentas, hashes y tokens).
class ServerAuthService {
  static const String _secretSalt = 'brilliant_game_salt_2026';

  /// Almacén de usuarios: username normalizado -> hash de contraseña.
  final Map<String, String> _passwordHashes = {};

  /// Almacén de entidades Usuario por username normalizado.
  final Map<String, Usuario> _usersByNormalizedName = {};

  /// Mapa de tokens activos -> Usuario.
  final Map<String, Usuario> _activeTokens = {};

  ServerAuthService() {
    // Precargar cuentas de prueba para facilitar pruebas multijugador inmediatas
    _seedUser('mango', 'mango123');
    _seedUser('mango2', 'mango123');
    _seedUser('jugador1', 'Password123');
    _seedUser('jugador2', 'Password123');
    _seedUser('admin', 'admin123');
  }

  void _seedUser(String username, String password) {
    final normalized = username.toLowerCase();
    _passwordHashes[normalized] = _hashPassword(normalized, password);
    _usersByNormalizedName[normalized] = Usuario(
      id: 'usr_${normalized.hashCode.abs()}',
      username: username,
    );
  }

  String _hashPassword(String normalizedUsername, String password) {
    final bytes = utf8.encode('$normalizedUsername:$password:$_secretSalt');
    return sha256.convert(bytes).toString();
  }

  String _generateToken(Usuario usuario) {
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    final raw = '${usuario.id}:${usuario.username}:$timestamp:$_secretSalt';
    final signature = sha256.convert(utf8.encode(raw)).toString();
    final payload = base64Url.encode(utf8.encode('${usuario.id}:${usuario.username}'));
    return '$payload.$signature';
  }

  /// Registra un nuevo usuario en el servidor validando formato y unicidad.
  ServerAuthResult register({
    required String username,
    required String password,
  }) {
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

    if (_passwordHashes.containsKey(normalizedUser)) {
      throw const AuthException(
        'El nombre de usuario ya está registrado. Elige otro.',
      );
    }

    final usuario = Usuario(
      id: 'usr_${normalizedUser.hashCode.abs()}',
      username: cleanUser,
    );

    _passwordHashes[normalizedUser] = _hashPassword(normalizedUser, password);
    _usersByNormalizedName[normalizedUser] = usuario;

    final token = _generateToken(usuario);
    _activeTokens[token] = usuario;

    return ServerAuthResult(usuario: usuario, token: token);
  }

  /// Autentica un usuario existente y genera un token de sesión.
  ServerAuthResult login({
    required String username,
    required String password,
  }) {
    final cleanUser = username.trim();
    final normalizedUser = cleanUser.toLowerCase();

    if (!_passwordHashes.containsKey(normalizedUser)) {
      throw const AuthException(ConstantesJuego.errorCredencialesInvalidas);
    }

    final expectedHash = _passwordHashes[normalizedUser];
    final providedHash = _hashPassword(normalizedUser, password);

    if (expectedHash != providedHash) {
      throw const AuthException(ConstantesJuego.errorCredencialesInvalidas);
    }

    final usuario = _usersByNormalizedName[normalizedUser]!;
    final token = _generateToken(usuario);
    _activeTokens[token] = usuario;

    return ServerAuthResult(usuario: usuario, token: token);
  }

  /// Verifica un token de sesión y retorna el [Usuario] asociado, o `null` si es inválido.
  Usuario? verifyToken(String? token) {
    if (token == null || token.isEmpty) return null;
    final cleanToken =
        token.startsWith('Bearer ') ? token.substring(7).trim() : token.trim();
    return _activeTokens[cleanToken];
  }
}
