import 'package:brilliant_game/brilliant_game.dart';
import 'package:test/test.dart';

void main() {
  group('BrilliantGame - Funciones de extracción de zonas y reglas', () {
    late BrilliantBoard board;
    late Region redRegion;
    late Region blueRegion;
    late Region greenRegion;
    late Region purpleRegion;
    late Region yellowRegion;

    setUp(() {
      redRegion = Region(
        id: 'red1',
        color: ZoneColor.red,
        cellLimit: 3,
        score: 10,
        cells: [
          Cell(coordinate: Coordinate(0, 0), value: 5),
          Cell(coordinate: Coordinate(0, 1), value: 2),
          Cell(coordinate: Coordinate(0, 2)), // Celda vacía
        ],
      );

      blueRegion = Region(
        id: 'blue1',
        color: ZoneColor.blue,
        cellLimit: 4,
        score: 15,
        cells: [
          Cell(coordinate: Coordinate(1, 0), value: 4),
          Cell(coordinate: Coordinate(1, 1), value: 2),
          Cell(coordinate: Coordinate(1, 2)), // Celda vacía
          Cell(coordinate: Coordinate(1, 3)), // Celda vacía
        ],
      );

      greenRegion = Region(
        id: 'green1',
        color: ZoneColor.green,
        cellLimit: 2,
        score: 5,
        cells: [
          Cell(coordinate: Coordinate(2, 0), value: 1),
          Cell(coordinate: Coordinate(2, 1)), // Celda vacía
        ],
      );

      purpleRegion = Region(
        id: 'purple1',
        color: ZoneColor.purple,
        cellLimit: 3,
        score: 20,
        cells: [
          Cell(coordinate: Coordinate(3, 0), value: 3),
          Cell(coordinate: Coordinate(3, 1), value: 3),
          Cell(coordinate: Coordinate(3, 2)), // Celda vacía
        ],
      );

      yellowRegion = Region(
        id: 'yellow1',
        color: ZoneColor.yellow,
        cellLimit: 2,
        score: 10,
        cells: [
          Cell(coordinate: Coordinate(4, 0), value: 6),
          Cell(coordinate: Coordinate(4, 1)), // Celda vacía
        ],
      );

      board = BrilliantBoard(
        regions: [redRegion, blueRegion, greenRegion, purpleRegion, yellowRegion],
      );
    });

    test('isRegionFull - estado inicial', () {
      expect(redRegion.isRegionFull(), isFalse);
      expect(redRegion.isFull, isFalse);
      
      // Update state in case it needs calculation
      redRegion.updateFullState();
      expect(redRegion.isFull, isFalse);
    });

    test('Reglas de inserción - Zonas Rojas y Amarillas (No repetidos)', () {
      // redRegion ya tiene [5, 2]
      expect(redRegion.canInsertValue(3), isTrue, reason: '3 no está en la zona, debe permitirse');
      expect(redRegion.canInsertValue(2), isFalse, reason: '2 ya está en la zona, debe rechazarse');
      
      // Inserción real
      expect(redRegion.insertNumber(Coordinate(0, 2), 3), isTrue, reason: 'Se inserta correctamente en celda vacía'); 
      expect(redRegion.insertNumber(Coordinate(0, 0), 1), isFalse, reason: 'La celda ya está ocupada, no se puede sobrescribir');

      // Después de llenarlo
      expect(redRegion.isRegionFull(), isTrue);

      // Amarillo
      expect(yellowRegion.canInsertValue(1), isTrue);
      expect(yellowRegion.canInsertValue(6), isFalse);
    });

    test('Reglas de inserción - Zonas Moradas (Todos iguales)', () {
      // purpleRegion ya tiene [3, 3]
      expect(purpleRegion.canInsertValue(3), isTrue, reason: 'Debe ser idéntico a los valores existentes');
      expect(purpleRegion.canInsertValue(4), isFalse, reason: 'No puede ser diferente a 3');

      expect(purpleRegion.insertNumber(Coordinate(3, 2), 3), isTrue);
      expect(purpleRegion.isRegionFull(), isTrue);
    });

    test('Reglas de inserción - Zonas Verdes (Cualquiera)', () {
      // greenRegion tiene [1]
      expect(greenRegion.canInsertValue(1), isTrue, reason: 'Permite duplicados');
      expect(greenRegion.canInsertValue(6), isTrue, reason: 'Permite diferentes');

      expect(greenRegion.insertNumber(Coordinate(2, 1), 6), isTrue);
      expect(greenRegion.isRegionFull(), isTrue);
    });

    test('Reglas de inserción - Zonas Azules (Máximo 2 diferentes)', () {
      // blueRegion ya tiene [4, 2]
      expect(blueRegion.canInsertValue(4), isTrue, reason: 'Puede repetir un valor que ya existe (4)');
      expect(blueRegion.canInsertValue(2), isTrue, reason: 'Puede repetir el otro valor que ya existe (2)');
      expect(blueRegion.canInsertValue(5), isFalse, reason: 'No puede introducir un TERCER número diferente (5)');

      expect(blueRegion.insertNumber(Coordinate(1, 2), 4), isTrue);
      expect(blueRegion.insertNumber(Coordinate(1, 3), 2), isTrue);
      expect(blueRegion.isRegionFull(), isTrue);
    });
    
    test('No puede insertar números inválidos', () {
      expect(redRegion.insertNumber(Coordinate(0, 2), 7), isFalse);
      expect(redRegion.insertNumber(Coordinate(0, 2), 0), isFalse);
    });
  });
}
