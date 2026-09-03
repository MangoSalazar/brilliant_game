import 'package:brilliant_game/brilliant_game.dart';
import 'package:test/test.dart';

void main() {
  group('BrilliantGame - Funciones de extracción de zonas y reglas', () {
    late BrilliantBoard board;

    setUp(() {
      // Inicializamos un tablero de prueba simulando celdas de un bloque
      board = BrilliantBoard([
        Cell(id: 1, region: Region.red1, color: ZoneColor.red, value: 5),
        Cell(id: 2, region: Region.red1, color: ZoneColor.red, value: 2),
        Cell(id: 3, region: Region.red1, color: ZoneColor.red, value: null), // Celda vacía
        
        Cell(id: 4, region: Region.blue1, color: ZoneColor.blue, value: 4),
        Cell(id: 5, region: Region.blue1, color: ZoneColor.blue, value: 4),
        Cell(id: 6, region: Region.blue1, color: ZoneColor.blue, value: null),
        
        Cell(id: 7, region: Region.green1, color: ZoneColor.green, value: 1),
        Cell(id: 8, region: Region.green1, color: ZoneColor.green, value: null),
        
        Cell(id: 9, region: Region.purple1, color: ZoneColor.purple, value: 3),
        Cell(id: 10, region: Region.purple1, color: ZoneColor.purple, value: 6),
        Cell(id: 11, region: Region.purple1, color: ZoneColor.purple, value: null),
        
        Cell(id: 12, region: Region.orange1, color: ZoneColor.orange, value: 1),
        Cell(id: 13, region: Region.orange1, color: ZoneColor.orange, value: 2),
        Cell(id: 14, region: Region.orange1, color: ZoneColor.orange, value: null),
      ]);
    });

    test('Extraer valores de un bloque usando enum Region', () {
      // Prueba principal de la función requerida
      List<int> redValues = board.getValuesByRegion(Region.red1);
      expect(redValues, equals([5, 2]), reason: 'Debe extraer los valores de las celdas rojas, omitiendo nulos');

      List<int> blueValues = board.getValuesByRegion(Region.blue1);
      expect(blueValues, equals([4, 4]), reason: 'Debe extraer todos los valores presentes en el bloque azul');
      
      // Una región sin celdas en el tablero devuelve lista vacía
      List<int> yellowValues = board.getValuesByRegion(Region.yellow1);
      expect(yellowValues, isEmpty, reason: 'Bloque sin inicializar devuelve lista vacía');
    });

    test('Validación de números del dado', () {
      expect(board.validateDiceInput(5), equals(5));
      expect(board.validateDiceInput('3'), equals(3));
      expect(board.validateDiceInput(7), isNull, reason: 'Fuera de rango > 6');
      expect(board.validateDiceInput(0), isNull, reason: 'Fuera de rango < 1');
      expect(board.validateDiceInput(null), isNull);
    });

    test('Reglas de inserción - Zonas Rojas (Todos diferentes)', () {
      // red1 ya tiene [5, 2]
      expect(board.canInsertValue(Region.red1, 3), isTrue, reason: '3 no está en la zona, debe permitirse');
      expect(board.canInsertValue(Region.red1, 2), isFalse, reason: '2 ya está en la zona, debe rechazarse');
      
      // Inserción real
      expect(board.tryInsertValue(3, 3), isTrue, reason: 'Se inserta correctamente en celda vacía'); 
      expect(board.tryInsertValue(3, 1), isFalse, reason: 'La celda ya está ocupada, no se puede sobrescribir');
    });

    test('Reglas de inserción - Zonas Azules (Todos iguales)', () {
      // blue1 ya tiene [4, 4]
      expect(board.canInsertValue(Region.blue1, 4), isTrue, reason: 'Debe ser idéntico a los valores existentes');
      expect(board.canInsertValue(Region.blue1, 5), isFalse, reason: 'No puede ser diferente a 4');
    });

    test('Reglas de inserción - Zonas Verdes (Cualquiera)', () {
      // green1 tiene [1]
      expect(board.canInsertValue(Region.green1, 1), isTrue, reason: 'Permite duplicados');
      expect(board.canInsertValue(Region.green1, 6), isTrue, reason: 'Permite diferentes');
    });

    test('Reglas de inserción - Zonas Moradas (Máximo 2 diferentes)', () {
      // purple1 ya tiene [3, 6]
      expect(board.canInsertValue(Region.purple1, 3), isTrue, reason: 'Puede repetir un valor que ya existe (3)');
      expect(board.canInsertValue(Region.purple1, 6), isTrue, reason: 'Puede repetir el otro valor que ya existe (6)');
      expect(board.canInsertValue(Region.purple1, 5), isFalse, reason: 'No puede introducir un TERCER número diferente (5)');
    });

    test('Reglas de inserción - Zonas Naranjas (1-3 o 4-6)', () {
      // orange1 tiene [1, 2] (rango 1-3)
      expect(board.canInsertValue(Region.orange1, 3), isTrue, reason: '3 es del rango 1-3');
      expect(board.canInsertValue(Region.orange1, 4), isFalse, reason: '4 es del rango 4-6, prohibido aquí');
      
      // Zona naranja nueva (vacía)
      board.cells.add(Cell(id: 15, region: Region.orange2, color: ZoneColor.orange));
      expect(board.canInsertValue(Region.orange2, 5), isTrue, reason: 'Zona vacía permite cualquier número del 4-6');
      board.tryInsertValue(15, 5);
      
      // Ahora orange2 es rango 4-6
      expect(board.canInsertValue(Region.orange2, 6), isTrue, reason: '6 es del rango 4-6');
      expect(board.canInsertValue(Region.orange2, 1), isFalse, reason: '1 es del rango 1-3, prohibido ahora');
    });
  });
}
