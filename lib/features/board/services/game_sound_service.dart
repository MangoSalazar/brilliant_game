import 'dart:math';
import 'dart:typed_data';

import 'sound_player_stub.dart'
    if (dart.library.js_interop) 'sound_player_web.dart'
    if (dart.library.io) 'sound_player_io.dart';

/// Tipos de efectos de sonido disponibles durante una partida de Brilliant Game.
enum GameSoundEffect {
  /// Sonido al lanzar los 2 dados globales al inicio de una ronda.
  diceRoll,

  /// Sonido corto al colocar un número en una casilla del tablero.
  placeNumber,

  /// Acorde ascendente al llenar por completo el 100% de una región.
  regionCompleted,

  /// Fanfarria triunfal al declararse el ganador de la partida.
  gameOver,
}

/// Nota musical o pulso sintetizado para construir un efecto `.wav` en memoria.
class _ToneSegment {
  final double frequencyHz;
  final int durationMs;
  final double volume;
  final double noiseMix;

  const _ToneSegment({
    required this.frequencyHz,
    required this.durationMs,
    this.volume = 0.65,
    this.noiseMix = 0.0,
  });
}

/// Servicio encargado de sintetizar y reproducir efectos de sonido sencillos
/// en formato `.wav` PCM de 16 bits en memoria (SRP).
class GameSoundService {
  static final GameSoundService instance = GameSoundService();

  bool _enabled;
  final Map<GameSoundEffect, Uint8List> _wavCache = {};
  final List<GameSoundEffect> _historialEfectos = [];

  GameSoundService({bool enabled = true}) : _enabled = enabled;

  /// Indica si los efectos de sonido están activos o silenciados.
  bool get isEnabled => _enabled;

  /// Historial de efectos reproducidos (útil para verificación en pruebas).
  List<GameSoundEffect> get historialEfectos =>
      List.unmodifiable(_historialEfectos);

  /// Último efecto reproducido o `null` si no se ha emitido ninguno.
  GameSoundEffect? get ultimoEfectoReproducido =>
      _historialEfectos.isEmpty ? null : _historialEfectos.last;

  /// Activa o desactiva la reproducción de sonidos.
  void setEnabled(bool value) {
    _enabled = value;
  }

  /// Alterna entre sonido activo y silenciado.
  bool toggleMute() {
    _enabled = !_enabled;
    return _enabled;
  }

  /// Limpia el registro histórico de sonidos reproducidos.
  void limpiarHistorial() {
    _historialEfectos.clear();
  }

  /// Reproduce el efecto de tirada de dados (`diceRoll`).
  Future<void> playDiceRoll() => play(GameSoundEffect.diceRoll);

  /// Reproduce el efecto de colocación de número en casilla (`placeNumber`).
  Future<void> playPlaceNumber() => play(GameSoundEffect.placeNumber);

  /// Reproduce el acorde de región completada (`regionCompleted`).
  Future<void> playRegionCompleted() => play(GameSoundEffect.regionCompleted);

  /// Reproduce la fanfarria de fin de partida (`gameOver`).
  Future<void> playGameOver() => play(GameSoundEffect.gameOver);

  /// Reproduce el [effect] indicado si el sonido está habilitado.
  Future<void> play(GameSoundEffect effect) async {
    if (!_enabled) return;
    _historialEfectos.add(effect);
    final wavBytes = obtenerWavBytes(effect);
    await playWavBytesPlatform(wavBytes);
  }

  /// Obtiene (o genera y almacena en caché) los bytes `.wav` PCM de 16 bits para [effect].
  Uint8List obtenerWavBytes(GameSoundEffect effect) {
    return _wavCache.putIfAbsent(effect, () => _sintetizarEfecto(effect));
  }

