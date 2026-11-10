import 'region.dart';
import 'tablero.dart';

/// Metadatos y fábrica de los 4 mapas oficiales de 7x7 de Brilliant Game.
class MapaDefinicion {
  final int id;
  final String titulo;
  final String subtitulo;
  final List<List<String>> matrizColores;

  /// Coordenadas 1-based `[fila, columna]` de las 6 casillas iniciales.
  final List<(int fila, int columna)> coordenadasIniciales;

  const MapaDefinicion({
    required this.id,
    required this.titulo,
    required this.subtitulo,
    required this.matrizColores,
    required this.coordenadasIniciales,
  });
}

/// Catálogo y constructor de tableros para los 4 mapas predefinidos.
abstract final class MapasJuego {
  static const List<MapaDefinicion> definiciones = [
    // #1 Mapa
    MapaDefinicion(
      id: 1,
      titulo: 'Mapa 1 • Clásico',
      subtitulo: 'Verde, Azul, Morado, Rojo y Amarillo',
      matrizColores: [
        ['A', 'V', 'Az', 'M', 'M', 'M', 'A'],
        ['V', 'V', 'Az', 'Az', 'M', 'M', 'V'],
        ['V', 'R', 'R', 'Az', 'M', 'V', 'V'],
        ['V', 'R', 'M', 'A', 'V', 'V', 'V'],
        ['V', 'R', 'M', 'M', 'R', 'R', 'Az'],
        ['R', 'R', 'M', 'R', 'R', 'Az', 'Az'],
        ['A', 'M', 'M', 'R', 'R', 'Az', 'A'],
      ],
      coordenadasIniciales: [
        (1, 3),
        (2, 6),
        (4, 2),
        (4, 5),
        (6, 3),
        (7, 5),
      ],
    ),

    // #2 Mapa
    MapaDefinicion(
      id: 2,
      titulo: 'Mapa 2 • Fortaleza Gris',
      subtitulo: 'Incluye zonas Grises de números idénticos',
      matrizColores: [
        ['M', 'M', 'M', 'G', 'V', 'V', 'V'],
        ['M', 'A', 'AZ', 'AZ', 'AZ', 'A', 'V'],
        ['M', 'R', 'R', 'AZ', 'AZ', 'R', 'V'],
        ['R', 'R', 'R', 'A', 'R', 'R', 'R'],
        ['V', 'R', 'AZ', 'AZ', 'R', 'R', 'M'],
        ['V', 'A', 'AZ', 'AZ', 'AZ', 'A', 'M'],
        ['V', 'V', 'V', 'G', 'M', 'M', 'M'],
      ],
      coordenadasIniciales: [
        (1, 5),
        (3, 1),
        (4, 3),
        (5, 6),
        (6, 2),
        (7, 5),
      ],
    ),

    // #3 Mapa
    MapaDefinicion(
      id: 3,
      titulo: 'Mapa 3 • Franjas Simétricas',
      subtitulo: 'Bandas horizontales y bloques Grises',
      matrizColores: [
        ['A', 'A', 'M', 'G', 'M', 'A', 'A'],
        ['G', 'A', 'M', 'M', 'M', 'A', 'G'],
        ['R', 'R', 'R', 'M', 'R', 'R', 'R'],
        ['R', 'R', 'R', 'G', 'R', 'R', 'R'],
        ['V', 'AZ', 'AZ', 'AZ', 'AZ', 'AZ', 'V'],
        ['V', 'V', 'V', 'V', 'V', 'V', 'V'],
        ['M', 'M', 'M', 'G', 'M', 'M', 'M'],
      ],
      coordenadasIniciales: [
        (2, 3),
        (2, 6),
        (4, 5),
        (5, 2),
        (5, 7),
        (7, 3),
      ],
    ),

    // #4 Mapa
    MapaDefinicion(
      id: 4,
      titulo: 'Mapa 4 • Anillo Naranja',
      subtitulo: 'Fila superior Naranja Alto (4-6) e inferior Naranja Bajo (1-3)',
      matrizColores: [
        ['N', 'N', 'N', 'N', 'N', 'N', 'N'],
        ['A', 'R', 'AZ', 'V', 'AZ', 'R', 'A'],
        ['R', 'R', 'M', 'M', 'M', 'R', 'R'],
        ['A', 'V', 'AZ', 'M', 'AZ', 'V', 'A'],
        ['R', 'R', 'M', 'M', 'M', 'R', 'R'],
        ['A', 'R', 'AZ', 'V', 'AZ', 'R', 'A'],
        ['N', 'N', 'N', 'N', 'N', 'N', 'N'],
      ],
      coordenadasIniciales: [
        (1, 5),
        (3, 3),
        (3, 6),
        (4, 1),
        (6, 5),
        (7, 2),
      ],
    ),
  ];

