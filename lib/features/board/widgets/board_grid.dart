import 'package:flutter/material.dart';
import '../../../../tablero.dart';
import '../../../../region.dart' hide Color;
import 'board_cell.dart';

/// Componente modular que renderiza la cuadrícula 7x7 del tablero de juego
/// asignando colores por región y administrando las casillas interactivas.
class BoardGrid extends StatelessWidget {
  final Tablero tablero;
  final List<Casilla> casillasRequeridas;
  final Map<Casilla, int> valoresIngresados;
  final bool isInteractive;
  final void Function(Casilla casilla, int value)? onSelectValue;
  final void Function(Casilla casilla)? onClearValue;

  const BoardGrid({
    super.key,
    required this.tablero,
    required this.casillasRequeridas,
    required this.valoresIngresados,
    this.isInteractive = true,
    this.onSelectValue,
    this.onClearValue,
  });

  Color _obtenerColorRegion(Casilla casilla) {
    GrupoRegion? grupo;
    for (final g in tablero.regiones) {
      if (g.casillas.contains(casilla)) {
        grupo = g;
        break;
      }
    }

    if (grupo != null) {
      if (grupo.tipoRegion is TipoAzul) return Colors.blue.shade300;
      if (grupo.tipoRegion is TipoVerde) return Colors.green.shade300;
      if (grupo.tipoRegion is TipoAmarillo) return Colors.amber.shade300;
      if (grupo.tipoRegion is TipoMorado) return Colors.purple.shade300;
      if (grupo.tipoRegion is TipoRojo) return Colors.red.shade300;
    }

    return Colors.grey.shade300;
  }

  List<int> _calcularValoresDisponibles(Casilla casilla) {
    final valoresUsadosPorOtras = valoresIngresados.entries
        .where((entry) => entry.key != casilla)
        .map((entry) => entry.value)
        .toSet();

    return [1, 2, 3, 4, 5, 6]
        .where((n) => !valoresUsadosPorOtras.contains(n))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: Colors.blueGrey.shade900.withAlpha(20),
            borderRadius: BorderRadius.circular(12),
          ),
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: tablero.ancho,
              childAspectRatio: 1,
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
            ),
            itemCount: tablero.ancho * tablero.alto,
            itemBuilder: (context, index) {
              final x = index % tablero.ancho;
              final y = index ~/ tablero.ancho;
              final casilla = tablero.getCasilla(x, y);

              final isRequired = casillasRequeridas.contains(casilla);
              final currentValue = valoresIngresados[casilla] ?? casilla.valor;
              final availableValues = isRequired ? _calcularValoresDisponibles(casilla) : const <int>[];

              return BoardCell(
                casilla: casilla,
                backgroundColor: _obtenerColorRegion(casilla),
                isRequired: isRequired,
                value: currentValue,
                availableValues: availableValues,
                isInteractive: isInteractive,
                onSelectValue: (val) => onSelectValue?.call(casilla, val),
                onClearValue: () => onClearValue?.call(casilla),
              );
            },
          ),
        ),
      ),
    );
  }
}
