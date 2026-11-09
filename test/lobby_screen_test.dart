import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:brilliant_game/features/auth/bloc/auth_bloc.dart';
import 'package:brilliant_game/features/auth/models/usuario.dart';
import 'package:brilliant_game/features/auth/repositories/auth_repository.dart';
import 'package:brilliant_game/features/home/ui/wip_screen.dart';
import 'package:brilliant_game/features/lobby/bloc/lobby_bloc.dart';
import 'package:brilliant_game/features/lobby/bloc/lobby_event.dart';
import 'package:brilliant_game/features/lobby/models/jugador_sala.dart';
import 'package:brilliant_game/features/lobby/models/sala_partida.dart';
import 'package:brilliant_game/features/lobby/repositories/lobby_repository.dart';
import 'package:brilliant_game/features/lobby/ui/lobby_screen.dart';

class _FakeLobbyRepository implements LobbyRepository {
  final StreamController<LobbyServerEvent> controller =
      StreamController<LobbyServerEvent>.broadcast();

  SalaPartida currentSala = const SalaPartida(
    codigo: '58129',
    gameMasterId: 'usr_1',
    mapaSeleccionado: 1,
    jugadores: [
      JugadorSala(
        id: 'usr_1',
        nombre: 'Mango1',
        esHost: true,
        esListo: false,
      ),
      JugadorSala(
        id: 'usr_2',
        nombre: 'Mango2',
        esHost: false,
        esListo: true,
      ),
    ],
  );

  @override
  Stream<LobbyServerEvent> get events => controller.stream;

  @override
  Future<void> connect({required Usuario usuario, String? token}) async {}

  @override
  void createRoom() {
    controller.add(LobbyRoomSynced(currentSala));
  }

  @override
  void joinRoom(String roomCode) {
    controller.add(LobbyRoomSynced(currentSala));
  }

  @override
  void toggleReady({bool? ready, String? roomCode}) {
    final updatedPlayers = currentSala.jugadores.map((j) {
      if (j.id == 'usr_1') {
        return j.copyWith(esListo: ready ?? !j.esListo);
      }
      return j;
    }).toList();
    final allReady = updatedPlayers.every((j) => j.esListo);
    currentSala = currentSala.copyWith(
      jugadores: updatedPlayers,
      estadoSala: allReady ? EstadoSala.todosListos : EstadoSala.esperando,
    );
    controller.add(LobbyRoomSynced(currentSala));
  }

  @override
  void selectMap(int mapId) {
    currentSala = currentSala.copyWith(mapaSeleccionado: mapId);
    controller.add(LobbyRoomSynced(currentSala));
  }

  @override
  void kickPlayer(String targetPlayerId) {
    final remaining = currentSala.jugadores
        .where((j) => j.id != targetPlayerId)
        .toList();
    currentSala = currentSala.copyWith(jugadores: remaining);
    controller.add(LobbyRoomSynced(currentSala));
  }

  @override
  void startGame() {
    currentSala = currentSala.copyWith(estadoSala: EstadoSala.enJuego);
    controller.add(LobbyGameStarted(currentSala));
  }

  @override
  void leaveRoom() {}

  @override
  Future<void> disconnect() async {}
}

