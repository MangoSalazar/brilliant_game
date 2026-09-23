import 'region.dart';

class Casilla {
  final int x;
  final int y;
  int? valor;

  Casilla(this.x, this.y, {this.valor});
}

class GrupoRegion {
  final Region tipoRegion;
  final List<Casilla> casillas;

  GrupoRegion(this.tipoRegion, this.casillas);

  bool get estaLlena => casillas.every((c) => c.valor != null);

  bool puedeAgregar(int valor) {
    if (estaLlena) return false;
    List<int> actuales = casillas.map((c) => c.valor).whereType<int>().toList();
    return tipoRegion.esPosibleAgregar(actuales, valor);
  }

  void agregarValor(Casilla casilla, int valor) {
    if (!casillas.contains(casilla)) {
      throw ArgumentError('La casilla no pertenece a esta región');
    }
    if (valor < 1 || valor > 6) {
      throw ArgumentError('El valor debe estar entre 1 y 6');
    }
    if (puedeAgregar(valor)) {
      casilla.valor = valor;
    } else {
      throw ArgumentError('Valor no válido para las reglas de esta región');
    }
  }

  bool _sonAdyacentes(Casilla a, Casilla b) {
    return (a.x - b.x).abs() + (a.y - b.y).abs() == 1;
  }

  bool validarForma() {
    if (tipoRegion is TipoAmarillo) {
      return true; // La región amarilla puede tener casillas sueltas
    }
    if (casillas.isEmpty) return true;

    // Verificar si todas las casillas están conectadas (adyacentes)
    var visitadas = <Casilla>{};
    var queue = <Casilla>[casillas.first];

    while (queue.isNotEmpty) {
      var actual = queue.removeAt(0);
      if (!visitadas.contains(actual)) {
        visitadas.add(actual);
        var vecinas = casillas.where((c) => _sonAdyacentes(actual, c) && !visitadas.contains(c));
        queue.addAll(vecinas);
      }
    }

    return visitadas.length == casillas.length;
  }
}

class Tablero {
  final int ancho;
  final int alto;
  late final List<List<Casilla>> celdas;
  final List<GrupoRegion> regiones = [];

  Tablero({this.ancho = 7, this.alto = 7}) {
    celdas = List.generate(
      alto,
      (y) => List.generate(ancho, (x) => Casilla(x, y)),
    );
  }

  Casilla getCasilla(int x, int y) {
    if (x < 0 || x >= ancho || y < 0 || y >= alto) {
      throw ArgumentError('Coordenadas fuera del tablero');
    }
    return celdas[y][x];
  }

  void agregarRegion(Region tipoRegion, List<Casilla> casillasRegion) {
    var grupo = GrupoRegion(tipoRegion, casillasRegion);
    if (!grupo.validarForma()) {
      throw ArgumentError('Las casillas de esta región deben estar conectadas, excepto si es amarilla');
    }
    
    for (var regionExistente in regiones) {
      for (var c in casillasRegion) {
        if (regionExistente.casillas.contains(c)) {
          throw ArgumentError('La casilla (${c.x}, ${c.y}) ya pertenece a otra región');
        }
      }
    }
    
    regiones.add(grupo);
  }
}
