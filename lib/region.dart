/// Minimal color value used by regions without depending on Flutter's
/// `dart:ui` library.
class Color {
  final int value;

  const Color(this.value);
}

abstract class Region {
  Color get color;
  String get descripcion;
  bool esPosibleAgregar(List<int> actuales, int posibles);
  Map<int, int> get puntuaciones;
}

class TipoAzul extends Region {
  @override
  Color get color => const Color(0xFFF2196F3);
 
  @override
  String get descripcion => 'Máximo dos números diferentes por zona';
 
  @override
  bool esPosibleAgregar(List<int> actuales, int posible) {
    final distintos = actuales.toSet()..add(posible);
    return distintos.length <= 2;
  }
 
  @override
  Map<int, int> get puntuaciones => {
    1:8,
    2:6,
    3:4
  };
}

class TipoVerde extends Region {
  @override
  Color get color => const Color(0xFF4CAF50);
 
  @override
  String get descripcion => 'Se puede colocar cualquier número';
 
  @override
  bool esPosibleAgregar(List<int> actuales, int posible) {
    return true;
  }
 
  @override
  Map<int, int> get puntuaciones => {
    1: 4,
    2: 3,
    3: 2,
  };
}

class TipoAmarillo extends Region {
  @override
  Color get color => const Color(0xFFFFC107);
 
  @override
  String get descripcion => 'Todos los números deben de ser distintos';
 
  @override
  bool esPosibleAgregar(List<int> actuales, int posible) {
    return actuales.isEmpty || actuales.every((element) => element != posible);
  }
 
  @override
  Map<int, int> get puntuaciones => {
    1: 8,
    2: 6,
    3: 4,
  };
}

class TipoMorado extends Region {
  @override
  Color get color => const Color(0xFF9C27B0);
 
  @override
  String get descripcion => 'Todos los números deben ser idénticos';
 
  @override
  bool esPosibleAgregar(List<int> actuales, int posible) {
    return actuales.isEmpty || actuales.every((element) => element == posible);
  }
 
  @override
  Map<int, int> get puntuaciones => {
    1: 8,
    2: 6,
    3: 4,
  };
}

class TipoRojo extends Region {
  @override
  Color get color => const Color(0xFFF44336);
 
  @override
  String get descripcion => 'Todos los números deben de ser distintos';
 
 
  @override
  bool esPosibleAgregar(List<int> actuales, int posible) {
    return actuales.isEmpty || actuales.every((element) => element != posible);
  }
 
  @override
  Map<int, int> get puntuaciones => {
    1:8,
    2:6,
    3:4
  };
}
 