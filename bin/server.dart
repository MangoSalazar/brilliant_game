import 'dart:io';
import 'package:brilliant_game/constantes.dart';
import 'package:brilliant_game/server/server_app.dart';

Future<void> main(List<String> args) async {
  final portEnv = Platform.environment['PORT'];
  final port = portEnv != null
      ? (int.tryParse(portEnv) ?? ConstantesJuego.puertoServidorPorDefecto)
      : ConstantesJuego.puertoServidorPorDefecto;

  final server = await startBrilliantServer(
    host: '0.0.0.0',
    port: port,
    enableLogging: true,
  );

  stdout.writeln('==========================================================');
  stdout.writeln(' 🎲 BRILLIANT GAME - SERVIDOR SHELF EN LÍNEA');
  stdout.writeln('==========================================================');
  stdout.writeln(' 🌐 HTTP REST API : http://localhost:${server.port}/api');
  stdout.writeln(' ⚡ WebSocket URL : ws://localhost:${server.port}/ws');
  stdout.writeln(' 🔑 Usuarios precargados para pruebas:');
  stdout.writeln('    - mango / mango123');
  stdout.writeln('    - mango2 / mango123');
  stdout.writeln('    - jugador1 / Password123');
  stdout.writeln('    - jugador2 / Password123');
  stdout.writeln('==========================================================');
}
