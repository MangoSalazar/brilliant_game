import 'dart:math';
import 'constantes.dart';
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
      throw ArgumentError(ConstantesJuego.errorCasillaNoPertenece);
    }
    if (valor < ConstantesJuego.valorDadoMinimo || valor > ConstantesJuego.valorDadoMaximo) {
      throw ArgumentError(ConstantesJuego.errorRangoDado);
    }
    if (puedeAgregar(valor)) {
      casilla.valor = valor;
    } else {
      throw ArgumentError(ConstantesJuego.errorReglasRegion);
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

  Tablero({
    this.ancho = ConstantesJuego.anchoTableroPorDefecto,
    this.alto = ConstantesJuego.altoTableroPorDefecto,
  }) {
    celdas = List.generate(
      alto,
      (y) => List.generate(ancho, (x) => Casilla(x, y)),
    );
  }

  List<Casilla> generarCasillasIniciales() {
    var random = Random();
    var seleccionadas = <Casilla>{};
    while (seleccionadas.length < ConstantesJuego.cantidadValoresIniciales) {
      int x = random.nextInt(ancho);
      int y = random.nextInt(alto);
      seleccionadas.add(celdas[y][x]);
    }
    return seleccionadas.toList();
  }

  /// Crea una copia independiente del tablero (valores y regiones incluidos).
  Tablero clonar() {
    final copia = Tablero(ancho: ancho, alto: alto);
    for (var y = 0; y < alto; y++) {
      for (var x = 0; x < ancho; x++) {
        copia.celdas[y][x].valor = celdas[y][x].valor;
      }
    }
    for (final g in regiones) {
      copia.agregarRegion(
        g.tipoRegion,
        g.casillas.map((c) => copia.celdas[c.y][c.x]).toList(),
      );
    }
    return copia;
  }

  Casilla getCasilla(int x, int y) {
    if (x < 0 || x >= ancho || y < 0 || y >= alto) {
      throw ArgumentError(ConstantesJuego.errorCoordenadasFuera);
    }
    return celdas[y][x];
  }

  void agregarRegion(Region tipoRegion, List<Casilla> casillasRegion) {
    var grupo = GrupoRegion(tipoRegion, casillasRegion);
    if (!grupo.validarForma()) {
      throw ArgumentError(ConstantesJuego.errorFormaRegion);
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
