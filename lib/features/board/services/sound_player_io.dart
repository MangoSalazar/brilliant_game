import 'dart:io';
import 'package:flutter/services.dart';

/// Reproduce el efecto de sonido en plataformas nativas (Android, iOS, Windows).
/// En entorno de pruebas (`FLUTTER_TEST`) omite la salida de audio del sistema.
Future<void> playWavBytesPlatform(Uint8List wavBytes) async {
  try {
    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      return;
    }
    await SystemSound.play(SystemSoundType.click);
  } catch (_) {
    // Ignorar errores de canal en entornos sin motor de audio nativo
  }
}
