import 'dart:async';
import 'dart:convert';
import 'package:equatable/equatable.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../../constantes.dart';
import '../../auth/models/usuario.dart';
import '../models/sala_partida.dart';

/// Eventos emitidos por el servidor hacia el cliente a través del canal de Lobby.
sealed class LobbyServerEvent extends Equatable {
  const LobbyServerEvent();

  @override
  List<Object?> get props => [];
}

/// Evento emitido cuando la sala se crea o actualiza su estado (jugadores, mapa, listos).
class LobbyRoomSynced extends LobbyServerEvent {
  final SalaPartida sala;
  const LobbyRoomSynced(this.sala);

  @override
  List<Object?> get props => [sala];
}

/// Evento emitido cuando el jugador actual es expulsado por el Game Master.
class LobbyPlayerKicked extends LobbyServerEvent {
  final String mensaje;
  const LobbyPlayerKicked(this.mensaje);

  @override
  List<Object?> get props => [mensaje];
}

/// Evento emitido cuando el Game Master inicia la partida y todos estaban listos.
class LobbyGameStarted extends LobbyServerEvent {
  final SalaPartida sala;
  const LobbyGameStarted(this.sala);

  @override
  List<Object?> get props => [sala];
}

/// Evento emitido cuando el servidor reporta un error de validación o conexión.
class LobbyErrorOccurred extends LobbyServerEvent {
  final String mensaje;
  const LobbyErrorOccurred(this.mensaje);

  @override
  List<Object?> get props => [mensaje];
}

/// Contrato abstracto para la comunicación en tiempo real de salas (Principio DIP).
abstract class LobbyRepository {
  /// Flujo continuo de eventos provenientes del servidor.
  Stream<LobbyServerEvent> get events;

  /// Conecta el cliente al servidor identificando al [usuario].
  Future<void> connect({
    required Usuario usuario,
    String? token,
  });

  /// Solicita al servidor crear una nueva sala con código único de 5 dígitos.
  void createRoom();

  /// Solicita al servidor unirse a una sala existente mediante su código de 5 dígitos.
  void joinRoom(String roomCode);

  /// Alterna el estado "Listo" del jugador actual en la sala.
  void toggleReady({bool? ready});

  /// Solicita cambiar el mapa seleccionado (1 al 4, exclusivo del Game Master).
  void selectMap(int mapId);

  /// Solicita expulsar a un jugador de la sala (exclusivo del Game Master).
  void kickPlayer(String targetPlayerId);

  /// Solicita iniciar la partida (exclusivo del Game Master cuando todos están listos).
  void startGame();

  /// Abandona la sala actual.
  void leaveRoom();

  /// Cierra la conexión activa.
  Future<void> disconnect();
}

/// Implementación basada en WebSockets que se conecta al servidor Shelf (`/ws`).
class WebSocketLobbyRepository implements LobbyRepository {
  final String wsBaseUrl;
  final WebSocketChannel Function(Uri uri)? _channelFactory;

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _channelSubscription;
  Timer? _heartbeatTimer;
  Usuario? _currentUser;

  final StreamController<LobbyServerEvent> _eventsController =
      StreamController<LobbyServerEvent>.broadcast();

  WebSocketLobbyRepository({
    this.wsBaseUrl = const String.fromEnvironment(
      'WS_URL',
      defaultValue: ConstantesJuego.wsServidorPorDefecto,
    ),
    WebSocketChannel Function(Uri uri)? channelFactory,
  }) : _channelFactory = channelFactory;

  @override
  Stream<LobbyServerEvent> get events => _eventsController.stream;

