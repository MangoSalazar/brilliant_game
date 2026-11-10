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
  final String? notificacion;

  const LobbyRoomSynced(
    this.sala, {
    this.notificacion,
  });

  @override
  List<Object?> get props => [sala, notificacion];
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

/// Evento emitido cuando se pierde inesperadamente la conexión con el servidor.
class LobbyConnectionLost extends LobbyServerEvent {
  final String mensaje;
  const LobbyConnectionLost(this.mensaje);

  @override
  List<Object?> get props => [mensaje];
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
  void toggleReady({bool? ready, String? roomCode});

  /// Solicita cambiar el mapa seleccionado (1 al 4, exclusivo del Game Master).
  void selectMap(int mapId);

  /// Solicita expulsar a un jugador de la sala (exclusivo del Game Master).
  void kickPlayer(String targetPlayerId);

  /// Solicita iniciar la partida (exclusivo del Game Master cuando todos están listos).
  void startGame();

  /// Notifica al servidor que el jugador actual completó la fase inicial de Setup.
  void completeSetup() {}

  /// Notifica al servidor que el jugador actual completó su turno en la ronda actual
  /// (incluyendo opcionalmente los colores de las regiones que completó).
  void completeTurn({
    List<String> coloresCompletados = const [],
    bool tableroLleno = false,
  }) {}

  /// Notifica al servidor que el jugador actual pasa su turno en la ronda actual.
  void passTurn({bool tableroLleno = false}) {}

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
  Timer? _pendingRoomTimer;
  Usuario? _currentUser;
  String? _activeRoomCode;
  bool _isIntentionalClose = false;

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
    _isIntentionalClose = false;

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
      final channel = factory(uri);
      _channel = channel;

      unawaited(
        channel.ready.timeout(const Duration(seconds: 4)).catchError((_) {
          if (!_isIntentionalClose && identical(_channel, channel)) {
            _isIntentionalClose = true;
            _cleanupSocket();
            _eventsController.add(
              const LobbyErrorOccurred(
                'No se pudo conectar con el servidor Shelf. Verifica que esté en ejecución (dart run bin/server.dart).',
              ),
            );
          }
        }),
      );

