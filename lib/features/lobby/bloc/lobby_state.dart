import 'package:equatable/equatable.dart';
import '../models/sala_partida.dart';

/// Estados de navegación y conexión del módulo de Lobby.
enum LobbyStatus {
  initial,
  connecting,
  inLobby,
  inGame,
  kicked,
  error,
}

/// Estado inmutable gestionado por [LobbyBloc].
class LobbyState extends Equatable {
  final LobbyStatus status;
  final SalaPartida? sala;
  final String? errorMessage;
  final String? infoMessage;

  const LobbyState({
    this.status = LobbyStatus.initial,
    this.sala,
    this.errorMessage,
    this.infoMessage,
  });

  bool get isLoading => status == LobbyStatus.connecting;
  bool get isInLobby => status == LobbyStatus.inLobby && sala != null;
  bool get isInGame => status == LobbyStatus.inGame && sala != null;

  LobbyState copyWith({
    LobbyStatus? status,
    SalaPartida? sala,
    bool clearSala = false,
    String? errorMessage,
    bool clearError = false,
    String? infoMessage,
    bool clearInfo = false,
  }) {
    return LobbyState(
      status: status ?? this.status,
      sala: clearSala ? null : (sala ?? this.sala),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      infoMessage: clearInfo ? null : (infoMessage ?? this.infoMessage),
    );
  }

  @override
  List<Object?> get props => [status, sala, errorMessage, infoMessage];
}
