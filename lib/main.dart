import 'tablero.dart';
import 'region.dart';

void main() {
  // Punto de entrada sin dependencias de interfaz gráfica (UI).
  // Inicialización y verificación de la lógica interna del juego.
  final tablero = Tablero(ancho: 7, alto: 7);
  print('Brilliant Game - Lógica interna inicializada.');
  print('Tablero base configurado: ${tablero.ancho}x${tablero.alto}');
}
