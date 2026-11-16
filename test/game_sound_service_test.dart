import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:brilliant_game/features/auth/models/usuario.dart';
import 'package:brilliant_game/features/board/services/game_sound_service.dart';
import 'package:brilliant_game/features/board/ui/game_screen.dart';
import 'package:brilliant_game/features/lobby/models/jugador_sala.dart';
import 'package:brilliant_game/features/lobby/models/sala_partida.dart';

void main() {
  group('GameSoundService (Síntesis WAV y Control de Sonido)', () {
    test('Genera buffers WAV PCM de 16 bits válidos con encabezado RIFF/WAVE para los 4 efectos', () {
      final service = GameSoundService();

      for (final effect in GameSoundEffect.values) {
        final bytes = service.obtenerWavBytes(effect);
        expect(bytes.length, greaterThan(44));

        // Verificar cabecera ASCII 'RIFF' y 'WAVE'
        expect(ascii.decode(bytes.sublist(0, 4)), equals('RIFF'));
        expect(ascii.decode(bytes.sublist(8, 12)), equals('WAVE'));
        expect(ascii.decode(bytes.sublist(12, 16)), equals('fmt '));
        expect(ascii.decode(bytes.sublist(36, 40)), equals('data'));
      }
    });

    test('Registra efectos reproducidos cuando está activo y los omite cuando está silenciado', () async {
      final service = GameSoundService();
      expect(service.isEnabled, isTrue);

      await service.playDiceRoll();
      await service.playRegionCompleted();
      await service.playGameOver();

      expect(
        service.historialEfectos,
        equals([
          GameSoundEffect.diceRoll,
          GameSoundEffect.regionCompleted,
          GameSoundEffect.gameOver,
        ]),
      );

      // Silenciar y verificar que no reproduce nuevos efectos
      service.toggleMute();
      expect(service.isEnabled, isFalse);

      await service.playPlaceNumber();
      expect(service.historialEfectos.length, equals(3));
    });

    testWidgets('GameScreen dispara sonidos al tirar dados, colocar número y finalizar partida, y permite silenciar', (tester) async {
      tester.view.physicalSize = const Size(1440, 960);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final soundService = GameSoundService();
      const usuario = Usuario(id: 'u1', username: 'Alex');
      const jugador = JugadorSala(
        id: 'u1',
        nombre: 'Alex',
        esListo: true,
        esHost: true,
        setupListo: true,
        puntos: 15,
      );

      const salaRonda1 = SalaPartida(
        codigo: '12345',
        gameMasterId: 'u1',
        mapaSeleccionado: 1,
        jugadores: [jugador],
        estadoSala: EstadoSala.enJuego,
        rondaActual: 1,
        dadosActuales: [3, 5],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: GameScreen(
            usuario: usuario,
            sala: salaRonda1,
            onLeaveGame: () {},
            soundService: soundService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Al iniciar la Ronda 1 con dados se reproduce el sonido de tirada de dados
      expect(
        soundService.historialEfectos,
        contains(GameSoundEffect.diceRoll),
      );

      // Tocar el botón de silenciar en el AppBar
      final toggleBtn = find.byKey(const Key('game_sound_toggle_button'));
      expect(toggleBtn, findsOneWidget);
      await tester.tap(toggleBtn);
      await tester.pump();
      expect(soundService.isEnabled, isFalse);

      // Volver a activar el sonido
      await tester.tap(toggleBtn);
      await tester.pump();
      expect(soundService.isEnabled, isTrue);

      // Actualizar a partida finalizada -> debe disparar fanfarria de gameOver
      const salaFinalizada = SalaPartida(
        codigo: '12345',
        gameMasterId: 'u1',
        mapaSeleccionado: 1,
        jugadores: [
          JugadorSala(
            id: 'u1',
            nombre: 'Alex',
            esListo: true,
            esHost: true,
            setupListo: true,
            puntos: 22,
          ),
        ],
        estadoSala: EstadoSala.finalizada,
        rondaActual: 4,
        dadosActuales: [2, 6],
        ganadorId: 'u1',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: GameScreen(
            usuario: usuario,
            sala: salaFinalizada,
            onLeaveGame: () {},
            soundService: soundService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        soundService.ultimoEfectoReproducido,
        equals(GameSoundEffect.gameOver),
      );
    });
  });
}
