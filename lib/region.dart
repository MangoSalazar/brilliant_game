/// Minimal color value used by regions without depending on Flutter's
/// `dart:ui` library.
class Color {
  final int value;

  const Color(this.value);
}

abstract class Region {
  Color get color;
  String get descripcion;
  bool esPosibleAgregar(List<int> actuales, List<int> posibles);
  Map<int, int> get puntuaciones;
}
