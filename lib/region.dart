import 'constantes.dart';

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
  Color get color => const Color(0xFF2196F3);

  @override
  String get descripcion => ConstantesJuego.descRegionAzul;

  @override
  bool esPosibleAgregar(List<int> actuales, int posible) {
    final distintos = actuales.toSet()..add(posible);
    return distintos.length <= 2;
  }

  @override
  Map<int, int> get puntuaciones => ConstantesJuego.puntuacionesEstandar;
}

class TipoVerde extends Region {
  @override
  Color get color => const Color(0xFF4CAF50);

  @override
  String get descripcion => ConstantesJuego.descRegionVerde;

  @override
  bool esPosibleAgregar(List<int> actuales, int posible) {
    return true;
  }

  @override
  Map<int, int> get puntuaciones => ConstantesJuego.puntuacionesVerde;
}

class TipoAmarillo extends Region {
  @override
  Color get color => const Color(0xFFFFC107);

  @override
  String get descripcion => ConstantesJuego.descRegionAmarilla;

  @override
  bool esPosibleAgregar(List<int> actuales, int posible) {
    return actuales.isEmpty || actuales.every((element) => element != posible);
  }

  @override
  Map<int, int> get puntuaciones => ConstantesJuego.puntuacionesEstandar;
}

class TipoMorado extends Region {
  @override
  Color get color => const Color(0xFF9C27B0);

  @override
  String get descripcion => ConstantesJuego.descRegionMorada;

  @override
  bool esPosibleAgregar(List<int> actuales, int posible) {
    return actuales.isEmpty || actuales.every((element) => element == posible);
  }

  @override
  Map<int, int> get puntuaciones => ConstantesJuego.puntuacionesEstandar;
}

class TipoRojo extends Region {
  @override
  Color get color => const Color(0xFFF44336);

  @override
  String get descripcion => ConstantesJuego.descRegionRoja;

  @override
  bool esPosibleAgregar(List<int> actuales, int posible) {
    return actuales.isEmpty || actuales.every((element) => element != posible);
  }

  @override
  Map<int, int> get puntuaciones => ConstantesJuego.puntuacionesEstandar;
}

class TipoGris extends Region {
  @override
  Color get color => const Color(0xFF9E9E9E);

  @override
  String get descripcion => ConstantesJuego.descRegionGris;

  @override
  bool esPosibleAgregar(List<int> actuales, int posible) {
    return actuales.isEmpty || actuales.every((element) => element == posible);
  }

  @override
  Map<int, int> get puntuaciones => ConstantesJuego.puntuacionesEstandar;
}

class TipoNaranjaAlto extends Region {
  @override
  Color get color => const Color(0xFFFF9800);

  @override
  String get descripcion => ConstantesJuego.descRegionNaranjaAlto;

  @override
  bool esPosibleAgregar(List<int> actuales, int posible) {
    return posible >= 4 && posible <= 6;
  }

  @override
  Map<int, int> get puntuaciones => ConstantesJuego.puntuacionesNaranja;
}

class TipoNaranjaBajo extends Region {
  @override
  Color get color => const Color(0xFFFF9800);

  @override
  String get descripcion => ConstantesJuego.descRegionNaranjaBajo;

  @override
  bool esPosibleAgregar(List<int> actuales, int posible) {
    return posible >= 1 && posible <= 3;
  }

  @override
  Map<int, int> get puntuaciones => ConstantesJuego.puntuacionesNaranja;
}
