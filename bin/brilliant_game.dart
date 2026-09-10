import 'package:brilliant_game/brilliant_game.dart';

void main(List<String> arguments) {
  print('================================================');
  print('🎲 BIENVENIDO A LA SIMULACIÓN DE BRILLIANT 🎲');
  print('================================================\n');

  final redRegion = Region(
    id: 'red1',
    color: ZoneColor.red,
    cellLimit: 3,
    score: 10,
    cells: [
      Cell(coordinate: Coordinate(0, 0), value: 5),
      Cell(coordinate: Coordinate(0, 1)), // Celda vacía
      Cell(coordinate: Coordinate(0, 2)), // Celda vacía
    ],
  );

  final blueRegion = Region(
    id: 'blue1',
    color: ZoneColor.blue,
    cellLimit: 3,
    score: 15,
    cells: [
      Cell(coordinate: Coordinate(1, 0), value: 4),
      Cell(coordinate: Coordinate(1, 1)), // Celda vacía
      Cell(coordinate: Coordinate(1, 2)), // Celda vacía
    ],
  );

  final purpleRegion = Region(
    id: 'purple1',
    color: ZoneColor.purple,
    cellLimit: 3,
    score: 20,
    cells: [
      Cell(coordinate: Coordinate(2, 0), value: 2),
      Cell(coordinate: Coordinate(2, 1), value: 2),
      Cell(coordinate: Coordinate(2, 2)), // Celda vacía
    ],
  );

  final board = BrilliantBoard(
    regions: [redRegion, blueRegion, purpleRegion],
  );

  print('Tablero inicializado con algunas casillas predefinidas.');

  print('\n[1] EXTRACCIÓN DE VALORES POR REGIÓN:');
  print('Valores actuales en la región ROJA (red1): ${redRegion.getCurrentValues()}');
  print('Valores actuales en la región AZUL (blue1): ${blueRegion.getCurrentValues()}');
  print('Valores actuales en la región MORADA (purple1): ${purpleRegion.getCurrentValues()}');

  print('\n[2] PRUEBAS DE INSERCIÓN Y REGLAS:');
  print('\n--- Zona ROJA (Todos deben ser diferentes) ---');
  print('Intentando insertar el número 5 en la celda vacía...');
  
  if (redRegion.insertNumber(Coordinate(0, 1), 5)) {
    print('✅ Éxito: Se insertó el 5.');
  } else {
    print('❌ Bloqueado: No se puede insertar el 5 porque ya existe en la zona roja.');
  }

  print('Intentando insertar el número 3 en la celda vacía...');
  if (redRegion.insertNumber(Coordinate(0, 1), 3)) {
    print('✅ Éxito: Se insertó el 3 correctamente.');
  } else {
    print('❌ Bloqueado: No se pudo insertar.');
  }

  print('\n--- Zona MORADA (Todos iguales) ---');
  print('Intentando insertar el número 4 (ya existen 2 y 2)...');
  
  if (purpleRegion.insertNumber(Coordinate(2, 2), 4)) {
    print('✅ Éxito: Se insertó el 4.');
  } else {
    print('❌ Bloqueado: No se permite un número diferente (deben ser todos iguales).');
  }

  print('\n================================================');
  print('RESULTADOS FINALES DESPUÉS DE LAS INSERCIONES:');
  print('Región ROJA: ${redRegion.getCurrentValues()}');
  print('Región MORADA: ${purpleRegion.getCurrentValues()}');
  print('================================================\n');
  print('¡El programa está listo y ejecutándose sin errores!');
}