      _channelSubscription = channel.stream.listen(
        _onRawMessage,
        onError: (_) {
          if (_isIntentionalClose) return;
          final wasInRoom = _activeRoomCode != null;
          _isIntentionalClose = true;
          _cleanupSocket();
          if (wasInRoom) {
            _eventsController.add(
              const LobbyConnectionLost(ConstantesJuego.errorConexionPerdida),
            );
          } else {
            _eventsController.add(
              const LobbyErrorOccurred(
                'No se pudo conectar con el servidor Shelf. Verifica que esté en ejecución (dart run bin/server.dart).',
              ),
            );
          }
        },
        onDone: () {
          final wasIntentional = _isIntentionalClose;
          final hadActiveRoom = _activeRoomCode != null;
          _isIntentionalClose = true;
          _cleanupSocket();
          if (!wasIntentional) {
            if (hadActiveRoom) {
              _eventsController.add(
                const LobbyConnectionLost(ConstantesJuego.errorConexionPerdida),
              );
            } else {
              _eventsController.add(
                const LobbyErrorOccurred(
                  'No se pudo conectar con el servidor Shelf. Verifica que esté en ejecución (dart run bin/server.dart).',
                ),
              );
            }
          }
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
        case ConstantesJuego.wsEventoDadosLanzados:
        case ConstantesJuego.wsEventoPuntuacionesActualizadas:
        case ConstantesJuego.wsEventoPartidaFinalizada:
          _pendingRoomTimer?.cancel();
          _pendingRoomTimer = null;
          final salaJson = payload['sala'] as Map<String, dynamic>;
          final sala = SalaPartida.fromJson(salaJson);
          final notificacion = payload['notificacion'] as String?;
          _activeRoomCode = sala.codigo;
          _eventsController.add(
            LobbyRoomSynced(sala, notificacion: notificacion),
          );
          break;

        case ConstantesJuego.wsEventoPartidaIniciada:
          _pendingRoomTimer?.cancel();
          _pendingRoomTimer = null;
          final salaJson = payload['sala'] as Map<String, dynamic>;
          final sala = SalaPartida.fromJson(salaJson);
          _activeRoomCode = sala.codigo;
          _eventsController.add(LobbyGameStarted(sala));
          break;

        case ConstantesJuego.wsEventoJugadorExpulsado:
          _pendingRoomTimer?.cancel();
          _pendingRoomTimer = null;
          _activeRoomCode = null;
          final msg = payload['mensaje'] as String? ??
              ConstantesJuego.msgJugadorExpulsado;
          _eventsController.add(LobbyPlayerKicked(msg));
          break;

        case ConstantesJuego.wsEventoError:
          _pendingRoomTimer?.cancel();
          _pendingRoomTimer = null;
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
    final channel = _channel;
    if (channel == null) {
      if (action != ConstantesJuego.wsAccionPing &&
          action != ConstantesJuego.wsAccionSalirSala) {
        _eventsController.add(
          const LobbyConnectionLost(ConstantesJuego.errorConexionPerdida),
        );
      }
      return;
    }

    final user = _currentUser;
    final enrichedPayload = <String, dynamic>{
      if (user != null) 'userId': user.id,
      if (user != null) 'username': user.username,
      if (_activeRoomCode != null && !payload.containsKey('room_code'))
        'room_code': _activeRoomCode,
      ...payload,
    };

    try {
      channel.sink.add(
        jsonEncode({
          'action': action,
          'payload': enrichedPayload,
        }),
      );
    } catch (_) {
      _cleanupSocket();
      _eventsController.add(
        const LobbyConnectionLost(ConstantesJuego.errorConexionPerdida),
      );
    }
  }

  void _startPendingRoomTimeout() {
    _pendingRoomTimer?.cancel();
    _pendingRoomTimer = Timer(const Duration(seconds: 5), () {
      if (_activeRoomCode == null && !_isIntentionalClose) {
        _isIntentionalClose = true;
        _cleanupSocket();
        _eventsController.add(
          const LobbyErrorOccurred(
            'El servidor no está disponible en este momento. Verifica que esté en ejecución.',
          ),
        );
      }
    });
  }

  @override
  void createRoom() {
    _startPendingRoomTimeout();
    _sendAction(ConstantesJuego.wsAccionCrearSala, {});
  }

  @override
  void joinRoom(String roomCode) {
    final cleanCode = roomCode.trim();
    _startPendingRoomTimeout();
    _sendAction(ConstantesJuego.wsAccionUnirseSala, {
      'room_code': cleanCode,
    });
  }

  @override
  void toggleReady({bool? ready, String? roomCode}) {
    _sendAction(ConstantesJuego.wsAccionAlternarListo, {
      if (ready != null) 'ready': ready,
      if (roomCode != null && roomCode.isNotEmpty) 'room_code': roomCode,
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
  void completeSetup() {
    _sendAction(ConstantesJuego.wsAccionCompletarSetup, {});
  }

  @override
  void completeTurn({
    List<String> coloresCompletados = const [],
    bool tableroLleno = false,
  }) {
    for (final colorId in coloresCompletados) {
      _sendAction(ConstantesJuego.wsAccionCompletarRegion, {
        'region_tipo': colorId,
        'color_id': colorId,
      });
    }
    _sendAction(ConstantesJuego.wsAccionCompletarTurno, {
      'colores_completados': coloresCompletados,
      'tablero_lleno': tableroLleno,
    });
  }

  @override
  void passTurn({bool tableroLleno = false}) {
    _sendAction(ConstantesJuego.wsAccionPasarTurno, {
      'tablero_lleno': tableroLleno,
    });
  }

  @override
  void leaveRoom() {
    _pendingRoomTimer?.cancel();
    _pendingRoomTimer = null;
    if (_activeRoomCode != null) {
      _activeRoomCode = null;
      _sendAction(ConstantesJuego.wsAccionSalirSala, {});
    } else {
      // Si estaba intentando conectar y el usuario canceló la solicitud, cerrar el socket pendiente de inmediato
      _isIntentionalClose = true;
      _cleanupSocket();
    }
  }

  void _cleanupSocket() {
    _activeRoomCode = null;
    _pendingRoomTimer?.cancel();
    _pendingRoomTimer = null;
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    _channelSubscription?.cancel();
    _channelSubscription = null;
    final oldChannel = _channel;
    _channel = null;
    if (oldChannel != null) {
      unawaited(oldChannel.sink.close().catchError((_) {}));
    }
  }

  @override
  Future<void> disconnect() async {
    _isIntentionalClose = true;
    _cleanupSocket();
  }
}
