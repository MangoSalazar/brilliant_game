# 📋 Product Backlog: Interfaz del Juego (Fase 1 - Preparación de Partida)

Como Scrum Master, he ajustado la planificación según los nuevos requerimientos. En esta primera iteración nos enfocaremos **exclusivamente en lograr el Estado de Partida Preparada**. 

Esto incluye: pintar el tablero con sus colores, permitir al jugador colocar los 6 números iniciales mediante un menú desplegable (combobox) al presionar una celda, y validar que estén correctos para habilitar el botón de inicio de partida.

---

## 🎯 Épica 1: Arquitectura y Configuración Base (Completada ✅)
- **Story 1.1:** Configuración de dependencias (`flutter_bloc`, `equatable`).
- **Story 1.2:** Estructura de directorios Feature-First.

## 🧠 Épica 2: Gestión de Estado BLoC (Fase de Preparación)
*Definir la lógica de estado para la colocación de los 6 números iniciales.*

- **Story 2.1: Definición de Estados (`GameState`)**
  - *Tarea:* Crear estados base como `GameSetup` (Preparando partida, bloqueando el inicio) y `GameReadyToStart` (Partida válida, botón habilitado).
- **Story 2.2: Definición de Eventos (`GameEvent`)**
  - *Tarea:* Crear eventos de preparación como `SetupStarted`, y `InitialNumberPlaced(x, y, valor)`.
- **Story 2.3: Implementación del `GameBloc` (Lógica de Setup)**
  - *Tarea:* Controlar el registro de los números ingresados, validando que el jugador introduzca exactamente los números del 1 al 6 sin repetirse y en las posiciones válidas estipuladas por el inicio del juego.
  - *Tarea:* Cambiar el estado a `GameReadyToStart` automáticamente en cuanto la validación de los 6 números sea exitosa.

## 📱 Épica 3: Interfaz del Tablero (Cuadrícula y Colores)
*Visualizar el tablero inicial en estado estático.*

- **Story 3.1: Construcción de la Cuadrícula 7x7**
  - *Tarea:* Implementar el contenedor principal y un `GridView` (o similar) para alojar exactamente 49 casillas.
- **Story 3.2: Aplicación de Colores por Región**
  - *Tarea:* Configurar el renderizado visual de cada celda para que adopte el color de la región a la que pertenece (Rojo, Amarillo, Morado, Azul, Verde) basado en la configuración inicial del tablero.

## 🎮 Épica 4: Interacción de Preparación (Combobox y Botón)
*Implementar el mecanismo de selección y la habilitación del juego.*

- **Story 4.1: Selección Numérica vía Combobox**
  - *Tarea:* Programar que al tocar una celda vacía aparezca un menú desplegable (`PopupMenuButton` o un combobox a medida) mostrando únicamente los números permitidos/disponibles.
  - *Tarea:* Al elegir un número del combobox, colocarlo automáticamente en la celda y notificar al `GameBloc`.
- **Story 4.2: Interfaz de "Comenzar Partida"**
  - *Tarea:* Construir el botón "Comenzar Partida".
  - *Tarea:* Ocultar o deshabilitar este botón mientras el estado sea `GameSetup`. Mostrarlo/habilitarlo únicamente cuando el estado pase a `GameReadyToStart`.
