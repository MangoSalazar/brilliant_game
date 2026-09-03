import 'package:brilliant_game/brilliant_game.dart';

void main(List<String> arguments) {
  print('================================================');
  print('🎲 BIENVENIDO A LA SIMULACIÓN DE BRILLIANT 🎲');
  print('================================================\n');

  // 1. Inicializamos un pequeño tablero de prueba
  final board = BrilliantBoard([
    Cell(id: 1, region: Region.red1, color: ZoneColor.red, value: 5),
    Cell(id: 2, region: Region.red1, color: ZoneColor.red, value: null),
    Cell(id: 3, region: Region.blue1, color: ZoneColor.blue, value: 4),
    Cell(id: 4, region: Region.blue1, color: ZoneColor.blue, value: null),
    Cell(id: 5, region: Region.purple1, color: ZoneColor.purple, value: 2),
    Cell(id: 6, region: Region.purple1, color: ZoneColor.purple, value: 6),
    Cell(id: 7, region: Region.purple1, color: ZoneColor.purple, value: null),
  ]);

  print('Tablero inicializado con algunas casillas predefinidas.');

  // 2. Extraer valores de un bloque usando el enum (la función principal)
  print('\n[1] EXTRACCIÓN DE VALORES POR REGIÓN:');
  print('Valores actuales en la región ROJA (red1): ${board.getValuesByRegion(Region.red1)}');
  print('Valores actuales en la región AZUL (blue1): ${board.getValuesByRegion(Region.blue1)}');
  print('Valores actuales en la región MORADA (purple1): ${board.getValuesByRegion(Region.purple1)}');

  // 3. Demostración de reglas: Región Roja (Todos diferentes)
  print('\n[2] PRUEBAS DE INSERCIÓN Y REGLAS:');
  print('\n--- Zona ROJA (Todos deben ser diferentes) ---');
  print('Intentando insertar el número 5 en la celda vacía...');
  
  if (board.tryInsertValue(2, 5)) {
    print('✅ Éxito: Se insertó el 5.');
  } else {
    print('❌ Bloqueado: No se puede insertar el 5 porque ya existe en la zona roja.');
  }

  print('Intentando insertar el número 3 en la celda vacía...');
  if (board.tryInsertValue(2, 3)) {
    print('✅ Éxito: Se insertó el 3 correctamente.');
  } else {
    print('❌ Bloqueado: No se pudo insertar.');
  }

  // 4. Demostración de reglas: Región Morada (Máx 2 diferentes)
  print('\n--- Zona MORADA (Máximo 2 números diferentes) ---');
  print('Intentando insertar el número 4 (ya existen 2 y 6)...');
  
  if (board.tryInsertValue(7, 4)) {
    print('✅ Éxito: Se insertó el 4.');
  } else {
    print('❌ Bloqueado: No se permite un tercer número diferente (regla XO).');
  }

  // 5. Mostrar el resultado final usando la función de extracción nuevamente
  print('\n================================================');
  print('RESULTADOS FINALES DESPUÉS DE LAS INSERCIONES:');
  print('Región ROJA: ${board.getValuesByRegion(Region.red1)}');
  print('Región MORADA: ${board.getValuesByRegion(Region.purple1)}');
  print('================================================\n');
  print('¡El programa está listo y ejecutándose sin errores!');
}
