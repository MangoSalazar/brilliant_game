# Bitácora y Contexto de Conversaciones: Brilliant Game

Este archivo mantiene el historial cronológico, el contexto acumulado de las conversaciones y decisiones técnicas tomadas en cada sesión de desarrollo del proyecto **Brilliant Game**.

---

## 📌 Estado General del Proyecto
- **Objetivo:** Juego multijugador competitivo de estrategia numérica y control de regiones para dispositivos móviles, implementado en Dart.
- **Enfoque actual:** Lógica interna pura (Modelos, BLoCs, Validadores y Regiones) desacoplada de la interfaz gráfica.
- **Directrices:** Arquitectura regida por principios SOLID, Clean Code y protocolo de control de versiones con Git (detallado en `Documentacion/Reglas de trabajo.md`).

---

## 📝 Registro de Sesiones

### Sesión: 26 de Octubre de 2026 (Noche) / 27 de Octubre de 2026 (UTC)

#### 1. Redacción Oficial de Reglas de Juego (`Definicion de juego.md`)
- Se reestructuró y documentó integralmente la mecánica del juego **Brilliant**:
  - Modalidad multijugador donde todos los jugadores eligen uno de los 4 mapas prediseñados y compiten en tableros réplica idénticos.
  - **Fase de Setup:** Colocación de 6 números iniciales (1 al 6, sin repetir) en casillas preestablecidas.
  - **Mecánica del Ancla:** Lanzamiento de 2 dados (1-6). Se elige un dado como *ancla* (cuyo valor se localiza en el tablero) y el *dado no ancla* se ubica en una casilla ortogonalmente adyacente que cumpla las reglas de la región.
  - **Condición de Victoria:** Primer jugador en alcanzar 21 o más puntos gana la partida de inmediato.

#### 2. Incorporación de Nuevos Colores y Reglas de Región
- **⚪ Región Gris (`TipoGris`):** Todos los números deben ser idénticos. Puntuación: 1.º = 8 pts, 2.º = 6 pts, 3.º = 4 pts.
- **🟠 Región Naranja (`TipoNaranja`):** Puntuación: 1.º = 6 pts, 2.º = 4 pts, 3.º = 3 pts en ambas variantes:
  - Variante Alta (`TipoNaranjaAlto`): Solo admite números del 4 al 6.
  - Variante Baja (`TipoNaranjaBajo`): Solo admite números del 1 al 3.
- **Regla de Empate por Ronda:** Si 2 o más jugadores completan la misma región durante la misma ronda de juego, ambos obtienen el mismo puntaje correspondiente al lugar disputado.

#### 3. Eliminación Completa de la Capa de Interfaz Gráfica (UI)
- A solicitud del usuario, se removieron todas las dependencias y archivos de UI (`BoardPage`, `BoardCell`, `BoardGrid`, `StartGameButton` y `MaterialApp` en `main.dart`) para concentrar el proyecto en una lógica interna sólida, limpia y mantenible.
- Se configuró `lib/brilliant_game.dart` como punto de exportación de la biblioteca de lógica pura.

#### 4. Creación de la Clase de Constantes (`ConstantesJuego`)
- Se implementó `lib/constantes.dart` centralizando:
  - Parámetros de partida (`puntosParaGanar = 21`, `cantidadDados = 2`, `cantidadValoresIniciales = 6`, `totalMapas = 4`).
  - Dimensiones del tablero por defecto (7x7).
  - Mapas de puntuaciones (`puntuacionesEstandar`, `puntuacionesNaranja`, `puntuacionesVerde`).
  - Textos descriptivos por color de región.
  - Mensajes de error y validación unificados.
- Se integró `ConstantesJuego` en `region.dart`, `tablero.dart`, `setup_bloc.dart` y `game_play_bloc.dart`.
- Se añadieron pruebas unitarias en `test/region_test.dart` cubriendo todas las regiones y escalas.

#### 5. Definición de Reglas de Trabajo
- Se creó `Documentacion/Reglas de trabajo.md` formalizando el uso de SOLID, Clean Code, commits por implementación y el protocolo automatizado de fin de sesión.

#### 6. Especificación de los 4 Mapas (`Documentacion/Mapas del juego.txt`)
- El usuario definió la matriz de regiones y las 6 casillas iniciales de preparación para los 4 mapas del juego.

---

## 🎯 Siguientes Pasos
1. Modelar e implementar la carga/creación de los 4 mapas oficiales del juego en Dart basados en `Mapas del juego.txt`.
2. Implementar la resolución y registro de empates en la misma ronda dentro de `GamePlayBloc`.
3. Ampliar la suite de pruebas unitarias para tableros completos y flujos de partida basados en los nuevos mapas.
