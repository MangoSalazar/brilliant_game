import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';
import 'package:brilliant_game/constantes.dart';
import 'package:brilliant_game/features/auth/models/usuario.dart';
import 'package:brilliant_game/features/lobby/models/sala_partida.dart';
import 'package:brilliant_game/features/lobby/repositories/lobby_repository.dart';
import 'package:brilliant_game/server/server_app.dart';
import 'package:brilliant_game/server/services/room_manager.dart';

void main() {
  group('RoomManager (Lógica de Salas en Servidor)', () {
    late RoomManager roomManager;

    setUp(() {
      roomManager = RoomManager();
    });

    test('Crea una sala con código de 5 dígitos y asigna al creador como Game Master', () {
      final sala = roomManager.crearSala(
        jugadorId: 'usr_1',
        nombreJugador: 'Mango',
      );

      expect(sala.codigo.length, equals(ConstantesJuego.longitudCodigoSala));
      expect(int.tryParse(sala.codigo), isNotNull);
      expect(sala.gameMasterId, equals('usr_1'));
      expect(sala.jugadores.length, equals(1));
      expect(sala.jugadores.first.esHost, isTrue);
      expect(sala.jugadores.first.esListo, isFalse);
      expect(sala.estadoSala, equals(EstadoSala.esperando));
    });

    test('Permite unir un segundo cliente y visualiza ambos en la sala', () {
      final salaCreada = roomManager.crearSala(
        jugadorId: 'usr_1',
        nombreJugador: 'Mango',
      );

      final salaActualizada = roomManager.unirseASala(
        codigo: salaCreada.codigo,
        jugadorId: 'usr_2',
        nombreJugador: 'Mango2',
      );

      expect(salaActualizada.jugadores.length, equals(2));
      expect(
        salaActualizada.jugadores.map((j) => j.nombre).toList(),
        equals(['Mango', 'Mango2']),
      );
    });

    test('Rechaza unirse si la sala ya tiene 6 jugadores', () {
      final sala = roomManager.crearSala(
        jugadorId: 'usr_1',
        nombreJugador: 'J1',
      );

      for (int i = 2; i <= 6; i++) {
        roomManager.unirseASala(
          codigo: sala.codigo,
          jugadorId: 'usr_$i',
          nombreJugador: 'J$i',
        );
      }

      expect(
        () => roomManager.unirseASala(
          codigo: sala.codigo,
          jugadorId: 'usr_7',
          nombreJugador: 'J7',
        ),
        throwsA(isA<RoomException>()),
      );
    });

    test('Impide iniciar partida si no todos los jugadores están listos', () {
      final sala = roomManager.crearSala(
        jugadorId: 'usr_1',
        nombreJugador: 'Mango',
      );
      roomManager.unirseASala(
        codigo: sala.codigo,
        jugadorId: 'usr_2',
        nombreJugador: 'Mango2',
      );

      // Solo usr_1 se marca listo
      roomManager.cambiarEstadoListo(
        codigo: sala.codigo,
        jugadorId: 'usr_1',
        listo: true,
      );

      expect(
        () => roomManager.iniciarPartida(
          codigo: sala.codigo,
          solicitanteId: 'usr_1',
        ),
        throwsA(isA<RoomException>()),
      );

      // usr_2 se marca listo -> ahora sí puede iniciar
      final salaLista = roomManager.cambiarEstadoListo(
        codigo: sala.codigo,
        jugadorId: 'usr_2',
        listo: true,
      );
      expect(salaLista.todosListos, isTrue);
      expect(salaLista.estadoSala, equals(EstadoSala.todosListos));

      final salaEnJuego = roomManager.iniciarPartida(
        codigo: sala.codigo,
        solicitanteId: 'usr_1',
      );
      expect(salaEnJuego.estadoSala, equals(EstadoSala.enJuego));
    });

    test('Rechaza la entrada de cualquier jugador cuando la partida ya se ha iniciado', () {
      final sala = roomManager.crearSala(
        jugadorId: 'usr_1',
        nombreJugador: 'Mango',
      );
      roomManager.cambiarEstadoListo(
        codigo: sala.codigo,
        jugadorId: 'usr_1',
        listo: true,
      );
      roomManager.iniciarPartida(
        codigo: sala.codigo,
        solicitanteId: 'usr_1',
      );

      expect(
        () => roomManager.unirseASala(
          codigo: sala.codigo,
          jugadorId: 'usr_nuevo',
          nombreJugador: 'JugadorTardio',
        ),
        throwsA(
          predicate(
            (e) =>
                e is RoomException &&
                e.message == ConstantesJuego.errorPartidaYaIniciada,
          ),
        ),
      );
    });

    test('Transfiere el rol de Game Master si el host sale de la sala', () {
      final sala = roomManager.crearSala(
        jugadorId: 'usr_1',
        nombreJugador: 'HostOriginal',
      );
      roomManager.unirseASala(
        codigo: sala.codigo,
        jugadorId: 'usr_2',
        nombreJugador: 'SegundoJugador',
      );

      final salaRestante = roomManager.removerJugador(
        codigo: sala.codigo,
        jugadorId: 'usr_1',
      );

      expect(salaRestante, isNotNull);
      expect(salaRestante!.gameMasterId, equals('usr_2'));
      expect(salaRestante.jugadores.first.esHost, isTrue);
    });

    test('Cuando un jugador abandona una partida ya empezada, no se elimina y los demás continúan jugando', () {
      final sala = roomManager.crearSala(
        jugadorId: 'usr_1',
        nombreJugador: 'HostOriginal',
      );
      roomManager.unirseASala(
        codigo: sala.codigo,
        jugadorId: 'usr_2',
        nombreJugador: 'SegundoJugador',
      );
      roomManager.cambiarEstadoListo(
        codigo: sala.codigo,
        jugadorId: 'usr_1',
        listo: true,
      );
      roomManager.cambiarEstadoListo(
        codigo: sala.codigo,
        jugadorId: 'usr_2',
        listo: true,
      );
      roomManager.iniciarPartida(
        codigo: sala.codigo,
        solicitanteId: 'usr_1',
      );

      final salaEnCurso = roomManager.removerJugador(
        codigo: sala.codigo,
        jugadorId: 'usr_1',
      );

      expect(salaEnCurso, isNotNull);
      expect(salaEnCurso!.estadoSala, equals(EstadoSala.enJuego));
      expect(salaEnCurso.jugadores.length, equals(2));
      expect(
        salaEnCurso.jugadores.firstWhere((j) => j.id == 'usr_1').abandono,
        isTrue,
      );
      expect(
        salaEnCurso.jugadores.firstWhere((j) => j.id == 'usr_2').abandono,
        isFalse,
      );
      expect(salaEnCurso.gameMasterId, equals('usr_2'));
    });
  });

  group('Integración Servidor Shelf + 2 Clientes en Tiempo Real (WebSockets)', () {
    late HttpServer server;
    late String httpBaseUrl;
    late String wsBaseUrl;

    setUp(() async {
      server = await startBrilliantServer(
        host: '127.0.0.1',
        port: 0, // Puerto efímero libre para pruebas
        enableLogging: false,
      );
      httpBaseUrl = 'http://127.0.0.1:${server.port}';
      wsBaseUrl = 'ws://127.0.0.1:${server.port}/ws';
    });

    tearDown(() async {
      await server.close(force: true);
    });

    test('Endpoints REST /api/auth/login, bloqueo de cuenta duplicada activa y /api/auth/logout funcionan correctamente', () async {
      final loginResponse = await http.post(
        Uri.parse('$httpBaseUrl/api/auth/login'),
        headers: {'content-type': 'application/json'},
        body: jsonEncode({'username': 'mango', 'password': 'mango123'}),
      );

      expect(loginResponse.statusCode, equals(200));
      final loginBody = jsonDecode(loginResponse.body) as Map<String, dynamic>;
      final token = loginBody['token'] as String;
      expect(token, isNotEmpty);
      expect(loginBody['usuario']['username'], equals('mango'));

      // Intentar iniciar sesión por segunda vez con 'mango' mientras ya está activo -> debe rechazarse (409)
      final duplicateLoginResponse = await http.post(
        Uri.parse('$httpBaseUrl/api/auth/login'),
        headers: {'content-type': 'application/json'},
        body: jsonEncode({'username': 'mango', 'password': 'mango123'}),
      );
      expect(duplicateLoginResponse.statusCode, equals(409));
      final duplicateBody =
          jsonDecode(duplicateLoginResponse.body) as Map<String, dynamic>;
      expect(
        duplicateBody['error'],
        equals(ConstantesJuego.errorSesionYaActiva),
      );

      // Cerrar sesión de 'mango' -> libera la cuenta y permite volver a entrar
      final logoutResponse = await http.post(
        Uri.parse('$httpBaseUrl/api/auth/logout'),
        headers: {
          'content-type': 'application/json',
          'authorization': 'Bearer $token',
        },
        body: jsonEncode({'username': 'mango'}),
      );
      expect(logoutResponse.statusCode, equals(200));

      final reloginResponse = await http.post(
        Uri.parse('$httpBaseUrl/api/auth/login'),
        headers: {'content-type': 'application/json'},
        body: jsonEncode({'username': 'mango', 'password': 'mango123'}),
      );
      expect(reloginResponse.statusCode, equals(200));

      final registerResponse = await http.post(
        Uri.parse('$httpBaseUrl/api/auth/register'),
        headers: {'content-type': 'application/json'},
        body: jsonEncode({'username': 'nuevo_user', 'password': 'Password123'}),
      );
      expect(registerResponse.statusCode, equals(201));
    });

    test('2 clientes se conectan por WebSocket a la misma sala y se visualizan mutuamente', () async {
      final client1 = WebSocketLobbyRepository(wsBaseUrl: wsBaseUrl);
      final client2 = WebSocketLobbyRepository(wsBaseUrl: wsBaseUrl);

      const user1 = Usuario(id: 'usr_mango1', username: 'Mango1');
      const user2 = Usuario(id: 'usr_mango2', username: 'Mango2');

      final client1Events = <LobbyServerEvent>[];
      final client2Events = <LobbyServerEvent>[];

      final sub1 = client1.events.listen(client1Events.add);
      final sub2 = client2.events.listen(client2Events.add);

      // 1. Cliente 1 conecta y crea sala
      await client1.connect(usuario: user1);
      final createdCompleter = Completer<SalaPartida>();
      late StreamSubscription<LobbyServerEvent> tempSub1;
      tempSub1 = client1.events.listen((event) {
        if (event is LobbyRoomSynced && !createdCompleter.isCompleted) {
          createdCompleter.complete(event.sala);
        }
      });

      client1.createRoom();
      final salaCreada = await createdCompleter.future.timeout(
        const Duration(seconds: 5),
      );
      await tempSub1.cancel();

      expect(salaCreada.codigo.length, equals(5));
      expect(salaCreada.jugadores.length, equals(1));
      expect(salaCreada.jugadores.first.nombre, equals('Mango1'));

      // 2. Cliente 2 conecta y se une usando el código de 5 dígitos de Cliente 1
      await client2.connect(usuario: user2);

      final client1SeesTwoPlayers = Completer<SalaPartida>();
      final client2SeesTwoPlayers = Completer<SalaPartida>();

      final waitSub1 = client1.events.listen((event) {
        if (event is LobbyRoomSynced &&
            event.sala.jugadores.length == 2 &&
            !client1SeesTwoPlayers.isCompleted) {
          client1SeesTwoPlayers.complete(event.sala);
        }
      });

      final waitSub2 = client2.events.listen((event) {
        if (event is LobbyRoomSynced &&
            event.sala.jugadores.length == 2 &&
            !client2SeesTwoPlayers.isCompleted) {
          client2SeesTwoPlayers.complete(event.sala);
        }
      });

      client2.joinRoom(salaCreada.codigo);

      final salaVistaPorCliente1 = await client1SeesTwoPlayers.future.timeout(
        const Duration(seconds: 5),
      );
      final salaVistaPorCliente2 = await client2SeesTwoPlayers.future.timeout(
        const Duration(seconds: 5),
      );

      await waitSub1.cancel();
      await waitSub2.cancel();

      // Ambos clientes ven exactamente la misma sala con los 2 jugadores
      expect(
        salaVistaPorCliente1.jugadores.map((j) => j.nombre).toList(),
        equals(['Mango1', 'Mango2']),
      );
      expect(
        salaVistaPorCliente2.jugadores.map((j) => j.nombre).toList(),
        equals(['Mango1', 'Mango2']),
      );

      // 3. Ambos clientes se marcan como Listo y el Game Master inicia la partida
      final gameStartedCompleter = Completer<SalaPartida>();
      final startSub = client2.events.listen((event) {
        if (event is LobbyGameStarted && !gameStartedCompleter.isCompleted) {
          gameStartedCompleter.complete(event.sala);
        }
      });

      client1.toggleReady(ready: true);
      client2.toggleReady(ready: true);

      // Esperar breve sincronización de estados listos
      await Future.delayed(const Duration(milliseconds: 150));
      client1.startGame();

      final salaIniciada = await gameStartedCompleter.future.timeout(
        const Duration(seconds: 5),
      );
      expect(salaIniciada.estadoSala, equals(EstadoSala.enJuego));

      await startSub.cancel();
      await sub1.cancel();
      await sub2.cancel();
      await client1.disconnect();
      await client2.disconnect();
    });

    test(
      'Permite alternar Listo / No Listo repetidamente y transfiere Game Master con notificación al desconectarse el host',
      () async {
        final client1 = WebSocketLobbyRepository(wsBaseUrl: wsBaseUrl);
        final client2 = WebSocketLobbyRepository(wsBaseUrl: wsBaseUrl);

        const user1 = Usuario(id: 'usr_host', username: 'HostMango');
        const user2 = Usuario(id: 'usr_guest', username: 'Invitado2');

        await client1.connect(usuario: user1);
        final roomCreated = Completer<SalaPartida>();
        final createSub = client1.events.listen((e) {
          if (e is LobbyRoomSynced && !roomCreated.isCompleted) {
            roomCreated.complete(e.sala);
          }
        });
        client1.createRoom();
        final salaInicial =
            await roomCreated.future.timeout(const Duration(seconds: 5));
        await createSub.cancel();

        await client2.connect(usuario: user2);
        final joinedCompleter = Completer<SalaPartida>();
        final joinSub = client2.events.listen((e) {
          if (e is LobbyRoomSynced &&
              e.sala.jugadores.length == 2 &&
              !joinedCompleter.isCompleted) {
            joinedCompleter.complete(e.sala);
          }
        });
        client2.joinRoom(salaInicial.codigo);
        await joinedCompleter.future.timeout(const Duration(seconds: 5));
        await joinSub.cancel();

        // 1. Invitado2 se marca como Listo y luego cancela su estado Listo
        final readyTrueCompleter = Completer<SalaPartida>();
        final readySub1 = client2.events.listen((e) {
          if (e is LobbyRoomSynced) {
            final guest =
                e.sala.jugadores.firstWhere((j) => j.id == 'usr_guest');
            if (guest.esListo && !readyTrueCompleter.isCompleted) {
              readyTrueCompleter.complete(e.sala);
            }
          }
        });
        client2.toggleReady(ready: true);
        await readyTrueCompleter.future.timeout(const Duration(seconds: 5));
        await readySub1.cancel();

        final readyFalseCompleter = Completer<SalaPartida>();
        final readySub2 = client2.events.listen((e) {
          if (e is LobbyRoomSynced) {
            final guest =
                e.sala.jugadores.firstWhere((j) => j.id == 'usr_guest');
            if (!guest.esListo && !readyFalseCompleter.isCompleted) {
              readyFalseCompleter.complete(e.sala);
            }
          }
        });
        client2.toggleReady(ready: false);
        final salaDesmarcada =
            await readyFalseCompleter.future.timeout(const Duration(seconds: 5));
        await readySub2.cancel();
        expect(
          salaDesmarcada.jugadores
              .firstWhere((j) => j.id == 'usr_guest')
              .esListo,
          isFalse,
        );

        // 2. HostMango pierde la conexión -> Invitado2 recibe la sala actualizada siendo el nuevo Game Master y el mensaje de notificación
        final hostTransferredCompleter = Completer<LobbyRoomSynced>();
        final transferSub = client2.events.listen((e) {
          if (e is LobbyRoomSynced &&
              e.sala.gameMasterId == 'usr_guest' &&
              !hostTransferredCompleter.isCompleted) {
            hostTransferredCompleter.complete(e);
          }
        });

        await client1.disconnect();

        final syncEvent = await hostTransferredCompleter.future.timeout(
          const Duration(seconds: 5),
        );
        await transferSub.cancel();

        expect(syncEvent.sala.jugadores.length, equals(1));
        expect(syncEvent.sala.gameMasterId, equals('usr_guest'));
        expect(syncEvent.sala.jugadores.first.esHost, isTrue);
        expect(syncEvent.notificacion, isNotNull);
        expect(syncEvent.notificacion, contains('Invitado2'));
        expect(syncEvent.notificacion, contains('Game Master'));

        await client2.disconnect();
      },
    );
  });
}
