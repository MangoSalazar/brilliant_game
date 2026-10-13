import 'package:flutter/material.dart';

/// Botón interactivo para iniciar la partida una vez completada la preparación (Story 4.2).
/// Permanece deshabilitado o muestra el progreso mientras no se hayan completado
/// los 6 números iniciales, y se activa con confirmación visual cuando el estado es válido.
class StartGameButton extends StatelessWidget {
  final bool isReady;
  final int numbersPlaced;
  final VoidCallback? onStartPressed;

  const StartGameButton({
    super.key,
    required this.isReady,
    required this.numbersPlaced,
    this.onStartPressed,
  });

  @override
  Widget build(BuildContext context) {
    if (!isReady) {
      return OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          foregroundColor: Colors.grey.shade600,
          side: BorderSide(color: Colors.grey.shade400),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
        onPressed: null, // Deshabilitado durante la preparación
        icon: const Icon(Icons.lock_outline, size: 20),
        label: Text(
          'Comenzar Partida ($numbersPlaced/6 colocados)',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      );
    }

    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        backgroundColor: Colors.green.shade600,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
      onPressed: onStartPressed ??
          () {
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Row(
                  children: [
                    Icon(Icons.sports_esports, color: Colors.green),
                    SizedBox(width: 8),
                    Text('¡Partida Lista!'),
                  ],
                ),
                content: const Text(
                  'Todos los 6 números iniciales han sido colocados y validados correctamente. El tablero está preparado para comenzar la partida.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('Aceptar'),
                  ),
                ],
              ),
            );
          },
      icon: const Icon(Icons.play_arrow_rounded, size: 28),
      label: const Text(
        'Comenzar Partida',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }
}