  /// Obtiene la definición de un mapa por su identificador (1 al 4).
  static MapaDefinicion obtenerDefinicion(int mapaId) {
    final index = (mapaId - 1).clamp(0, definiciones.length - 1);
    return definiciones[index];
  }

  /// Construye una instancia de [Tablero] de 7x7 con todas las regiones y
  /// las 6 casillas iniciales configuradas para el [mapaId] indicado (1 al 4).
  static Tablero crearTablero(int mapaId) {
    final def = obtenerDefinicion(mapaId);
    final alto = def.matrizColores.length;
    final ancho = def.matrizColores.first.length;
    final tablero = Tablero(ancho: ancho, alto: alto);

    final visitadas = List.generate(alto, (_) => List.filled(ancho, false));
    final casillasAmarillas = <Casilla>[];

    // 1. Recolectar todas las casillas Amarillas ('A') en una sola región dispersa
    for (int y = 0; y < alto; y++) {
      for (int x = 0; x < ancho; x++) {
        final codigo = def.matrizColores[y][x].trim().toUpperCase();
        if (codigo == 'A') {
          casillasAmarillas.add(tablero.getCasilla(x, y));
          visitadas[y][x] = true;
        }
      }
    }

    if (casillasAmarillas.isNotEmpty) {
      tablero.agregarRegion(const TipoAmarillo(), casillasAmarillas);
    }

    // 2. Para el resto de colores, agrupar cada bloque conectado ortogonalmente
    for (int y = 0; y < alto; y++) {
      for (int x = 0; x < ancho; x++) {
        if (visitadas[y][x]) continue;

        final codigoBase = def.matrizColores[y][x].trim().toUpperCase();
        final bloque = <Casilla>[];
        final cola = <(int, int)>[(x, y)];
        visitadas[y][x] = true;

        while (cola.isNotEmpty) {
          final (cx, cy) = cola.removeAt(0);
          bloque.add(tablero.getCasilla(cx, cy));

          for (final (dx, dy) in const [(1, 0), (-1, 0), (0, 1), (0, -1)]) {
            final nx = cx + dx;
            final ny = cy + dy;
            if (nx < 0 || nx >= ancho || ny < 0 || ny >= alto) continue;
            if (visitadas[ny][nx]) continue;

            final codigoVecino =
                def.matrizColores[ny][nx].trim().toUpperCase();
            if (codigoVecino == codigoBase) {
              visitadas[ny][nx] = true;
              cola.add((nx, ny));
            }
          }
        }

        final region = _instanciarRegionPorCodigo(codigoBase, filaInicial: y);
        tablero.agregarRegion(region, bloque);
      }
    }

    // 3. Configurar las 6 casillas iniciales preestablecidas (convirtiendo de 1-based a 0-based)
    final iniciales = def.coordenadasIniciales
        .map((coord) => tablero.getCasilla(coord.$2 - 1, coord.$1 - 1))
        .toList();
    tablero.asignarCasillasIniciales(iniciales);

    return tablero;
  }

  static Region _instanciarRegionPorCodigo(
    String codigoUpper, {
    required int filaInicial,
  }) {
    switch (codigoUpper) {
      case 'A':
        return const TipoAmarillo();
      case 'V':
        return const TipoVerde();
      case 'AZ':
        return const TipoAzul();
      case 'M':
        return const TipoMorado();
      case 'R':
        return const TipoRojo();
      case 'G':
        return const TipoGris();
      case 'N':
        // En el Mapa 4: Fila de arriba (fila 0) = Naranja Alto (4-6),
        // Fila de abajo = Naranja Bajo (1-3)
        return filaInicial == 0
            ? const TipoNaranjaAlto()
            : const TipoNaranjaBajo();
      default:
        throw ArgumentError('Código de color de mapa no válido: $codigoUpper');
    }
  }
}
