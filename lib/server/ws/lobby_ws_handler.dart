import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../constantes.dart';
import '../../features/lobby/models/sala_partida.dart';
import '../services/room_manager.dart';
import '../services/server_auth_service.dart';

/// Sesión activa de un cliente conectado por WebSocket al servidor.
class _ClientSession {
  String userId;
  String username;
  String? currentRoomCode;
  final WebSocketChannel channel;

  _ClientSession({
    required this.userId,
    required this.username,
    required this.channel,
  });
}

/// Controlador de conexiones WebSocket en tiempo real para Lobbies (`/ws`).
class LobbyWsHandler {
  final RoomManager _roomManager;
  final ServerAuthService _authService;

  /// Sesiones activas indexadas por `userId`.
  final Map<String, _ClientSession> _sessionsByUserId = {};

  LobbyWsHandler({
    required RoomManager roomManager,
    required ServerAuthService authService,
  })  : _roomManager = roomManager,
        _authService = authService;

  /// Crea el [Handler] de Shelf para procesar el upgrade a WebSocket.
  Handler get handler {
    return (Request request) {
      final params = request.url.queryParameters;
      final token = params['token'];
      final verifiedUser = _authService.verifyToken(token);

      final initialUserId = verifiedUser?.id ??
          params['userId'] ??
          'usr_${DateTime.now().microsecondsSinceEpoch}';
      final initialUsername =
          verifiedUser?.username ?? params['username'] ?? 'Jugador';

      final wsHandler = webSocketHandler((WebSocketChannel channel, String? protocol) {
        _onClientConnected(
          channel: channel,
          userId: initialUserId,
          username: initialUsername,
        );
      });

      return wsHandler(request);
    };
  }

  void _onClientConnected({
    required WebSocketChannel channel,
    required String userId,
    required String username,
  }) {
    final session = _ClientSession(
      userId: userId,
      username: username,
      channel: channel,
    );

    _sessionsByUserId[userId] = session;

    channel.stream.listen(
      (dynamic rawMessage) {
        if (rawMessage is String) {
          _handleMessage(session, rawMessage);
        }
      },
      onDone: () => _handleDisconnect(session),
      onError: (_) => _handleDisconnect(session),
    );
  }