  Uint8List _sintetizarEfecto(GameSoundEffect effect) {
    switch (effect) {
      case GameSoundEffect.diceRoll:
        // Repique rápido de dados (4 toques percusivos + tono corto de asentamiento)
        return _generarWavDesdeSegmentos(const [
          _ToneSegment(
            frequencyHz: 310,
            durationMs: 42,
            volume: 0.70,
            noiseMix: 0.45,
          ),
          _ToneSegment(frequencyHz: 0, durationMs: 18, volume: 0),
          _ToneSegment(
            frequencyHz: 420,
            durationMs: 42,
            volume: 0.72,
            noiseMix: 0.40,
          ),
          _ToneSegment(frequencyHz: 0, durationMs: 16, volume: 0),
          _ToneSegment(
            frequencyHz: 370,
            durationMs: 45,
            volume: 0.75,
            noiseMix: 0.35,
          ),
          _ToneSegment(frequencyHz: 0, durationMs: 18, volume: 0),
          _ToneSegment(
            frequencyHz: 587.33, // D5
            durationMs: 95,
            volume: 0.68,
            noiseMix: 0.12,
          ),
        ]);

      case GameSoundEffect.placeNumber:
        // "Pop" corto y limpio al asentar un número en el tablero
        return _generarWavDesdeSegmentos(const [
          _ToneSegment(frequencyHz: 440.0, durationMs: 40, volume: 0.55),
          _ToneSegment(frequencyHz: 659.25, durationMs: 65, volume: 0.62),
        ]);

      case GameSoundEffect.regionCompleted:
        // Arpegio mayor ascendente alegre (Do5 - Mi5 - Sol5 - Do6) al completar una zona
        return _generarWavDesdeSegmentos(const [
          _ToneSegment(frequencyHz: 523.25, durationMs: 75, volume: 0.68), // C5
          _ToneSegment(frequencyHz: 659.25, durationMs: 75, volume: 0.72), // E5
          _ToneSegment(frequencyHz: 783.99, durationMs: 85, volume: 0.76), // G5
          _ToneSegment(
            frequencyHz: 1046.50,
            durationMs: 190,
            volume: 0.82,
          ), // C6
        ]);

      case GameSoundEffect.gameOver:
        // Fanfarria triunfal de victoria
        return _generarWavDesdeSegmentos(const [
          _ToneSegment(frequencyHz: 523.25, durationMs: 95, volume: 0.75), // C5
          _ToneSegment(frequencyHz: 659.25, durationMs: 95, volume: 0.75), // E5
          _ToneSegment(frequencyHz: 783.99, durationMs: 95, volume: 0.78), // G5
          _ToneSegment(frequencyHz: 0, durationMs: 30, volume: 0),
          _ToneSegment(frequencyHz: 783.99, durationMs: 90, volume: 0.78), // G5
          _ToneSegment(
            frequencyHz: 1046.50,
            durationMs: 320,
            volume: 0.88,
          ), // C6
        ]);
    }
  }

  /// Construye un archivo `.wav` RIFF/PCM mono de 16 bits a 22050 Hz en memoria.
  Uint8List _generarWavDesdeSegmentos(List<_ToneSegment> segmentos) {
    const int sampleRate = 22050;
    final int totalDurationMs = segmentos.fold(
      0,
      (sum, seg) => sum + seg.durationMs,
    );
    final int numSamples = ((sampleRate * totalDurationMs) / 1000).round();
    final int dataByteCount = numSamples * 2; // 16-bit mono = 2 bytes por muestra
    final ByteData buffer = ByteData(44 + dataByteCount);

    // Encabezado RIFF / WAVE estándar (44 bytes)
    _writeAscii(buffer, 0, 'RIFF');
    buffer.setUint32(4, 36 + dataByteCount, Endian.little);
    _writeAscii(buffer, 8, 'WAVE');
    _writeAscii(buffer, 12, 'fmt ');
    buffer.setUint32(16, 16, Endian.little); // Subchunk1Size (16 para PCM)
    buffer.setUint16(20, 1, Endian.little); // AudioFormat (1 = PCM)
    buffer.setUint16(22, 1, Endian.little); // NumChannels (1 = Mono)
    buffer.setUint32(24, sampleRate, Endian.little); // SampleRate
    buffer.setUint32(28, sampleRate * 2, Endian.little); // ByteRate
    buffer.setUint16(32, 2, Endian.little); // BlockAlign
    buffer.setUint16(34, 16, Endian.little); // BitsPerSample (16 bits)
    _writeAscii(buffer, 36, 'data');
    buffer.setUint32(40, dataByteCount, Endian.little);

    final random = Random(42);
    int sampleOffset = 0;

    for (final seg in segmentos) {
      final int segSamples = ((sampleRate * seg.durationMs) / 1000).round();
      for (int i = 0; i < segSamples && sampleOffset < numSamples; i++) {
        double sampleValue = 0.0;
        if (seg.frequencyHz > 0 && seg.volume > 0) {
          final double t = i / sampleRate;
          // Onda fundamental + segundo armónico suave para timbre cálido
          final double fundamental = sin(2 * pi * seg.frequencyHz * t);
          final double arm2 = 0.25 * sin(4 * pi * seg.frequencyHz * t);
          double wave = (fundamental + arm2) / 1.25;

          if (seg.noiseMix > 0) {
            final double noise = (random.nextDouble() * 2.0) - 1.0;
            wave = (wave * (1.0 - seg.noiseMix)) + (noise * seg.noiseMix);
          }

          // Envolvente de ataque rápido y decaimiento exponencial suave (evita clics)
          final double progress = i / segSamples;
          final double attack = (i < 60) ? (i / 60.0) : 1.0;
          final double decay = exp(-2.6 * progress);
          sampleValue = wave * seg.volume * attack * decay;
        }

        final int pcm16 = (sampleValue.clamp(-1.0, 1.0) * 32767).round();
        buffer.setInt16(44 + (sampleOffset * 2), pcm16, Endian.little);
        sampleOffset++;
      }
    }

    return buffer.buffer.asUint8List();
  }

  void _writeAscii(ByteData data, int offset, String text) {
    for (int i = 0; i < text.length; i++) {
      data.setUint8(offset + i, text.codeUnitAt(i));
    }
  }
}
