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

## 🚀 Fase 2: Ciclo de Jugabilidad y Turnos (Siguiente Iteración)

### 🎲 Épica 5: Gestión de Turnos y Fichas en BLoC
- **Story 5.1: Estado de Partida Activa (`GamePlayState`)**
  - Almacenar el turno actual, puntos acumulados y números disponibles por jugada.
- **Story 5.2: Eventos de Jugada (`PlaceNumber`, `PassTurn`, `ResetGame`)**
  - Validar colocación de números en casillas vacías adyacentes respetando las restricciones de color de cada región (`puedeAgregar`).

### 🧩 Épica 6: Interfaz Interactiva de Juego
- **Story 6.1: Panel de Jugador y Puntuación**
  - Mostrar turno actual, puntuación y bolsa/dados de números.
- **Story 6.2: Retroalimentación Visual de Reglas de Región**
  - Resaltar casillas válidas para jugar según la región tocada (Azul, Morado, Verde, Amarillo, Rojo).
