# 📋 Product Backlog: Interfaz del Juego

## ✅ Fase 1: Preparación de Partida (Completada 100%)

En esta primera iteración nos enfocamos **exclusivamente en lograr el Estado de Partida Preparada**:
Pintar el tablero con sus colores de región, permitir al jugador colocar los 6 números iniciales mediante un menú desplegable (combobox / PopupMenuButton) al presionar una celda destacada mostrando únicamente los números disponibles (1-6 sin repetir), y validar que estén correctos para habilitar el botón de inicio de partida.

---

### 🎯 Épica 1: Arquitectura y Configuración Base (Completada ✅)
- **Story 1.1:** Configuración de dependencias (`flutter_bloc`, `equatable`).
- **Story 1.2:** Estructura de directorios Feature-First (`features/board/`).

### 🧠 Épica 2: Gestión de Estado BLoC - Fase de Preparación (Completada ✅)
*Lógica de estado para la colocación de los 6 números iniciales.*
- **Story 2.1:** Definición de Estados (`SetupInitial`, `SetupAwaitingInputs`, `SetupCompleted`).
- **Story 2.2:** Definición de Eventos (`StartSetup`, `InputValue`, `ClearValue`).
- **Story 2.3:** Implementación del `SetupBloc` con validación de valores únicos (1-6) en las 6 casillas requeridas, cálculo dinámico de `valoresDisponiblesPara` y transición a `SetupCompleted`.

### 📱 Épica 3: Interfaz del Tablero - Cuadrícula y Colores (Completada ✅)
*Visualización modular del tablero 7x7.*
- **Story 3.1:** Construcción de `BoardGrid` (cuadrícula 7x7 alojando 49 casillas con `AspectRatio`).
- **Story 3.2:** Aplicación visual de colores por región (Rojo, Amarillo, Morado, Azul, Verde) y bordes destacados en casillas requeridas.

### 🎮 Épica 4: Interacción de Preparación (Completada ✅)
*Mecanismo de selección numérica y habilitación del juego.*
- **Story 4.1:** Componente `BoardCell` con `PopupMenuButton` (combobox desplegable) que filtra y muestra **únicamente los números disponibles** (1 al 6 no repetidos) y opción para retirar número.
- **Story 4.2:** Componente `StartGameButton` que permanece deshabilitado mostrando progreso (`X/6`) y se habilita automáticamente en verde cuando la partida está lista para comenzar.

---

## 🚀 Fase 2: Ciclo de Jugabilidad y Turnos (En curso)

### 🎲 Épica 5: Gestión de Turnos y Fichas en BLoC (Completada ✅ — `game_play_bloc.dart`)
- **Story 5.1: Estado de Partida Activa (`GamePlayActive`)** ✅
  - Un tablero independiente por jugador (`Tablero.clonar()`), jugador actual, puntos, 2 dados, ancla elegida, orden de completado por región, `terminada` y contador `jugadas`.
  - Getters: `casillasValidas`, `regionesPorLlenar` (región completa + puntos que daría), `puntosParaCompletar`.
- **Story 5.2: Eventos de Jugada** ✅
  - `StartGame(tablero, jugadores)`, `SelectAnchor(dado)`, `PlaceNumber(x, y)`, `PassTurn`, `ResetGame`.
  - Casilla válida = vacía, dentro de una región, adyacente a una ocupada y la región acepta el ancla (`puedeAgregar`).
  - Puntuación al llenar una región: `puntuaciones[lugar]` según orden de llegada (1.º, 2.º, 3.º; después 0).
- Tests: `test/game_play_bloc_test.dart` (6 casos). `dart analyze` sin errores.

### 🧩 Épica 6: Interfaz Interactiva de Juego (Pendiente — siguiente paso)
- **Story 6.0: Conectar el flujo Setup → Juego**
  - `StartGameButton` debe disparar `StartGame(tablero, jugadores)` y navegar/cambiar a la pantalla de juego (`BlocProvider<GamePlayBloc>`).
- **Story 6.1: Panel de Jugador y Puntuación**
  - Mostrar jugador actual, puntos de todos, los 2 dados (tocar uno = `SelectAnchor`) y botón `PassTurn`/`ResetGame`.
- **Story 6.2: Retroalimentación Visual de Reglas de Región**
  - Iluminar `casillasValidas` del ancla elegida.
  - Iluminar completa cada región de `regionesPorLlenar` y mostrar en su centro los puntos que daría.
  - Tocar una casilla iluminada = `PlaceNumber`. Mostrar `errorMessage` y pantalla de fin (`terminada`) con ganador.
- **Story 6.3: Tests de widget/bloc de la nueva UI.**