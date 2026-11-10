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

### Sesión: 6 de Noviembre de 2026

#### 1. Requerimiento Académico: Accesibilidad Global del Servidor (WAN / Internet)
- Se incorporó formalmente a la documentación técnica el requerimiento establecido por el profesor: **el servidor debe ser accesible por cualquier usuario desde cualquier parte del mundo**, trascendiendo el ámbito de red de área local (LAN o `localhost`).
- **Actualización de Documentación:**
  - `Documentacion/Definicion de juego.md`: Se especificó la modalidad multijugador en red global por Internet (WAN), el rol del servidor como servicio público y la flexibilidad del cliente para conectarse a endpoints remotos.
  - `Documentacion/Arquitectura Servidor Shelf.md`: Se añadió la sección *8. Despliegue y Accesibilidad Global (Acceso WAN / Internet)* detallando:
    - Opciones de hosting en la nube (Render, Railway, Fly.io, DigitalOcean, VPS con Docker) y túneles seguros para pruebas remotas (Cloudflare Tunnels, ngrok).
    - Protocolos obligatorios HTTPS y WSS para evitar restricciones de navegadores y firewalls móviles.
    - Configuración de CORS universal.
    - Mecanismo de *heartbeats* (`pingInterval` de 30s) en WebSockets para mantener vivas las conexiones en rutas geográficas de larga distancia.
    - Parametrización dinámica de la URL del servidor en el cliente Flutter.

