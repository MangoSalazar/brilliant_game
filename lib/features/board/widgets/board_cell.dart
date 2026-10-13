import 'package:flutter/material.dart';
import '../../../../tablero.dart';

/// Casilla individual del tablero con soporte para menú desplegable (combobox)
/// que muestra únicamente los números disponibles (1-6) durante la preparación.
class BoardCell extends StatelessWidget {
  final Casilla casilla;
  final Color backgroundColor;
  final bool isRequired;
  final int? value;
  final List<int> availableValues;
  final bool isInteractive;
  final ValueChanged<int>? onSelectValue;
  final VoidCallback? onClearValue;

  const BoardCell({
    super.key,
    required this.casilla,
    required this.backgroundColor,
    required this.isRequired,
    this.value,
    this.availableValues = const [],
    this.isInteractive = true,
    this.onSelectValue,
    this.onClearValue,
  });

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null;

    final cellContent = Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isRequired ? Colors.black87 : Colors.black26,
          width: isRequired ? 2.5 : 1.0,
        ),
        boxShadow: isRequired
            ? [
                BoxShadow(
                  color: Colors.black.withAlpha(40),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                )
              ]
            : null,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Indicador sutil de celda inicial requerida si está vacía
          if (isRequired && !hasValue)
            Positioned(
              right: 2,
              bottom: 2,
              child: Icon(
                Icons.arrow_drop_down,
                size: 16,
                color: Colors.black.withAlpha(120),
              ),
            ),
          // Valor numérico
          if (hasValue)
            Text(
              '$value',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            )
          else if (isRequired)
            Text(
              '?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black.withAlpha(75),
              ),
            ),
        ],
      ),
    );

    // Si es requerida e interactiva, envolvemos en un menú desplegable (PopupMenuButton / Combobox)
    if (isRequired && isInteractive) {
      return PopupMenuButton<int>(
        tooltip: 'Elegir número para casilla (${casilla.x}, ${casilla.y})',
        offset: const Offset(0, 45),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        itemBuilder: (context) {
          final items = <PopupMenuEntry<int>>[];

          // Encabezado informativo
          items.add(
            const PopupMenuItem<int>(
              enabled: false,
              child: Text(
                'Números disponibles:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ),
          );

          if (availableValues.isEmpty && !hasValue) {
            items.add(
              const PopupMenuItem<int>(
                enabled: false,
                child: Text('No hay números disponibles'),
              ),
            );
          } else {
            // Solo los números disponibles (1 al 6 sin repetirse)
            for (final n in availableValues) {
              items.add(
                PopupMenuItem<int>(
                  value: n,
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: Colors.blueGrey,
                        child: Text(
                          '$n',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text('Número $n', style: const TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              );
            }
          }

          // Opción para limpiar valor si ya tenía uno asignado
          if (hasValue) {
            items.add(const PopupMenuDivider());
            items.add(
              const PopupMenuItem<int>(
                value: -1,
                child: Row(
                  children: [
                    Icon(Icons.clear, color: Colors.red, size: 20),
                    SizedBox(width: 12),
                    Text('Quitar número', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            );
          }

          return items;
        },
        onSelected: (selectedValue) {
          if (selectedValue == -1) {
            onClearValue?.call();
          } else {
            onSelectValue?.call(selectedValue);
          }
        },
        child: cellContent,
      );
    }

    // Casillas no requeridas
    return GestureDetector(
      onTap: () {
        if (!isRequired) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Esta casilla no es una de las 6 asignadas para la preparación.'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      },
      child: cellContent,
    );
  }
}
