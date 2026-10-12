import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'features/board/bloc/setup_bloc.dart';
import 'features/board/view/board_page.dart';
import 'tablero.dart';
import 'region.dart' hide Color;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Creamos un tablero inicial para visualizarlo
    final tablero = Tablero(ancho: 7, alto: 7);
    
    // Agregamos algunas regiones de prueba para poder ver los colores
    // (En un futuro esto se cargará desde un nivel predefinido)
    tablero.agregarRegion(TipoRojo(), [
      tablero.getCasilla(0, 0), tablero.getCasilla(1, 0), tablero.getCasilla(2, 0),
      tablero.getCasilla(0, 1), tablero.getCasilla(1, 1), tablero.getCasilla(2, 1),
      tablero.getCasilla(0, 2), tablero.getCasilla(1, 2), tablero.getCasilla(2, 2),
    ]);

    tablero.agregarRegion(TipoAzul(), [
      tablero.getCasilla(3, 0), tablero.getCasilla(4, 0),
      tablero.getCasilla(3, 1), tablero.getCasilla(4, 1),
      tablero.getCasilla(3, 2), tablero.getCasilla(4, 2),
    ]);

    tablero.agregarRegion(TipoVerde(), [
      tablero.getCasilla(5, 0), tablero.getCasilla(6, 0),
      tablero.getCasilla(5, 1), tablero.getCasilla(6, 1),
      tablero.getCasilla(5, 2), tablero.getCasilla(6, 2),
    ]);
    
    // Región amarilla puede estar dispersa
    tablero.agregarRegion(TipoAmarillo(), [
      tablero.getCasilla(0, 6), tablero.getCasilla(6, 6),
      tablero.getCasilla(3, 4),
    ]);

    return MaterialApp(
      title: 'Brilliant Game',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: BlocProvider(
        create: (context) => SetupBloc()..add(StartSetup(tablero)),
        child: const BoardPage(),
      ),
    );
  }
}
