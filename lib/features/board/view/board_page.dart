import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/setup_bloc.dart';
import '../widgets/board_grid.dart';
import '../widgets/start_game_button.dart';
import '../../../tablero.dart';

/// Pantalla principal para la visualización del tablero y la fase de preparación
/// de partida (Épica 3 y Épica 4).
class BoardPage extends StatelessWidget {
  const BoardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Brilliant Game - Preparación'),
        backgroundColor: Colors.blueGrey.shade800,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: BlocBuilder<SetupBloc, SetupState>(
        builder: (context, state) {
          if (state is SetupInitial) {
            return const Center(child: CircularProgressIndicator());
          }

          final Tablero tablero;
          final List<Casilla> requeridas;
          final Map<Casilla, int> ingresados;
          final bool isReady = state is SetupCompleted;

          if (state is SetupAwaitingInputs) {
            tablero = state.tablero;
            requeridas = state.casillasRequeridas;
            ingresados = state.valoresIngresados;
          } else if (state is SetupCompleted) {
            tablero = state.tablero;
            requeridas = state.tablero.celdas
                .expand((row) => row)
                .where((c) => c.valor != null)
                .toList();
            ingresados = {for (var c in requeridas) c: c.valor!};
          } else {
            return const SizedBox();
          }

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  const SizedBox(height: 16),

                  // Mensaje / Feedback de Error
                  if (state is SetupAwaitingInputs && state.errorMessage != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.red.shade300),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red.shade700),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              state.errorMessage!,
                              style: TextStyle(
                                color: Colors.red.shade900,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Mensaje de Éxito
                  if (isReady)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.green.shade400),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle_outline, color: Colors.green.shade800),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '¡Los 6 números iniciales han sido colocados exitosamente!',
                              style: TextStyle(
                                color: Colors.green.shade900,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Encabezado con instrucciones
                  Text(
                    isReady ? 'Tablero Listo' : 'Coloca los 6 números iniciales (1 al 6)',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isReady
                        ? 'Presiona "Comenzar Partida" para iniciar'
                        : 'Toca una casilla destacada para desplegar los números disponibles',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade700,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 16),

                  // Tablero visual modular (Épica 3 y Épica 4.1)
                  Expanded(
                    child: BoardGrid(
                      tablero: tablero,
                      casillasRequeridas: requeridas,
                      valoresIngresados: ingresados,
                      isInteractive: true,
                      onSelectValue: (casilla, valor) {
                        context.read<SetupBloc>().add(InputValue(casilla, valor));
                      },
                      onClearValue: (casilla) {
                        context.read<SetupBloc>().add(ClearValue(casilla));
                      },
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Botón de comenzar partida modular (Épica 4.2)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24.0),
                    child: StartGameButton(
                      isReady: isReady,
                      numbersPlaced: ingresados.length,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
