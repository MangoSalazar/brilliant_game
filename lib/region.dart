import 'constantes.dart';

/// Minimal color value used by regions without depending on Flutter's
/// `dart:ui` library.
class Color {
  final int value;

  const Color(this.value);
}

/// Variantes disponibles para la región Naranja.
enum VarianteNaranja {
  /// Admite únicamente números del 4 al 6.
  alto,

  /// Admite únicamente números del 1 al 3.
  bajo,
}

abstract class Region {
  const Region();

  Color get color;
  String get descripcion;
  bool esPosibleAgregar(List<int> actuales, int posibles);
  Map<int, int> get puntuaciones;

  /// Método de fábrica para instanciar una región a partir de su nombre.
  static Region desdeNombre(
    String nombre, {
    VarianteNaranja varianteNaranja = VarianteNaranja.alto,
  }) {
    switch (nombre.toLowerCase().trim()) {
      case 'rojo':
        return const TipoRojo();
      case 'azul':
        return const TipoAzul();
      case 'verde':
        return const TipoVerde();
      case 'amarillo':
        return const TipoAmarillo();
      case 'morado':
        return const TipoMorado();
      case 'gris':
        return const TipoGris();
      case 'naranja':
        return TipoNaranja(variante: varianteNaranja);
      case 'naranja_alto':
      case 'naranjaalto':
        return const TipoNaranjaAlto();
      case 'naranja_bajo':
      case 'naranjabajo':
        return const TipoNaranjaBajo();
      default:
        throw ArgumentError('Tipo de región no reconocido: $nombre');
    }
  }
}

class TipoAzul extends Region {
  const TipoAzul();

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
  const TipoVerde();

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
  const TipoAmarillo();

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
  const TipoMorado();

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
  const TipoRojo();

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

/// Región Gris: Todos los números dentro de la zona deben ser idénticos.
/// Puntuaciones: 1.º = 8 pts, 2.º = 6 pts, 3.er = 4 pts.
class TipoGris extends Region {
  const TipoGris();

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

/// Región Naranja: Presenta dos variantes posibles (Alto: 4-6, Bajo: 1-3).
/// Puntuaciones en ambas variantes: 1.º = 6 pts, 2.º = 4 pts, 3.er = 3 pts.
class TipoNaranja extends Region {
  final VarianteNaranja variante;

  const TipoNaranja({this.variante = VarianteNaranja.alto});
  const TipoNaranja.alto() : variante = VarianteNaranja.alto;
  const TipoNaranja.bajo() : variante = VarianteNaranja.bajo;

  @override
  Color get color => const Color(0xFFFF9800);

  @override
  String get descripcion => variante == VarianteNaranja.alto
      ? ConstantesJuego.descRegionNaranjaAlto
      : ConstantesJuego.descRegionNaranjaBajo;

  @override
  bool esPosibleAgregar(List<int> actuales, int posible) {
    if (variante == VarianteNaranja.alto) {
      return posible >= 4 && posible <= 6;
    } else {
      return posible >= 1 && posible <= 3;
    }
  }

  @override
  Map<int, int> get puntuaciones => ConstantesJuego.puntuacionesNaranja;
}

/// Subclase especializada para Naranja variante Alta (4 al 6).
class TipoNaranjaAlto extends TipoNaranja {
  const TipoNaranjaAlto() : super.alto();
}

/// Subclase especializada para Naranja variante Baja (1 al 3).
class TipoNaranjaBajo extends TipoNaranja {
  const TipoNaranjaBajo() : super.bajo();
}
