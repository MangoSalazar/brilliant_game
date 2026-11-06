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

#### 7. Implementación de Nuevas Regiones y Fábrica en Código
- Se estructuró formalmente `TipoGris` y `TipoNaranja` con `VarianteNaranja` (alto y bajo) en `lib/region.dart`.
- Se implementó el patrón Factory `Region.desdeNombre` para instanciar cualquier región a partir de cadenas de texto.
- Se agregaron pruebas unitarias completas en `test/region_test.dart` y se registró el commit `736dc60`.

---

### Sesión: 5 de Noviembre de 2026

#### 1. Reestructuración de la Arquitectura: Modelo Cliente - Servidor
- Se define la separación del proyecto en dos partes principales: **Cliente** (App Flutter) y **Servidor** (Backend autoritativo con base de datos para persistencia).
- **Persistencia y Autenticación:** 
  - Pantalla inicial con registro y login de usuarios (usuario y contraseña validados por el servidor antes de ingresar a partidas).
- **Menú Principal:**
  - Opciones de "Crear una partida" o "Unirse a una partida".

#### 2. Sistema de Salas (Lobbies) y Pre-partida
- **Código de Sala:** Cada sala creada genera automáticamente un código único de 5 dígitos para unirse.
- **Capacidad:** Máximo de 6 jugadores por sala.
- **Game Master (Anfitrión):**
  - Selecciona 1 de los 4 mapas disponibles.
  - Tiene la facultad de expulsar jugadores.
  - Es el único con el botón para comenzar la partida.
- **Mecánica de Confirmación "Listo":**
  - Lista de jugadores en tiempo real.
  - Cada participante dispone de un botón para marcarse como "Listo"; su nombre se ilumina en color verde.
  - La partida **no** puede comenzar hasta que **todos** los participantes estén listos y el Game Master presione comenzar.

#### 3. Regla Fundamental de Dados Globales por Servidor
- Los dados dejan de ser individuales: **el servidor arroja los 2 dados al inicio de cada ronda**.
- El resultado es exactamente el mismo para todos los jugadores.
- Cada jugador elige independientemente en su turno/ronda cuál dado usar como ancla y en qué casilla adyacente válida colocar el segundo dado.

#### 4. Actualización Documental
- Se actualizó formalmente `Documentacion/Definicion de juego.md` reflejando la nueva arquitectura cliente-servidor, flujos de autenticación, gestión de salas, dados centralizados y nuevos requerimientos técnicos.
- Se seleccionó **Shelf** como tecnología del servidor backend y se redactó la especificación técnica completa en `Documentacion/Arquitectura Servidor Shelf.md` (REST, WebSockets, JWT, SQLite y gestión de salas en memoria).

#### 5. Implementación de Interfaz de Autenticación y Pantalla WIP
- Se implementó la arquitectura limpia para autenticación:
  - Modelo `Usuario` y contrato abstracto `AuthRepository`.
  - Repositorio `LocalAuthRepository` con cuentas de prueba (`jugador1` / `Password123`, `admin` / `Admin123`) y almacenamiento de nuevos usuarios registrados.
  - Gestión de estado con `AuthBloc` (eventos `AuthModeChanged`, `AuthLoginRequested`, `AuthRegisterRequested`, `AuthLogoutRequested`).
- Interfaz gráfica (UI):
  - `AuthScreen`: Selector de pestañas ("Iniciar Sesión" y "Crear Cuenta"), campos estilizados con feedback de visibilidad de contraseña, validaciones reactivas y banner de errores.
  - `WipScreen`: Pantalla de destino post-autenticación con el indicador de "🚧 WIP 🚧", badge del usuario autenticado y botón para cerrar sesión.
- Se añadieron runners de plataforma para Flutter (Windows y Android) y pruebas unitarias/de widgets completas (`test/auth_bloc_test.dart`, `test/widget_test.dart`), alcanzando 47 tests aprobados sin advertencias de análisis.

#### 6. Iconografía Moderna y Soporte Web
- Se integró la librería `font_awesome_flutter` (v11.0.0) para dotar a la interfaz de una estética gaming profesional:
  - Isotipo con dado poliédrico tridimensional `FontAwesomeIcons.diceD6`.
  - Íconos de formulario modernos (`FontAwesomeIcons.user`, `lock`, `shieldHalved`, `eye`, `eyeSlash`).
  - Íconos de acción contextuales en botones (`rightToBracket`, `userPlus`, `arrowRightFromBracket`, `screwdriverWrench`).
- Se configuró la plataforma **Web** para permitir la ejecución inmediata y pruebas interactivas en el navegador (Edge / Chrome) sin requerir compiladores pesados de C++ de Visual Studio.

---

## 🎯 Siguientes Pasos
1. Implementar el Menú Principal (opciones "Crear Partida" y "Unirse a Partida" con modal para el código de 5 dígitos).
2. Desarrollar la pantalla de Sala de Espera / Lobby (selector de mapas, lista de jugadores con indicador verde "Listo", botón de inicio y expulsión de jugadores).
3. Construir el backend en Shelf (`packages/server`) conectando los endpoints REST de autenticación y el handler de WebSockets para salas en tiempo real.
