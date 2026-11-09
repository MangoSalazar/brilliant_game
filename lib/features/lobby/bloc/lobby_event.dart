import 'package:equatable/equatable.dart';
import '../../auth/models/usuario.dart';
import '../repositories/lobby_repository.dart';

/// Eventos despachados hacia el [LobbyBloc].
sealed class LobbyEvent extends Equatable {
  const LobbyEvent();

  @override
  List<Object?> get props => [];
}

/// Solicita crear una nueva sala en el servidor como Game Master.
class LobbyCreateRoomRequested extends LobbyEvent {
  final Usuario usuario;
  final String? token;

  const LobbyCreateRoomRequested({
    required this.usuario,
    this.token,
  });

  @override
  List<Object?> get props => [usuario, token];
}

/// Solicita unirse a una sala existente con el código de 5 dígitos.
class LobbyJoinRoomRequested extends LobbyEvent {
  final Usuario usuario;
  final String codigoSala;
  final String? token;

  const LobbyJoinRoomRequested({
    required this.usuario,
    required this.codigoSala,
    this.token,
  });

  @override
  List<Object?> get props => [usuario, codigoSala, token];
}

/// Solicita alternar el estado "Listo" del jugador actual.
class LobbyToggleReadyRequested extends LobbyEvent {
  final bool? ready;
  const LobbyToggleReadyRequested({this.ready});

  @override
  List<Object?> get props => [ready];
}

/// Solicita cambiar el mapa seleccionado (1 al 4, exclusivo del Game Master).
class LobbySelectMapRequested extends LobbyEvent {
  final int mapaId;
  const LobbySelectMapRequested(this.mapaId);

  @override
  List<Object?> get props => [mapaId];
}

/// Solicita expulsar a un jugador de la sala (exclusivo del Game Master).
class LobbyKickPlayerRequested extends LobbyEvent {
  final String targetPlayerId;
  const LobbyKickPlayerRequested(this.targetPlayerId);

  @override
  List<Object?> get props => [targetPlayerId];
}

/// Solicita iniciar la partida (exclusivo del Game Master cuando todos están listos).
class LobbyStartGameRequested extends LobbyEvent {
  const LobbyStartGameRequested();
}

/// Solicita abandonar la sala actual y volver al menú principal.
class LobbyLeaveRoomRequested extends LobbyEvent {
  const LobbyLeaveRoomRequested();
}

/// Limpia los mensajes de error activos en el estado del Lobby.
class LobbyClearErrorRequested extends LobbyEvent {
  const LobbyClearErrorRequested();
}

/// Limpia los mensajes informativos activos en el estado del Lobby.
class LobbyClearInfoRequested extends LobbyEvent {
  const LobbyClearInfoRequested();
}

/// Evento interno disparado cuando el repositorio recibe una notificación del servidor.
class LobbyServerEventReceived extends LobbyEvent {
  final LobbyServerEvent serverEvent;
  const LobbyServerEventReceived(this.serverEvent);

  @override
  List<Object?> get props => [serverEvent];
}
