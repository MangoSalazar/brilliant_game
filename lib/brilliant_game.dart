enum ZoneColor {
  red,
  yellow,
  blue,
  green,
  purple
}

class Coordinate {
  final int x;
  final int y;

  Coordinate(this.x, this.y);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Coordinate &&
          runtimeType == other.runtimeType &&
          x == other.x &&
          y == other.y;

  @override
  int get hashCode => x.hashCode ^ y.hashCode;
}

class Cell {
  final Coordinate coordinate;
  int? value;

  Cell({
    required this.coordinate,
    this.value,
  });
}

class Region {
  final String id;
  final ZoneColor color;
  final int cellLimit;
  final int score;
  final List<Cell> cells;
  
  bool _isFull = false;
  
  bool get isFull => _isFull;

  Region({
    required this.id,
    required this.color,
    required this.cellLimit,
    required this.score,
    List<Cell>? cells,
  }) : cells = cells ?? [];

  /// Función para saber si una región ya esta llena
  bool isRegionFull() {
    return _isFull;
  }

  /// Función para cambiar el estado de lleno
  void updateFullState() {
    if (cells.length == cellLimit && cells.every((c) => c.value != null)) {
      _isFull = true;
    } else {
      _isFull = false;
    }
  }

  /// Función para insertar un numero en esa región
  bool insertNumber(Coordinate coord, int number) {
    if (_isFull) return false;
    if (number < 1 || number > 6) return false;

    // Buscar la celda en la región
    final cellIndex = cells.indexWhere((c) => c.coordinate == coord);
    if (cellIndex == -1) return false; // Celda no pertenece a esta región

    final cell = cells[cellIndex];
    if (cell.value != null) return false; // Celda ya ocupada

    if (canInsertValue(number)) {
      cell.value = number;
      updateFullState();
      return true;
    }
    return false;
  }

  List<int> getCurrentValues() {
    return cells.where((c) => c.value != null).map((c) => c.value!).toList();
  }

  bool canInsertValue(int newValue) {
    List<int> currentValues = getCurrentValues();

    switch (color) {
      case ZoneColor.red:
      case ZoneColor.yellow:
        // Amarillo y rojo: Los números no se pueden repetir
        return !currentValues.contains(newValue);

      case ZoneColor.purple:
        // Morado: Las celdas deben llenarse con el mismo numero
        return currentValues.isEmpty || currentValues.first == newValue;

      case ZoneColor.blue:
        // Azul: Las celdas deben llenarse con 2 números distintos
        Set<int> uniqueNumbers = currentValues.toSet();
        uniqueNumbers.add(newValue);
        return uniqueNumbers.length <= 2;

      case ZoneColor.green:
        // Verde: Las celdas pueden llenarse con cualquier numero
        return true;
    }
  }
}

class BrilliantBoard {
  int width;
  int height;
  final List<Region> regions;

  BrilliantBoard({
    this.width = 7,
    this.height = 7,
    required this.regions,
  });

  /// Encuentra a qué región pertenece una coordenada
  Region? getRegionAt(Coordinate coord) {
    for (var region in regions) {
      if (region.cells.any((c) => c.coordinate == coord)) {
        return region;
      }
    }
    return null;
  }
}
