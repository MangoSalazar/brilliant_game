import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import '../constantes.dart';
import 'routes/auth_routes.dart';
import 'services/room_manager.dart';
import 'services/server_auth_service.dart';
import 'ws/lobby_ws_handler.dart';

/// Aplicación principal del Servidor Backend implementada con Shelf.
class BrilliantServerApp {
  final ServerAuthService authService;
  final RoomManager roomManager;
  late final LobbyWsHandler lobbyWsHandler;

  BrilliantServerApp({
    ServerAuthService? authService,
    RoomManager? roomManager,
  })  : authService = authService ?? ServerAuthService(),
        roomManager = roomManager ?? RoomManager() {
    lobbyWsHandler = LobbyWsHandler(
      roomManager: this.roomManager,
      authService: this.authService,
    );
  }

  /// Construye el [Handler] completo de Shelf con middlewares CORS y rutas.
  Handler get handler {
    final router = Router();

    // Estado y salud del servidor
    router.get('/api/health', (Request request) {
      return Response.ok(
        jsonEncode({
          'status': 'ok',
          'service': 'Brilliant Game Shelf Server',
          'activeRooms': roomManager.salasActivas.length,
        }),
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    });

    // Rutas REST de Autenticación (/api/auth/register, /api/auth/login, /api/auth/me)
    final authRoutes = AuthRoutes(authService);
    router.mount('/api/auth', authRoutes.router.call);

    // Ruta WebSocket para Lobbies y Salas en tiempo real (/ws)
    router.get('/ws', lobbyWsHandler.handler);

    return const Pipeline()
        .addMiddleware(_corsMiddleware())
        .addHandler(router.call);
  }

  /// Middleware CORS universal para permitir conexiones desde Flutter Web y dispositivos en red.
  static Middleware _corsMiddleware() {
    const corsHeaders = {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
      'Access-Control-Allow-Headers': 'Origin, Content-Type, Authorization, Accept',
    };

    return (Handler innerHandler) {
      return (Request request) async {
        if (request.method == 'OPTIONS') {
          return Response.ok('', headers: corsHeaders);
        }
        final response = await innerHandler(request);
        return response.change(headers: corsHeaders);
      };
    };
  }
}

/// Inicia el servidor HTTP/WebSocket de Brilliant Game en el host y puerto indicados.
Future<HttpServer> startBrilliantServer({
  String host = '0.0.0.0',
  int port = ConstantesJuego.puertoServidorPorDefecto,
  BrilliantServerApp? app,
  bool enableLogging = true,
}) async {
  final serverApp = app ?? BrilliantServerApp();
  Handler pipeline = serverApp.handler;
  if (enableLogging) {
    pipeline = const Pipeline().addMiddleware(logRequests()).addHandler(pipeline);
  }

  final server = await shelf_io.serve(pipeline, host, port);
  return server;
}
