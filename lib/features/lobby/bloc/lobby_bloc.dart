import 'dart:async';
import 'package:bloc/bloc.dart';
import '../../auth/models/usuario.dart';
import '../models/jugador_sala.dart';
import '../models/sala_partida.dart';
import '../repositories/lobby_repository.dart';
import 'lobby_event.dart';
import 'lobby_state.dart';

/// BLoC responsable de coordinar las acciones de sala (crear, unirse, elegir mapa,
/// marcarse listo, expulsar jugadores e iniciar partida) con el servidor.
class LobbyBloc extends Bloc<LobbyEvent, LobbyState> {
  final LobbyRepository _lobbyRepository;
  StreamSubscription<LobbyServerEvent>? _eventsSubscription;
  Usuario? _currentUser;

  LobbyBloc({
    required LobbyRepository lobbyRepository,
  })  : _lobbyRepository = lobbyRepository,
        super(const LobbyState()) {
    on<LobbyCreateRoomRequested>(_onCreateRoomRequested);
    on<LobbyJoinRoomRequested>(_onJoinRoomRequested);
    on<LobbyToggleReadyRequested>(_onToggleReadyRequested);
    on<LobbySelectMapRequested>(_onSelectMapRequested);
    on<LobbyKickPlayerRequested>(_onKickPlayerRequested);
    on<LobbyStartGameRequested>(_onStartGameRequested);
    on<LobbyLeaveRoomRequested>(_onLeaveRoomRequested);
    on<LobbyClearErrorRequested>(_onClearErrorRequested);
    on<LobbyClearInfoRequested>(_onClearInfoRequested);
    on<LobbyServerEventReceived>(_onServerEventReceived);

    _eventsSubscription = _lobbyRepository.events.listen((serverEvent) {
      add(LobbyServerEventReceived(serverEvent));
    });
  }

  Future<void> _onCreateRoomRequested(
    LobbyCreateRoomRequested event,
    Emitter<LobbyState> emit,
  ) async {
    _currentUser = event.usuario;
    emit(state.copyWith(
      status: LobbyStatus.connecting,
      clearError: true,
      clearInfo: true,
    ));

    await _lobbyRepository.connect(
      usuario: event.usuario,
      token: event.token,
    );
    _lobbyRepository.createRoom();
  }

  Future<void> _onJoinRoomRequested(
    LobbyJoinRoomRequested event,
    Emitter<LobbyState> emit,
  ) async {
    _currentUser = event.usuario;
    emit(state.copyWith(
      status: LobbyStatus.connecting,
      clearError: true,
      clearInfo: true,
    ));

    await _lobbyRepository.connect(
      usuario: event.usuario,
      token: event.token,
    );
    _lobbyRepository.joinRoom(event.codigoSala);
  }

  void _onToggleReadyRequested(
    LobbyToggleReadyRequested event,
    Emitter<LobbyState> emit,
  ) {
    final salaActual = state.sala;
    final userId = _currentUser?.id;
    bool? nuevoValorListo = event.ready;

    if (salaActual != null) {
      final indice = userId != null
          ? salaActual.jugadores.indexWhere((j) => j.id == userId)
          : -1;

      if (indice != -1) {
        final jugador = salaActual.jugadores[indice];
        nuevoValorListo ??= !jugador.esListo;

        final jugadoresActualizados =
            List<JugadorSala>.from(salaActual.jugadores);
        jugadoresActualizados[indice] = jugador.copyWith(
          esListo: nuevoValorListo,
        );

        final todosListos = jugadoresActualizados.isNotEmpty &&
            jugadoresActualizados.every((j) => j.esListo);

        final salaOptimista = salaActual.copyWith(
          jugadores: jugadoresActualizados,
          estadoSala:
              todosListos ? EstadoSala.todosListos : EstadoSala.esperando,
        );

        emit(state.copyWith(
          status: LobbyStatus.inLobby,
          sala: salaOptimista,
          clearError: true,
        ));
      }
    }

    _lobbyRepository.toggleReady(
      ready: nuevoValorListo,
      roomCode: salaActual?.codigo,
    );
  }

  void _onSelectMapRequested(
    LobbySelectMapRequested event,
    Emitter<LobbyState> emit,
  ) {
    _lobbyRepository.selectMap(event.mapaId);
  }

  void _onKickPlayerRequested(
    LobbyKickPlayerRequested event,
    Emitter<LobbyState> emit,
  ) {
    _lobbyRepository.kickPlayer(event.targetPlayerId);
  }

  void _onStartGameRequested(
    LobbyStartGameRequested event,
    Emitter<LobbyState> emit,
  ) {
    _lobbyRepository.startGame();
  }

  void _onLeaveRoomRequested(
    LobbyLeaveRoomRequested event,
    Emitter<LobbyState> emit,
  ) {
    _lobbyRepository.leaveRoom();
    emit(const LobbyState(status: LobbyStatus.initial));
  }

  void _onClearErrorRequested(
    LobbyClearErrorRequested event,
    Emitter<LobbyState> emit,
  ) {
    emit(state.copyWith(
      status: state.sala != null ? LobbyStatus.inLobby : LobbyStatus.initial,
      clearError: true,
    ));
  }

  void _onClearInfoRequested(
    LobbyClearInfoRequested event,
    Emitter<LobbyState> emit,
  ) {
    emit(state.copyWith(clearInfo: true));
  }

  void _onServerEventReceived(
    LobbyServerEventReceived event,
    Emitter<LobbyState> emit,
  ) {
    final serverEvent = event.serverEvent;
    switch (serverEvent) {
      case LobbyRoomSynced(:final sala, :final notificacion):
        emit(LobbyState(
          status: LobbyStatus.inLobby,
          sala: sala,
          errorMessage: null,
          infoMessage: notificacion,
        ));
        break;

      case LobbyGameStarted(:final sala):
        emit(LobbyState(
          status: LobbyStatus.inGame,
          sala: sala,
          errorMessage: null,
          infoMessage: null,
        ));
        break;

      case LobbyPlayerKicked(:final mensaje):
        emit(LobbyState(
          status: LobbyStatus.kicked,
          sala: null,
          errorMessage: mensaje,
          infoMessage: null,
        ));
        break;

      case LobbyConnectionLost(:final mensaje):
        emit(LobbyState(
          status: LobbyStatus.error,
          sala: null,
          errorMessage: mensaje,
          infoMessage: null,
        ));
        break;

      case LobbyErrorOccurred(:final mensaje):
        emit(state.copyWith(
          status: state.sala != null ? LobbyStatus.inLobby : LobbyStatus.error,
          errorMessage: mensaje,
        ));
        break;
    }
  }

  @override
  Future<void> close() async {
    await _eventsSubscription?.cancel();
    await _lobbyRepository.disconnect();
    return super.close();
  }
}