void main() {
  const hostUser = Usuario(id: 'usr_1', username: 'Mango1');

  group('LobbyScreen (Sala de Espera en Tiempo Real)', () {
    testWidgets(
      'Visualiza código de 5 dígitos, los 2 clientes conectados e ilumina en verde al jugador Listo',
      (tester) async {
        final fakeRepo = _FakeLobbyRepository();

        await tester.pumpWidget(
          MultiBlocProvider(
            providers: [
              BlocProvider<AuthBloc>(
                create: (_) => AuthBloc(
                  authRepository:
                      LocalAuthRepository(simulatedDelay: Duration.zero),
                ),
              ),
              BlocProvider<LobbyBloc>(
                create: (_) => LobbyBloc(lobbyRepository: fakeRepo)
                  ..add(const LobbyCreateRoomRequested(usuario: hostUser)),
              ),
            ],
            child: const MaterialApp(
              home: LobbyScreen(usuarioActual: hostUser),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Código de sala de 5 dígitos visible
        expect(find.text('58129'), findsOneWidget);
        expect(find.text('2 / 6 Jugadores'), findsOneWidget);

        // Ambos jugadores conectados aparecen en la lista
        expect(find.text('Mango1'), findsOneWidget);
        expect(find.text('Mango2'), findsOneWidget);

        // Mango2 está marcado como listo -> su nombre se ilumina en color verde (#10B981)
        final mango2Text = tester.widget<Text>(
          find.byKey(const Key('player_name_usr_2')),
        );
        expect(mango2Text.style?.color, equals(const Color(0xFF10B981)));

        // Mango1 aún no está listo -> el botón de Iniciar Partida está deshabilitado
        final startButtonFinder = find.byKey(const Key('lobby_start_game_button'));
        final startButtonBefore =
            tester.widget<ElevatedButton>(startButtonFinder);
        expect(startButtonBefore.onPressed, isNull);

        // Mango1 pulsa "Marcarme como Listo"
        final toggleReadyFinder =
            find.byKey(const Key('lobby_toggle_ready_button'));
        await tester.ensureVisible(toggleReadyFinder);
        await tester.pumpAndSettle();
        await tester.tap(toggleReadyFinder);
        await tester.pumpAndSettle();

        // Ahora ambos están en verde y el botón Iniciar Partida se habilita
        final mango1TextAfter = tester.widget<Text>(
          find.byKey(const Key('player_name_usr_1')),
        );
        expect(mango1TextAfter.style?.color, equals(const Color(0xFF10B981)));

        final startButtonAfter =
            tester.widget<ElevatedButton>(startButtonFinder);
        expect(startButtonAfter.onPressed, isNotNull);

        // Al iniciar partida, navega a la vista de partida WIP
        await tester.ensureVisible(startButtonFinder);
        await tester.pumpAndSettle();
        await tester.tap(startButtonFinder);
        await tester.pumpAndSettle();

        expect(find.byType(WipScreen), findsOneWidget);
        expect(find.textContaining('Sala #58129'), findsOneWidget);
      },
    );

    testWidgets(
      'Permite alternar libremente entre "Marcarme como Listo" y "Cancelar Listo" sin desmarcar al cambiar mapa',
      (tester) async {
        final fakeRepo = _FakeLobbyRepository();

        await tester.pumpWidget(
          MultiBlocProvider(
            providers: [
              BlocProvider<AuthBloc>(
                create: (_) => AuthBloc(
                  authRepository:
                      LocalAuthRepository(simulatedDelay: Duration.zero),
                ),
              ),
              BlocProvider<LobbyBloc>(
                create: (_) => LobbyBloc(lobbyRepository: fakeRepo)
                  ..add(const LobbyCreateRoomRequested(usuario: hostUser)),
              ),
            ],
            child: const MaterialApp(
              home: LobbyScreen(usuarioActual: hostUser),
            ),
          ),
        );

        await tester.pumpAndSettle();

        final toggleReadyFinder =
            find.byKey(const Key('lobby_toggle_ready_button'));
        expect(find.text('MARCARME COMO LISTO'), findsOneWidget);

        // 1. Marcarse como Listo
        await tester.ensureVisible(toggleReadyFinder);
        await tester.pumpAndSettle();
        await tester.tap(toggleReadyFinder);
        await tester.pumpAndSettle();

        expect(find.text('CANCELAR LISTO'), findsOneWidget);
        final mango1ReadyText = tester.widget<Text>(
          find.byKey(const Key('player_name_usr_1')),
        );
        expect(mango1ReadyText.style?.color, equals(const Color(0xFF10B981)));

        // 2. Cambiar de mapa no desmarca el estado Listo
        final map2Finder = find.byKey(const Key('lobby_map_option_2'));
        await tester.ensureVisible(map2Finder);
        await tester.pumpAndSettle();
        await tester.tap(map2Finder);
        await tester.pumpAndSettle();

        expect(find.text('CANCELAR LISTO'), findsOneWidget);

        // 3. Volver a pulsar el botón para Cancelar Listo
        await tester.ensureVisible(toggleReadyFinder);
        await tester.pumpAndSettle();
        await tester.tap(toggleReadyFinder);
        await tester.pumpAndSettle();

        expect(find.text('MARCARME COMO LISTO'), findsOneWidget);
        final mango1UnreadyText = tester.widget<Text>(
          find.byKey(const Key('player_name_usr_1')),
        );
        expect(mango1UnreadyText.style?.color, equals(Colors.white));
      },
    );

    testWidgets(
      'Solicita confirmación antes de salir indicando transferencia de Game Master al jugador más antiguo',
      (tester) async {
        final fakeRepo = _FakeLobbyRepository();

        await tester.pumpWidget(
          MultiBlocProvider(
            providers: [
              BlocProvider<AuthBloc>(
                create: (_) => AuthBloc(
                  authRepository:
                      LocalAuthRepository(simulatedDelay: Duration.zero),
                ),
              ),
              BlocProvider<LobbyBloc>(
                create: (_) => LobbyBloc(lobbyRepository: fakeRepo)
                  ..add(const LobbyCreateRoomRequested(usuario: hostUser)),
              ),
            ],
            child: const MaterialApp(
              home: LobbyScreen(usuarioActual: hostUser),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Pulsar botón de salir en el AppBar
        await tester.tap(find.byKey(const Key('lobby_leave_button')));
        await tester.pumpAndSettle();

        // Se muestra el diálogo advirtiendo que Mango2 será el nuevo Game Master
        expect(find.text('¿Abandonar la sala?'), findsOneWidget);
        expect(
          find.textContaining('transferirá automáticamente a Mango2'),
          findsOneWidget,
        );

        // Si pulsa "Permanecer", sigue en la sala
        await tester.tap(find.byKey(const Key('cancel_leave_room_button')));
        await tester.pumpAndSettle();
        expect(find.text('58129'), findsOneWidget);
      },
    );
  });
}
