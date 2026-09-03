/// Enumerador que define las regiones (bloques o zonas) de un tablero de Brilliant.
/// Se usa como parámetro para identificar un bloque concreto del juego.
enum Region {
  red1,
  red2,
  yellow1,
  yellow2,
  blue1,
  blue2,
  green1,
  green2,
  purple1,
  purple2,
  orange1,
  orange2,
  grey1,
  grey2
}

/// Enumerador para los tipos de color de zona, útil para aplicar las reglas de validación.
enum ZoneColor {
  red,
  yellow,
  blue,
  green,
  purple,
  orange,
  grey
}

/// Representa una casilla individual en el tablero.
class Cell {
  final int id;          // Identificador único de la casilla
  final Region region;   // Bloque/región al que pertenece la casilla
  final ZoneColor color; // Color de la zona (regla aplicable)
  int? value;            // Valor actual del dado escrito en la casilla (1-6)

  Cell({
    required this.id,
    required this.region,
    required this.color,
    this.value,
  });
}

/// Representa el tablero de juego de Brilliant.
class BrilliantBoard {
  final List<Cell> cells;

  BrilliantBoard(this.cells);

  /// =========================================================
  /// Función Principal Solicitada: 
  /// Extrae los valores de las celdas de cualquier bloque.
  /// Toma como parámetro un ENUM que indica cuál es la región.
  /// Devuelve una LISTA DE ENTEROS con los valores.
  /// =========================================================
  List<int> getValuesByRegion(Region region) {
    return cells
        .where((cell) => cell.region == region && cell.value != null)
        .map((cell) => cell.value!)
        .toList();
  }

  /// Valida que el dato ingresado sea un número entero (o texto convertible a entero) 
  /// y que esté estrictamente en el rango de un dado de 6 caras.
  int? validateDiceInput(dynamic input) {
    int? number;
    if (input is int) {
      number = input;
    } else if (input is String) {
      number = int.tryParse(input);
    }
    
    if (number != null && number >= 1 && number <= 6) {
      return number;
    }
    return null; // Retorna null si es un tipo de dato inválido o está fuera de rango
  }

  /// Verifica si un número cumple con las reglas de inserción de una región determinada
  /// utilizando la función getValuesByRegion.
  bool canInsertValue(Region region, dynamic input) {
    int? newValue = validateDiceInput(input);
    if (newValue == null) return false;

    // Obtener los valores actuales en la región invocando la función principal
    List<int> currentValues = getValuesByRegion(region);
    
    // Identificamos el color de la región
    final cellsInRegion = cells.where((c) => c.region == region);
    if (cellsInRegion.isEmpty) return false; // Región no existe en el tablero actual

    ZoneColor color = cellsInRegion.first.color;

    // Aplicamos las reglas según el color (extraídas del PDF y del archivo txt)
    switch (color) {
      case ZoneColor.red:
      case ZoneColor.yellow:
        // ZONAS ROJAS Y AMARILLAS: Todos los números deben ser diferentes.
        return !currentValues.contains(newValue);
      
      case ZoneColor.blue:
      case ZoneColor.grey:
        // ZONAS AZULES Y GRISES: Todos los números deben ser iguales en su respectiva zona.
        return currentValues.isEmpty || currentValues.first == newValue;
      
      case ZoneColor.green:
        // ZONAS VERDES: No hay ningún requisito.
        return true;
      
      case ZoneColor.purple:
        // ZONAS MORADAS: Solo pueden escribirse un máximo de dos números diferentes.
        Set<int> uniqueNumbers = currentValues.toSet();
        uniqueNumbers.add(newValue);
        return uniqueNumbers.length <= 2;
      
      case ZoneColor.orange:
        // ZONAS NARANJAS: O bien solo números del 1-3, o bien solo números del 4-6.
        if (currentValues.isEmpty) return true;
        bool isLowGroup = currentValues.first <= 3;
        bool newValueIsLow = newValue <= 3;
        return isLowGroup == newValueIsLow;
    }
  }

  /// Intenta insertar un valor en una celda específica evaluando primero las reglas.
  bool tryInsertValue(int cellId, dynamic input) {
    final cellIndex = cells.indexWhere((c) => c.id == cellId);
    if (cellIndex == -1) return false;
    
    final cell = cells[cellIndex];
    if (cell.value != null) return false; // La celda ya tiene un número

    if (canInsertValue(cell.region, input)) {
      cell.value = validateDiceInput(input);
      return true;
    }
    return false;
  }
}
