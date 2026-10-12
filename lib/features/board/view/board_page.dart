import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/setup_bloc.dart';
import '../../../tablero.dart';
import '../../../region.dart' hide Color;

class BoardPage extends StatelessWidget {
  const BoardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Brilliant Game - Setup'),
        backgroundColor: Colors.blueGrey,
      ),
      body: BlocBuilder<SetupBloc, SetupState>(
        builder: (context, state) {
          if (state is SetupInitial) {
            return const Center(child: CircularProgressIndicator());
          }

          Tablero? tablero;
          List<Casilla> requeridas = [];
          Map<Casilla, int> ingresados = {};

          if (state is SetupAwaitingInputs) {
            tablero = state.tablero;
            requeridas = state.casillasRequeridas;
            ingresados = state.valoresIngresados;
          } else if (state is SetupCompleted) {
            tablero = state.tablero;
          }

          if (tablero == null) return const SizedBox();

          return Column(
            children: [
              const SizedBox(height: 16),
              // Feedback de errores
              if (state is SetupAwaitingInputs && state.errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          state.errorMessage!,
                          style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              // Feedback de éxito
              if (state is SetupCompleted)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green),
                      SizedBox(width: 8),
                      Text(
                        '¡Números iniciales correctos!',
                        style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              
              const SizedBox(height: 24),
              const Text(
                'Coloca los números iniciales (1 al 6)',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Tablero visual
              Expanded(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Container(
                      padding: const EdgeInsets.all(8.0),
                      color: Colors.black12,
                      child: GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: tablero.ancho,
                          childAspectRatio: 1,
                          crossAxisSpacing: 3,
                          mainAxisSpacing: 3,
                        ),
                        itemCount: tablero.ancho * tablero.alto,
                        itemBuilder: (context, index) {
                          int x = index % tablero.ancho;
                          int y = index ~/ tablero.ancho;
                          final casilla = tablero.getCasilla(x, y);
                          
                          // Identificar región de la casilla
                          GrupoRegion? grupo;
                          for (var g in tablero.regiones) {
                            if (g.casillas.contains(casilla)) {
                              grupo = g;
                              break;
                            }
                          }

                          // Mapeo de colores (fallback seguro)
                          Color bgColor = Colors.grey.shade300;
                          if (grupo != null) {
                            if (grupo.tipoRegion is TipoAzul) bgColor = Colors.blue.shade300;
                            if (grupo.tipoRegion is TipoVerde) bgColor = Colors.green.shade300;
                            if (grupo.tipoRegion is TipoAmarillo) bgColor = Colors.yellow.shade400;
                            if (grupo.tipoRegion is TipoMorado) bgColor = Colors.purple.shade300;
                            if (grupo.tipoRegion is TipoRojo) bgColor = Colors.red.shade300;
                          }

                          bool esRequerida = requeridas.contains(casilla);
                          int? valor = ingresados[casilla] ?? casilla.valor;

                          return GestureDetector(
                            onTap: () {
                              if (state is SetupAwaitingInputs && esRequerida) {
                                _mostrarSelectorNativo(context, casilla);
                              } else if (state is SetupAwaitingInputs && !esRequerida) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Esta casilla no es para los números iniciales. Selecciona una remarcada.'), duration: Duration(seconds: 2))
                                );
                              }
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: bgColor,
                                border: Border.all(
                                  color: esRequerida ? Colors.black : Colors.transparent,
                                  width: esRequerida ? 3 : 1,
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Center(
                                child: Text(
                                  valor != null ? valor.toString() : '',
                                  style: const TextStyle(
                                    fontSize: 24, 
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),

              // Botón Comenzar
              if (state is SetupCompleted)
                Padding(
                  padding: const EdgeInsets.only(bottom: 32.0),
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      // TODO: Transición a la partida real
                    },
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Comenzar Partida', style: TextStyle(fontSize: 18)),
                  ),
                ),
              if (state is! SetupCompleted)
                const SizedBox(height: 80), // Spacer equivalent
            ],
          );
        },
      ),
    );
  }

  void _mostrarSelectorNativo(BuildContext context, Casilla casilla) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Selecciona el número para esta casilla:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: List.generate(6, (index) {
                  int valor = index + 1;
                  return InkWell(
                    onTap: () {
                      Navigator.of(ctx).pop();
                      context.read<SetupBloc>().add(InputValue(casilla, valor));
                    },
                    child: CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.blueGrey,
                      child: Text(
                        valor.toString(),
                        style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}
