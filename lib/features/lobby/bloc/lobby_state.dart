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

  const LobbyState({
    this.status = LobbyStatus.initial,
    this.sala,
    this.errorMessage,
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
  }) {
    return LobbyState(
      status: status ?? this.status,
      sala: clearSala ? null : (sala ?? this.sala),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [status, sala, errorMessage];
}
