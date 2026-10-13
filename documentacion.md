# Documentación de Cambios y Progreso

## ¿Qué hicimos hoy?

Hoy nos enfocamos en reestructurar las clases y la lógica principal del juego en Dart para que estuvieran alineadas exactamente con el documento de diseño.

## ¿Cómo lo hicimos?

### 1. Análisis del Documento de Diseño
Primero, se leyó el documento "Definicion de juego.md" para extraer los requerimientos técnicos y reglas:
-   **Tablero**: De dimensiones 7x7 por defecto.
-   **Celdas**: Poseen coordenadas y aceptan valores del 1 al 6.
-   **Regiones**:
    -   Tienen *puntaje*, *descripcion*, *estado para agregar (lleno o no)*, y un *color*.
    -   Existen tres funciones esenciales solicitadas: validar si está llena, insertar un número y cambiar el estado a lleno.
-   **Reglas por Color**:
    -   **Rojo y Amarillo**: Los números no se pueden repetir.
    -   **Morado**: Se permiten un máximo de dos números distintos
    -   **Azul**: .Todos los números deben ser idénticos.
    -   **Verde**: Cualquier número es válido.

### 2. Implementación en Código (`lib/region.dart`)
Esta definida la clase abstracta de la region y tambien se define las clases especificas para cada region con sus reglas, color, puntuaciones y el metodo para saber si esta llena

### 3. Ajuste de las Pruebas Unitarias (`test/region_test.dart`)
No hay pruebas unitarias creadas para la clase de las regiones, se neceitan validar la creacion de todas ellas

### 4. Siguientes pasos ()
Hacer el código del tablero donde se guardan los datos. Especifique como se llama tambien la clase que une el tablero con las regiones. Acordarse de elaborar pruebas unitarias tanto para el tablero como para validar las regiones, Quiero que el tablero este simulado como un plano cartesiano en donde cada region debera estar acomodada, las regiones deben de tener sus casillas pegadas, excepto por la amarilla, esa region puede tener sus casillas sueltas por todo el tablero, usa la clase de regiones para ello, 




---

## 📌 Contexto para continuar (sesión del 12-oct-2026)

### Estado actual
- **Fase 1 (preparación de partida)**: completa. `SetupBloc`, `BoardGrid`, `BoardCell` (PopupMenuButton), `StartGameButton`, `BoardPage`.
- **Épica 5 (lógica de partida)**: completa y subida a `main` (commit `29843f8`). Archivo: `lib/features/board/bloc/game_play_bloc.dart`. Se agregó `Tablero.clonar()` en `lib/tablero.dart`.
- **Épica 6 (UI de juego)**: pendiente. Es el siguiente paso. Detalle en `plan_interfaz_bloc.md`.
- 30 tests pasan y `dart analyze lib` está limpio.

### Reglas definidas por el usuario en la conversación
- Partida pensada para **varios jugadores**; cada jugador tiene **su propio tablero** (copia del preparado).
- Cada turno se **tiran 2 dados (1-6)**; el jugador elige uno como **ancla**. Se **iluminan las casillas disponibles que cumplen con el ancla**.
- **Puntuación** al llenar una región completa: el primero que la termina obtiene la puntuación de 1.er lugar; el siguiente que termine esa misma región obtiene menos, **hasta un máximo de 3.er lugar**. Se usan las `puntuaciones` de cada tipo de región.
- Cuando una región **esté por llenarse en esa jugada**, se **ilumina completa** y en su **centro aparece la puntuación** que daría.

### Supuestos míos (por confirmar con el usuario)
- El valor colocado es el del dado ancla; el otro dado se descarta.
- Casilla válida exige además **adyacencia** a una casilla ocupada (viene de Story 5.2 del plan).
- La partida termina cuando todas las regiones de todos los tableros están llenas; sin jugadas válidas se usa `PassTurn`.

### Pendientes / notas
- El mapa de ejemplo está en `lib/main.dart` (regiones Rojo, Azul, Verde, Amarillo; faltan Morado y casillas fuera de regiones). Las casillas sin región no son jugables.
- **Inconsistencia de docs**: en la sección "Reglas por Color" de arriba, Morado y Azul aparecen intercambiados respecto al código (`region.dart`: Azul = máx. dos números distintos, Morado = todos idénticos; Rojo y Amarillo = no repetir). Revisar contra `Documentacion/Definicion de juego.md`.
- Sin archivos versionados aún: `.idea/`, `.metadata`, `android/`, `brilliant_game.iml` (se dejaron fuera del commit a propósito).
- En la sesión no estaban disponibles las herramientas `dtd`/`hot_reload`; tras cambios en Dart hay que hacer hot restart manual.
