import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../../features/auth/repositories/auth_repository.dart';
import '../services/server_auth_service.dart';

/// Enrutador REST para los endpoints de autenticación del servidor Shelf.
class AuthRoutes {
  final ServerAuthService _authService;

  AuthRoutes(this._authService);

  Router get router {
    final router = Router();

    router.post('/register', _handleRegister);
    router.post('/login', _handleLogin);
    router.get('/me', _handleMe);

    return router;
  }

  static const Map<String, String> _jsonHeaders = {
    'content-type': 'application/json; charset=utf-8',
  };

  Future<Response> _handleRegister(Request request) async {
    try {
      final bodyStr = await request.readAsString();
      final body = jsonDecode(bodyStr) as Map<String, dynamic>;
      final username = body['username'] as String? ?? '';
      final password = body['password'] as String? ?? '';

      final result = _authService.register(
        username: username,
        password: password,
      );

      return Response(
        201,
        body: jsonEncode(result.toJson()),
        headers: _jsonHeaders,
      );
    } on AuthException catch (e) {
      final statusCode = e.message.contains('ya está registrado') ? 409 : 400;
      return Response(
        statusCode,
        body: jsonEncode({'error': e.message}),
        headers: _jsonHeaders,
      );
    } catch (_) {
      return Response(
        400,
        body: jsonEncode({'error': 'Formato de solicitud inválido.'}),
        headers: _jsonHeaders,
      );
    }
  }

  Future<Response> _handleLogin(Request request) async {
    try {
      final bodyStr = await request.readAsString();
      final body = jsonDecode(bodyStr) as Map<String, dynamic>;
      final username = body['username'] as String? ?? '';
      final password = body['password'] as String? ?? '';

      final result = _authService.login(
        username: username,
        password: password,
      );

      return Response.ok(
        jsonEncode(result.toJson()),
        headers: _jsonHeaders,
      );
    } on AuthException catch (e) {
      return Response(
        401,
        body: jsonEncode({'error': e.message}),
        headers: _jsonHeaders,
      );
    } catch (_) {
      return Response(
        400,
        body: jsonEncode({'error': 'Formato de solicitud inválido.'}),
        headers: _jsonHeaders,
      );
    }
  }

  Future<Response> _handleMe(Request request) async {
    final authHeader = request.headers['authorization'];
    final usuario = _authService.verifyToken(authHeader);

    if (usuario == null) {
      return Response(
        401,
        body: jsonEncode({'error': 'Token inválido o sesión expirada.'}),
        headers: _jsonHeaders,
      );
    }

    return Response.ok(
      jsonEncode({'usuario': usuario.toJson()}),
      headers: _jsonHeaders,
    );
  }
}