#### 2. Implementación del Menú Principal y Modal de Código de 5 Dígitos
- Se implementó la interfaz gráfica del Menú Principal ([`MainMenuScreen`](file:///C:/Users/Manguito/Documents/brilliant_game/lib/features/menu/ui/main_menu_screen.dart)) en sustitución de la pantalla provisional WIP:
  - Header con isotipo, badge del usuario autenticado y botón para cerrar sesión integrado con [`AuthBloc`](file:///C:/Users/Manguito/Documents/brilliant_game/lib/features/auth/bloc/auth_bloc.dart).
  - Opción destacada **"Crear Partida"** ([`MenuActionCard`](file:///C:/Users/Manguito/Documents/brilliant_game/lib/features/menu/ui/widgets/menu_action_card.dart)) asignando el rol de Game Master y generando el código numérico de 5 dígitos para compartir.
  - Opción destacada **"Unirse a Partida"** que despliega el modal interactivo [`JoinRoomDialog`](file:///C:/Users/Manguito/Documents/brilliant_game/lib/features/menu/ui/widgets/join_room_dialog.dart), con validación reactiva de exactamente 5 dígitos numéricos y teclado especializado.
  - Componente informativo [`GameInfoBanner`](file:///C:/Users/Manguito/Documents/brilliant_game/lib/features/menu/ui/widgets/game_info_banner.dart) con los parámetros clave (21+ pts para ganar, hasta 6 jugadores, 2 dados globales, 4 mapas).
  - Badge contextual de Conexión Global WAN clarificando que el código de 5 dígitos funciona a través de Internet con amigos en cualquier país.
- Pruebas y Calidad:
  - Se implementó la suite completa de tests de widgets en `test/main_menu_test.dart`.
  - Se alcanzaron 52 pruebas aprobadas con cero advertencias en `flutter analyze`.

#### 3. Configuración Web y Verificación
- Se añadió `uses-material-design: true` en `pubspec.yaml` para asegurar la resolución de fuentes de iconos en Flutter Web.
- Se verificó la ejecución exitosa de la aplicación web en desarrollo local y la suite completa de 52 pruebas automatizadas.

---

### Sesión: 7 de Noviembre de 2026

#### 1. Delimitación de Responsabilidades Cliente - Servidor
A requerimiento explícito del diseño de arquitectura, se formalizó y delimitó con precisión el reparto de responsabilidades operativas entre el cliente y el servidor:
- **Responsabilidad del Servidor:**
  - **Tirada Centralizada de Dados:** El servidor es la única entidad encargada de generar autoritativamente la tirada de los 2 dados al inicio de cada ronda y comunicar el resultado idéntico a todos los jugadores (`dice_rolled`).
  - **Arbitraje y Comunicación de Puntos:** Recibe las notificaciones de zonas llenadas por los jugadores, adjudica los puestos en la carrera por regiones (1.º, 2.º, 3.er lugar y resolución de empates en la misma ronda) y transmite la tabla general de puntuaciones actualizada en tiempo real (`scores_updated`).
  - **Declaración del Ganador:** Evalúa la condición de fin de partida (alcanzar 21 o más puntos) y proclama oficialmente al jugador ganador ante toda la sala (`game_over`).
- **Responsabilidad del Cliente:**
  - **Acomodo de Números en Tablero:** El jugador selecciona autónomamente el dado ancla y ubica el segundo dado en casillas válidas. El cliente valida localmente las reglas de adyacencia ortogonal y restricciones del color de la región mediante su BLoC.
  - **Notificación de Zona Llena:** En el momento exacto en que una jugada completa el 100% de las casillas de una región, el cliente emite de forma inmediata un evento al servidor (`region_completed`) solicitando los puntos de dicha zona.
  - **Confirmación de Acción:** Informa al servidor cuando ha colocado su número (`turn_completed`) o cuando decide pasar el turno (`pass_turn`).

#### 2. Actualización de Documentación Técnica
- Se actualizaron las secciones 2, 5 y 9 de [`Definicion de juego.md`](file:///C:/Users/Manguito/Documents/brilliant_game/Documentacion/Definicion%20de%20juego.md).
- Se actualizaron las secciones 1 y 6.2 del protocolo WebSocket en [`Arquitectura Servidor Shelf.md`](file:///C:/Users/Manguito/Documents/brilliant_game/Documentacion/Arquitectura%20Servidor%20Shelf.md).

#### 3. Creación del Documento Maestro de Asignación de Funciones
- Se creó el documento formal [`Documentacion/Asignacion de funciones Cliente-Servidor.md`](file:///C:/Users/Manguito/Documents/brilliant_game/Documentacion/Asignacion%20de%20funciones%20Cliente-Servidor.md) que desglosa las 39 funciones del sistema agrupadas en 8 módulos clave (Autenticación, Lobbies, Setup, Dados/Rondas, Acomodo/Tablero, Puntuación/Arbitraje, Victoria/Fin de Partida y Conectividad), incluyendo una matriz de roles y un diagrama de secuencia de una ronda de juego típica.

#### 4. Implementación del Servidor Shelf y Sala de Espera (Lobby) en Tiempo Real
- **Servidor Shelf Independiente ([`bin/server.dart`](file:///C:/Users/Manguito/Documents/brilliant_game/bin/server.dart) y `lib/server/`):**
  - Se implementó [`BrilliantServerApp`](file:///C:/Users/Manguito/Documents/brilliant_game/lib/server/server_app.dart) con soporte CORS universal, endpoints REST de autenticación (`/api/auth/login`, `/api/auth/register`, `/api/auth/me`) respaldados por [`ServerAuthService`](file:///C:/Users/Manguito/Documents/brilliant_game/lib/server/services/server_auth_service.dart) con hasheo SHA-256.
  - Se implementó [`RoomManager`](file:///C:/Users/Manguito/Documents/brilliant_game/lib/server/services/room_manager.dart) para gestionar en memoria la creación de salas con código único de 5 dígitos, unión de hasta 6 jugadores, selección de mapa (1 al 4), alternancia de estado "Listo", expulsiones y transferencia automática de Game Master en caso de desconexión.
  - Se implementó [`LobbyWsHandler`](file:///C:/Users/Manguito/Documents/brilliant_game/lib/server/ws/lobby_ws_handler.dart) sobre WebSockets (`/ws`) para sincronizar instantáneamente a todos los clientes conectados a la misma sala.
- **Cliente y Sala de Espera ([`LobbyScreen`](file:///C:/Users/Manguito/Documents/brilliant_game/lib/features/lobby/ui/lobby_screen.dart)):**
  - Se implementaron los modelos [`SalaPartida`](file:///C:/Users/Manguito/Documents/brilliant_game/lib/features/lobby/models/sala_partida.dart) y [`JugadorSala`](file:///C:/Users/Manguito/Documents/brilliant_game/lib/features/lobby/models/jugador_sala.dart), el repositorio WebSocket [`WebSocketLobbyRepository`](file:///C:/Users/Manguito/Documents/brilliant_game/lib/features/lobby/repositories/lobby_repository.dart) y [`LobbyBloc`](file:///C:/Users/Manguito/Documents/brilliant_game/lib/features/lobby/bloc/lobby_bloc.dart).
  - La pantalla [`LobbyScreen`](file:///C:/Users/Manguito/Documents/brilliant_game/lib/features/lobby/ui/lobby_screen.dart) visualiza el código de 5 dígitos, selector de los 4 mapas, lista en tiempo real de jugadores conectados iluminando en color verde (`#10B981`) a quienes se marcan como "Listo", botón de expulsión y transición a [`WipScreen`](file:///C:/Users/Manguito/Documents/brilliant_game/lib/features/home/ui/wip_screen.dart) al iniciar la partida.
- **Pruebas y Calidad:**
  - Se implementaron suites de integración y widgets en [`test/server_room_test.dart`](file:///C:/Users/Manguito/Documents/brilliant_game/test/server_room_test.dart) y [`test/lobby_screen_test.dart`](file:///C:/Users/Manguito/Documents/brilliant_game/test/lobby_screen_test.dart), alcanzando **60 pruebas automatizadas aprobadas** y cero advertencias en `flutter analyze`.

---

### Sesión: 9 de Noviembre de 2026

#### 1. Robustez en Salas de Espera (Lobby) y Cuentas Activas Únicas
- **Gestión de Desconexiones y Transferencia de Game Master:**
  - Si un jugador pierde la conexión en el lobby, se remueve de inmediato, regresa a `MainMenuScreen` y el resto de la sala recibe una notificación informativa.
  - Si el Game Master sale o se desconecta, el rol se transfiere automáticamente al jugador activo más antiguo y se muestra un diálogo de confirmación antes de abandonar voluntariamente.
- **Alternancia Libre del Botón "Listo" y Bloqueo de Partida Iniciada:**
  - El botón de estado Listo permite alternar libremente entre `"MARCARME COMO LISTO"` y `"CANCELAR LISTO"` en cualquier momento sin reiniciarse al cambiar de mapa.
  - Se bloquea el ingreso a salas cuya partida ya ha comenzado (`ConstantesJuego.errorPartidaYaIniciada`).
  - Se corrigió la cancelación inmediata al crear/unirse a una sala cuando el servidor Shelf no está disponible (`lobby_cancel_connecting_button`).
- **Prevención de Cuentas Duplicadas en Uso (`ServerAuthService` y `AuthRoutes`):**
  - El servidor rastrea las sesiones activas (`_activeUserIds`) e impide iniciar sesión o entrar a una sala con una cuenta que ya se encuentra activa en otra ventana/dispositivo (`409 Conflict` con `ConstantesJuego.errorSesionYaActiva`), liberándola automáticamente al cerrar sesión (`POST /api/auth/logout`) o desconectarse del WebSocket.

#### 2. Diseño e Implementación de los 4 Mapas Oficiales (7×7) y Pantalla de Partida (`GameScreen`)
- **Fábrica de los 4 Mapas Predefinidos ([`lib/mapas_juego.dart`](file:///C:/Users/Manguito/Documents/brilliant_game/lib/mapas_juego.dart)):**
  - Se implementó `MapasJuego` a partir de las matrices corregidas de 7×7 en `Documentacion/Mapas del juego.txt`, agrupando por componentes conexos cada bloque de color (y región amarilla dispersa) y asignando las 6 casillas iniciales de preparación de cada mapa.
- **Distribución de `GameScreen` ([`lib/features/board/ui/game_screen.dart`](file:///C:/Users/Manguito/Documents/brilliant_game/lib/features/board/ui/game_screen.dart)):**
  - **Columna Izquierda:** Panel de **Reglas y Puntos en Disputa**, donde cada zona muestra sus 3 escalas (`1.º`, `2.º`, `3.º`) e ilumina en el color de la zona únicamente la puntuación que está actualmente en disputa.
  - **Columna Central (de arriba hacia abajo):**
    1. **Apartado de Puntuaciones de la Sala** encima del tablero (mostrando puntos en vivo y estado de cada jugador; si un jugador abandona con la partida ya empezada, permanece en la lista marcado como `"Abandonó la partida"` con `abandono: true` para que los demás sigan jugando).
    2. **Apartado de Resultados de los Dados** ubicado entre las puntuaciones y el tablero.
    3. **Tablero Interactivo 7×7** debajo de los dados.
  - **Columna Derecha:** Panel de Acción contextual según la fase (Setup de fichas `1..6`, Ronda activa con Dado Ancla o Podio Final).

#### 3. Ciclo Completo de Partidas Multijugador en Tiempo Real
- **Fase 1 (Setup Sincronizado):** Cuando todos los jugadores activos confirman sus 6 números iniciales (`setup_completed`), el servidor inicia automáticamente la **Ronda 1** y lanza los **2 dados globales** (`dice_rolled`).
- **Fase 2 (Dado Ancla y Acomodo):** Cada jugador elige uno de los 2 dados globales como **Dado Ancla** (cuyo valor debe existir en su tablero) y coloca el **otro dado** en una casilla vacía adyacente ortogonalmente al número Ancla que cumpla la regla de color de la región, o bien pasa su turno (`pass_turn`).
- **Arbitraje de Puntos, Empates y Victoria (`RoomManager`):**
  - Al cierre de cada ronda, el servidor adjudica los puntos de las regiones completadas (otorgando el mismo puntaje en disputa si dos o más jugadores completan el mismo color en la misma ronda), avanza el indicador encendido de `1.º -> 2.º -> 3.º` lugar en el panel de reglas y proclama al ganador en cuanto algún jugador alcanza **21 o más puntos** (`EstadoSala.finalizada`).
- **Pruebas y Calidad:**
  - Se alcanzaron **70 pruebas automatizadas aprobadas** (`flutter test`) y cero advertencias en `flutter analyze`.

---

## 🎯 Siguientes Pasos
1. Realizar pruebas de experiencia de usuario multijugador con varias ventanas/clientes simultáneos en navegador y ajustar detalles visuales o animaciones de transición entre rondas si se requiere.
2. Evaluar si se desea agregar un temporizador opcional por ronda o revancha rápida dentro de la misma sala al finalizar una partida.
