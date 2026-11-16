import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';

@JS('Audio')
extension type _HtmlAudioElement._(JSObject _) implements JSObject {
  external factory _HtmlAudioElement(JSString src);
  external set volume(JSNumber value);
  external JSPromise<JSAny?> play();
}

/// Reproduce un buffer WAV en memoria directamente en Flutter Web (Chrome/Edge)
/// usando el elemento nativo `Audio` de HTML5 mediante `dart:js_interop`.
Future<void> playWavBytesPlatform(Uint8List wavBytes) async {
  try {
    final base64Wav = base64Encode(wavBytes);
    final dataUri = 'data:audio/wav;base64,$base64Wav';
    final audio = _HtmlAudioElement(dataUri.toJS);
    audio.volume = 0.75.toJS;
    await audio.play().toDart;
  } catch (_) {
    // Ignorar silenciosamente si el navegador bloquea autoplay antes de interacción
  }
}