  @override
  Future<void> connect({
    required Usuario usuario,
    String? token,
  }) async {
    if (_channel != null && _currentUser?.id == usuario.id) {
      return;
    }

    await disconnect();
    _currentUser = usuario;

    final baseUri = Uri.parse(wsBaseUrl);
    final queryParams = <String, String>{
      ...baseUri.queryParameters,
      'userId': usuario.id,
      'username': usuario.username,
      if (token != null && token.isNotEmpty) 'token': token,
    };

    final uri = baseUri.replace(queryParameters: queryParams);

    try {
      final factory = _channelFactory ?? WebSocketChannel.connect;
      _channel = factory(uri);

      _channelSubscription = _channel!.stream.listen(
        _onRawMessage,
        onError: (_) {
          _eventsController.add(
            const LobbyErrorOccurred(
              'No se pudo conectar con el servidor Shelf. Verifica que esté en ejecución (dart run bin/server.dart).',
            ),
          );
          _cleanupSocket();
        },
        onDone: () {
          _cleanupSocket();
        },
      );

      _heartbeatTimer = Timer.periodic(const Duration(seconds: 25), (_) {
        _sendAction(ConstantesJuego.wsAccionPing, {});
      });
    } catch (_) {
      _eventsController.add(
        const LobbyErrorOccurred(
          'Error al abrir conexión WebSocket con el servidor.',
        ),
      );
    }
  }

  void _onRawMessage(dynamic raw) {
    if (raw is! String) return;
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final action = decoded['action'] as String? ?? '';
      final payload =
          (decoded['payload'] as Map<String, dynamic>?) ?? <String, dynamic>{};

      switch (action) {
        case ConstantesJuego.wsEventoSalaCreada:
        case ConstantesJuego.wsEventoSalaActualizada:
          final salaJson = payload['sala'] as Map<String, dynamic>;
          final sala = SalaPartida.fromJson(salaJson);
          _eventsController.add(LobbyRoomSynced(sala));
          break;

        case ConstantesJuego.wsEventoPartidaIniciada:
          final salaJson = payload['sala'] as Map<String, dynamic>;
          final sala = SalaPartida.fromJson(salaJson);
          _eventsController.add(LobbyGameStarted(sala));
          break;

        case ConstantesJuego.wsEventoJugadorExpulsado:
          final msg = payload['mensaje'] as String? ??
              ConstantesJuego.msgJugadorExpulsado;
          _eventsController.add(LobbyPlayerKicked(msg));
          break;

        case ConstantesJuego.wsEventoError:
          final msg =
              payload['mensaje'] as String? ?? 'Error desconocido en la sala.';
          _eventsController.add(LobbyErrorOccurred(msg));
          break;

        case ConstantesJuego.wsEventoPong:
          break;
      }
    } catch (_) {
      // Ignorar tramas malformadas
    }
  }

  void _sendAction(String action, Map<String, dynamic> payload) {
    final user = _currentUser;
    final enrichedPayload = <String, dynamic>{
      if (user != null) 'userId': user.id,
      if (user != null) 'username': user.username,
      ...payload,
    };

    try {
      _channel?.sink.add(
        jsonEncode({
          'action': action,
          'payload': enrichedPayload,
        }),
      );
    } catch (_) {
      _eventsController.add(
        const LobbyErrorOccurred(
          'Conexión perdida con el servidor. Intenta nuevamente.',
        ),
      );
    }
  }

  @override
  void createRoom() {
    _sendAction(ConstantesJuego.wsAccionCrearSala, {});
  }

  @override
  void joinRoom(String roomCode) {
    _sendAction(ConstantesJuego.wsAccionUnirseSala, {
      'room_code': roomCode.trim(),
    });
  }

  @override
  void toggleReady({bool? ready}) {
    _sendAction(ConstantesJuego.wsAccionAlternarListo, {
      if (ready != null) 'ready': ready,
    });
  }

  @override
  void selectMap(int mapId) {
    _sendAction(ConstantesJuego.wsAccionSeleccionarMapa, {
      'map_id': mapId,
    });
  }

  @override
  void kickPlayer(String targetPlayerId) {
    _sendAction(ConstantesJuego.wsAccionExpulsarJugador, {
      'target_player_id': targetPlayerId,
    });
  }

  @override
  void startGame() {
    _sendAction(ConstantesJuego.wsAccionIniciarPartida, {});
  }

  @override
  void leaveRoom() {
    _sendAction(ConstantesJuego.wsAccionSalirSala, {});
  }

  void _cleanupSocket() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    _channelSubscription?.cancel();
    _channelSubscription = null;
    _channel = null;
  }

  @override
  Future<void> disconnect() async {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    await _channelSubscription?.cancel();
    _channelSubscription = null;
    try {
      await _channel?.sink.close();
    } catch (_) {}
    _channel = null;
  }
}