  void _handleMessage(_ClientSession session, String rawMessage) {
    Map<String, dynamic> decoded;
    try {
      decoded = jsonDecode(rawMessage) as Map<String, dynamic>;
    } catch (_) {
      _sendError(session, 'Mensaje JSON malformado.');
      return;
    }

    final action = decoded['action'] as String? ?? '';
    final payload =
        (decoded['payload'] as Map<String, dynamic>?) ?? <String, dynamic>{};

    // Permitir actualizar identidad desde el payload si se envía explícitamente
    if (payload['userId'] is String && (payload['userId'] as String).isNotEmpty) {
      final newId = payload['userId'] as String;
      if (newId != session.userId) {
        _sessionsByUserId.remove(session.userId);
        session.userId = newId;
        _sessionsByUserId[newId] = session;
      }
    }
    if (payload['username'] is String &&
        (payload['username'] as String).isNotEmpty) {
      session.username = payload['username'] as String;
    }

    try {
      switch (action) {
        case ConstantesJuego.wsAccionPing:
          _sendToSession(session, ConstantesJuego.wsEventoPong, {});
          break;

        case ConstantesJuego.wsAccionCrearSala:
          _salirDeSalaActualSiExiste(session);
          final sala = _roomManager.crearSala(
            jugadorId: session.userId,
            nombreJugador: session.username,
          );
          session.currentRoomCode = sala.codigo;
          _sendToSession(
            session,
            ConstantesJuego.wsEventoSalaCreada,
            {'sala': sala.toJson()},
          );
          break;

        case ConstantesJuego.wsAccionUnirseSala:
          final codigo = (payload['room_code'] ?? payload['codigo'] ?? '')
              .toString()
              .trim();
          if (session.currentRoomCode != null &&
              session.currentRoomCode != codigo) {
            _salirDeSalaActualSiExiste(session);
          }
          final sala = _roomManager.unirseASala(
            codigo: codigo,
            jugadorId: session.userId,
            nombreJugador: session.username,
          );
          session.currentRoomCode = sala.codigo;
          _broadcastToRoom(
            sala,
            ConstantesJuego.wsEventoSalaActualizada,
            {'sala': sala.toJson()},
          );
          break;

        case ConstantesJuego.wsAccionAlternarListo:
          final codigo = _requireRoomCode(session, payload);
          final bool? ready = payload['ready'] as bool?;
          final sala = _roomManager.cambiarEstadoListo(
            codigo: codigo,
            jugadorId: session.userId,
            listo: ready,
          );
          _broadcastToRoom(
            sala,
            ConstantesJuego.wsEventoSalaActualizada,
            {'sala': sala.toJson()},
          );
          break;

        case ConstantesJuego.wsAccionSeleccionarMapa:
          final codigo = _requireRoomCode(session, payload);
          final mapaId = (payload['map_id'] ?? payload['mapaSeleccionado'] ?? 1) as int;
          final sala = _roomManager.seleccionarMapa(
            codigo: codigo,
            solicitanteId: session.userId,
            mapaId: mapaId,
          );
          _broadcastToRoom(
            sala,
            ConstantesJuego.wsEventoSalaActualizada,
            {'sala': sala.toJson()},
          );
          break;

        case ConstantesJuego.wsAccionExpulsarJugador:
          final codigo = _requireRoomCode(session, payload);
          final targetId =
              (payload['target_player_id'] ?? payload['jugadorId'] ?? '')
                  .toString();
          final sala = _roomManager.expulsarJugador(
            codigo: codigo,
            solicitanteId: session.userId,
            objetivoId: targetId,
          );

          // Notificar al jugador expulsado y desvincularlo de la sala
          final kickedSession = _sessionsByUserId[targetId];
          if (kickedSession != null) {
            kickedSession.currentRoomCode = null;
            _sendToSession(
              kickedSession,
              ConstantesJuego.wsEventoJugadorExpulsado,
              {'mensaje': ConstantesJuego.msgJugadorExpulsado},
            );
          }

          // Difundir la sala actualizada al resto de integrantes
          _broadcastToRoom(
            sala,
            ConstantesJuego.wsEventoSalaActualizada,
            {'sala': sala.toJson()},
          );
          break;

        case ConstantesJuego.wsAccionIniciarPartida:
          final codigo = _requireRoomCode(session, payload);
          final sala = _roomManager.iniciarPartida(
            codigo: codigo,
            solicitanteId: session.userId,
          );
          _broadcastToRoom(
            sala,
            ConstantesJuego.wsEventoPartidaIniciada,
            {'sala': sala.toJson()},
          );
          break;

        case ConstantesJuego.wsAccionSalirSala:
          _salirDeSalaActualSiExiste(session);
          break;

        default:
          _sendError(session, 'Acción no reconocida: $action');
      }
    } on RoomException catch (e) {
      _sendError(session, e.message);
    } catch (e) {
      _sendError(session, 'Error procesando solicitud: $e');
    }
  }

  String _requireRoomCode(
    _ClientSession session,
    Map<String, dynamic> payload,
  ) {
    final code = (payload['room_code'] ??
            payload['codigo'] ??
            session.currentRoomCode ??
            '')
        .toString()
        .trim();
    if (code.isEmpty) {
      throw const RoomException('No te encuentras en ninguna sala activa.');
    }
    return code;
  }

  void _salirDeSalaActualSiExiste(_ClientSession session) {
    final roomCode = session.currentRoomCode;
    if (roomCode == null) return;

    session.currentRoomCode = null;
    final salaRestante = _roomManager.removerJugador(
      codigo: roomCode,
      jugadorId: session.userId,
    );

    if (salaRestante != null) {
      _broadcastToRoom(
        salaRestante,
        ConstantesJuego.wsEventoSalaActualizada,
        {'sala': salaRestante.toJson()},
      );
    }
  }

  void _handleDisconnect(_ClientSession session) {
    _salirDeSalaActualSiExiste(session);
    if (_sessionsByUserId[session.userId] == session) {
      _sessionsByUserId.remove(session.userId);
    }
  }

  void _broadcastToRoom(
    SalaPartida sala,
    String eventName,
    Map<String, dynamic> payload,
  ) {
    for (final jugador in sala.jugadores) {
      final targetSession = _sessionsByUserId[jugador.id];
      if (targetSession != null) {
        _sendToSession(targetSession, eventName, payload);
      }
    }
  }

  void _sendError(_ClientSession session, String message) {
    _sendToSession(
      session,
      ConstantesJuego.wsEventoError,
      {'mensaje': message},
    );
  }

  void _sendToSession(
    _ClientSession session,
    String action,
    Map<String, dynamic> payload,
  ) {
    try {
      final encoded = jsonEncode({
        'action': action,
        'payload': payload,
      });
      session.channel.sink.add(encoded);
    } catch (_) {
      // Canal cerrado o error de escritura
    }
  }
}
