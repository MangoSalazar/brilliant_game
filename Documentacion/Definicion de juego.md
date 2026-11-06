# Definición del Juego: Brilliant

## 1. Visión General
**Brilliant** es un juego de mesa digital de estrategia y colocación de números, diseñado para dispositivos móviles y desarrollado en **Dart** (usando el framework Flutter). 

Está concebido para partidas **multijugador** competitivas en red bajo una arquitectura **Cliente-Servidor**, donde cada jugador compite sobre su propia copia idéntica de un tablero seleccionado, buscando completar regiones y acumular puntos antes que sus contrincantes.

- **Plataforma:** Dispositivos móviles (Android / iOS) y Web.
- **Tecnología:** Dart & Flutter (arquitectura con BLoC y comunicación en tiempo real con servidor).
- **Modalidad:** Multijugador en red global por Internet / WAN (hasta 6 jugadores por sala, cada uno con su tablero independiente). Los usuarios pueden conectarse y jugar simultáneamente desde cualquier lugar del mundo.
- **Condición de victoria:** La partida termina en cuanto un jugador alcanza **21 o más puntos**. Gana quien cumpla esta condición primero.

---

## 2. Arquitectura General y Persistencia (Cliente - Servidor)

El sistema se divide formalmente en dos capas independientes y desacopladas:

1. **Servidor (Backend & Persistencia):**
   - **Accesibilidad Global en Internet (WAN):** El servidor debe estar expuesto públicamente a través de Internet (nube, VPS, IP pública o túnel seguro) para permitir el acceso ininterrumpido desde cualquier ubicación geográfica del mundo, sin limitarse a una red de área local (LAN).
   - **Almacenamiento de Datos:** Base de datos para persistir cuentas de usuario, contraseñas seguras y registros de partidas.
   - **Servicio de Autenticación:** Verificación de credenciales (usuario y contraseña) antes de permitir el acceso a las funciones multijugador.
   - **Gestión de Salas (Lobbies):** Creación, sincronización de estados de jugadores, control del rol de Game Master y validación de reglas de inicio.
   - **Motor de Azar Autorizado:** El servidor es la única entidad responsable de lanzar los dados en cada ronda para garantizar partidas justas e invulnerables a trampas locales.

2. **Cliente (App Móvil / Web):**
   - Interfaz de usuario para autenticación, gestión de sala y visualización interactiva del tablero.
   - Configuración de conexión remota flexible para apuntar al dominio o IP pública del servidor desplegado en la nube.
   - Motor local de validación de reglas de colocación de números y cálculo de estados mediante BLoC.
   - Comunicación en tiempo real con el servidor (WebSockets o sockets bidireccionales sobre WSS/WS).

---

## 3. Flujo de Usuario y Gestión de Salas (Lobbies)

### 3.1. Autenticación (Inicio de Sesión y Registro)
1. Al abrir la aplicación, la primera pantalla que encuentra el jugador es el módulo de autenticación:
   - **Iniciar Sesión:** Ingreso de usuario y contraseña existentes.
   - **Crear Cuenta (Registro):** Formulario para registrar un nuevo usuario con credenciales que se almacenan en el servidor.
2. El servidor valida obligatoriamente las credenciales antes de autorizar la entrada al menú principal.

### 3.2. Menú Principal
Una vez autenticado, el jugador dispone de dos opciones principales:
1. **Crear una Partida:** Convierte al usuario en el **Game Master (dueño de la sala)** y lo traslada a la pantalla de configuración del lobby.
2. **Unirse a una Partida:** Solicita el ingreso de un **código de sala de 5 dígitos**.

### 3.3. Configuración y Dinámica de la Sala de Espera (Lobby)
- **Código Único de Sala:** Toda nueva sala recibe automáticamente un identificador numérico único de **5 dígitos** generado por el servidor.
- **Capacidad Máxima:** Cada sala admite un límite estricto de **hasta 6 jugadores simultáneos**.
- **Rol del Dueño de la Sala (Game Master):**
  - **Selección de Mapa:** Elige cuál de los **4 mapas prediseñados** se jugará en la partida.
  - **Expulsión de Jugadores:** Cuenta con la facultad de expulsar (kickear) a cualquier jugador que esté dentro de la sala.
  - **Iniciar Partida:** Es el único facultado para accionar el botón de inicio de juego.
- **Lista de Jugadores y Estado "Listo" (Ready):**
  - La sala muestra el listado en tiempo real de todos los participantes conectados.
  - Cada jugador dispone de un botón para marcarse como **Listo**.
  - Al marcarse como listo, el nombre del jugador **se ilumina en color verde** tanto en su pantalla como en la de todos los demás integrantes.
- **Regla Estricta de Inicio:**
  - La partida **NO podrá comenzar** bajo ninguna circunstancia a menos que **todos los jugadores presentes hayan marcado su estado como "Listo"**.
  - Una vez cumplida esta condición, el Game Master activa el inicio y la partida transiciona a la fase de preparación de tableros.

---

## 4. Componentes del Juego

### 4.1. El Tablero y las Celdas (Casillas)
- **Tablero:** Cuadrícula bidimensional estructurada según el mapa elegido (por defecto matriz de **7x7** celdas).
- **Celdas / Casillas:**
  - **Coordenadas:** Par `(x, y)` dentro de la matriz.
  - **Valor numérico:** Vacía (`null`) o número entero del **1 al 6**.
  - **Pertenencia a Región:** Asignada a un color específico (las casillas no asignadas no son jugables).

### 4.2. Mapas del Juego
- Existen **4 mapas predefinidos** con configuraciones espaciales, casillas iniciales y distribuciones de regiones únicas.
- **Todos los jugadores en la sala reciben una copia idéntica del mapa seleccionado por el Game Master**, garantizando equidad competitiva.

### 4.3. Dados Compartidos (Tirada Global del Servidor)
- Se emplean **2 dados estándar de 6 caras** (valores del 1 al 6).
- **Mecánica Centralizada:** Los dados **NO** son lanzados individualmente por cada jugador. En cada ronda, **el servidor arroja los dados y envía el resultado idéntico a todos los jugadores de la partida**.
- Todos los participantes juegan esa ronda utilizando los mismos dos valores numéricos.

---

## 5. Fases de la Partida

### Fase 1: Configuración Inicial de Tableros (Setup)
1. Con el mapa ya seleccionado desde el lobby, se inicializa el tablero réplica para cada participante.
2. Cada mapa designa **6 casillas iniciales preestablecidas**.
3. Cada jugador debe colocar en dichas casillas los **6 números únicos** (del 1 al 6, sin repetir) según su preferencia estratégica.
4. Cuando todos completan su setup, el servidor da paso al ciclo de rondas.

### Fase 2: Rondas de Juego (Gameplay Simultáneo con Dados Centralizados)
En cada ronda:
1. **Lanzamiento Global:** El servidor genera el resultado de los 2 dados y lo retransmite simultáneamente a todos los clientes.
2. **Elección Individual del Dado Ancla:**
   - Cada jugador evalúa los dos números y decide libre e individualmente cuál de ellos utilizará como **dado ancla**.
   - El valor elegido como ancla debe coincidir con un número que el jugador **ya tenga escrito en su tablero**.
3. **Colocación del Dado No Ancla:**
   - El valor del segundo dado (no ancla) es el número a ingresar.
   - **Regla de adyacencia:** Debe posicionarse en una celda vacía **ortogonalmente adyacente** (arriba, abajo, izquierda, derecha) a alguna casilla que contenga el número ancla seleccionado.
   - **Regla de región:** La celda seleccionada debe cumplir las restricciones del color de su región.
4. **Pase de Ronda:** Si un jugador no puede o no desea colocar el número, puede pasar su turno (`PassTurn`).
5. **Cierre de Ronda y Puntuaciones:** El servidor recopila las regiones completadas durante la ronda para adjudicar puntos y resolver empates de ronda antes de pasar a la siguiente tirada.

---

## 6. Regiones / Zonas del Tablero

El tablero se divide en **7 tipos de regiones principales** (incluyendo variantes) diferenciadas por su color y reglas de colocación de números para cubrir las mecánicas de los distintos mapas.

### 6.1. Propiedades de cada Región
- **Límite de celdas:** Número fijo de casillas que componen el grupo.
- **Forma y conectividad:** Todas las casillas de una región deben estar conectadas entre sí (adyacencia continua), **excepto la Región Amarilla**, cuyas casillas pueden estar dispersas o aisladas por distintas partes del tablero.
- **Estado de completitud:** Booleano que indica si la región ya tiene todas sus casillas llenas.
- **Validación de reglas:** Método que verifica si un número del 1 al 6 puede ser insertado en base a los números ya existentes en la zona.

### 6.2. Reglas Específicas por Color

| Color / Tipo | Regla de Colocación | Forma / Conectividad |
| :--- | :--- | :--- |
| 🔴 **Rojo** (`TipoRojo`) | **Números únicos:** No se pueden repetir números dentro de la región (todos diferentes). | Casillas continuas / conectadas. |
| 🟡 **Amarillo** (`TipoAmarillo`) | **Números únicos:** No se pueden repetir números dentro de la región (todos diferentes). | **Dispersa:** Puede tener casillas sueltas o separadas en el mapa. |
| 🟣 **Morado** (`TipoMorado`) | **Números idénticos:** Todas las casillas deben llenarse exactamente con el mismo número. | Casillas continuas / conectadas. |
| 🔵 **Azul** (`TipoAzul`) | **Máximo 2 números distintos:** Solo se permite combinar un máximo de dos valores diferentes en toda la zona (ej. solo doses y cuatros). | Casillas continuas / conectadas. |
| 🟢 **Verde** (`TipoVerde`) | **Libre:** Se puede colocar cualquier número del 1 al 6 sin restricciones de repetición. | Casillas continuas / conectadas. |
| ⚪ **Gris** (`TipoGris`) | **Números idénticos:** Todas las casillas dentro de la zona deben llenarse exactamente con el mismo número. | Casillas continuas / conectadas. |
| 🟠 **Naranja (Variante 4-6)** (`TipoNaranjaAlto`) | **Rango Alto:** Solo se permiten colocar números del **4 al 6** (4, 5 o 6). | Casillas continuas / conectadas. |
| 🟠 **Naranja (Variante 1-3)** (`TipoNaranjaBajo`) | **Rango Bajo:** Solo se permiten colocar números del **1 al 3** (1, 2 o 3). | Casillas continuas / conectadas. |

---

## 7. Sistema de Puntuación

Los puntos se consiguen a medida que los jugadores completan regiones a lo largo de la partida. 

### 7.1. Dinámica de Carrera por Puntos
- Al completar el 100% de las casillas de una región, el jugador recibe el puntaje correspondiente.
- **Orden de finalización (1.º, 2.º y 3.er lugar):**
  - El primer jugador de la partida en completar una región específica se lleva la puntuación máxima (**1.er lugar**).
  - El segundo jugador en completar esa misma región recibe la puntuación de **2.º lugar**.
  - El tercer jugador recibe la puntuación de **3.er lugar**.
  - Cualquier jugador subsecuente no recibe puntos por esa región ya agotada.
- **Empates en la misma ronda:** Si dos (o más) jugadores terminan la misma zona dentro de la misma ronda de juego, **ambos reciben la misma puntuación** correspondiente a la posición en disputa (por ejemplo, si ambos la completan en la misma ronda disputando el primer puesto, ambos obtendrán la puntuación completa de 1.er lugar).
- **Feedback visual:** Cuando una jugada esté a punto de completar una región (le falta 1 casilla y la jugada actual es válida), la región se ilumina por completo y muestra en su centro la puntuación que otorgaría.

### 7.2. Tabla de Puntuaciones por Región

| Región | Puntuación 1.er Lugar | Puntuación 2.º Lugar | Puntuación 3.er Lugar |
| :--- | :---: | :---: | :---: |
| 🔴 **Rojo** | 8 pts | 6 pts | 4 pts |
| 🟡 **Amarillo** | 8 pts | 6 pts | 4 pts |
| 🟣 **Morado** | 8 pts | 6 pts | 4 pts |
| 🔵 **Azul** | 8 pts | 6 pts | 4 pts |
| ⚪ **Gris** | 8 pts | 6 pts | 4 pts |
| 🟠 **Naranja (ambas variantes: 1-3 y 4-6)** | 6 pts | 4 pts | 3 pts |
| 🟢 **Verde** | 4 pts | 3 pts | 2 pts |

---

## 8. Fin de la Partida y Declaración de Ganador

- **Condición de Fin:** La partida concluye de inmediato cuando cualquier jugador alcanza **21 o más puntos**.
- **Ganador:** Se proclama ganador al jugador que haya alcanzado los 21 puntos (o la puntuación más alta en la ronda de cierre).
- **Final alternativo:** Si todos los jugadores llenan por completo todas las regiones de sus tableros antes de que alguien alcance 21 puntos, gana el jugador con mayor puntaje acumulado.

---

## 9. Requerimientos Técnicos y de Lógica de Negocio (Dart)

Para el funcionamiento integral del sistema (Cliente y Servidor), se definen las siguientes operaciones, entidades y responsabilidades:

1. **Gestión de Cuentas y Autenticación:**
   - Modelo `Usuario` (`id`, `nombreUsuario`, `passwordHash`, `fechaRegistro`).
   - Servicio de autenticación: registro, login, generación y validación de tokens de sesión.

2. **Gestión de Salas y Red (`Lobby` / `SalaPartida`):**
   - Entidad `SalaPartida`:
     - `codigo`: Cadena numérica única de 5 dígitos (ej. `"48291"`).
     - `gameMasterId`: Identificador del anfitrión de la sala.
     - `mapaSeleccionado`: Índice del mapa elegido (1 al 4).
     - `jugadores`: Lista de participantes (`id`, `nombre`, `esListo`, `esHost`). Límite máximo: 6.
     - `estadoSala`: Esperando, TodosListos, EnSetup, EnJuego, Finalizada.
   - Operaciones de Sala:
     - `unirseASala(codigo, jugador)`: Valida existencia y capacidad (< 6).
     - `expulsarJugador(jugadorId)`: Exclusivo del Game Master.
     - `cambiarEstadoListo(jugadorId, bool listo)`: Alterna el estado (iluminación verde).
     - `iniciarPartida()`: Solo ejecutable si `jugadores.every((j) => j.esListo)` y solicitado por el Game Master.

3. **Motor Centralizado de Rondas y Dados (Servidor):**
   - Generación de tirada aleatoria de 2 dados (1-6) por ronda.
   - Difusión (broadcast) simultánea de los dados a todos los tableros activos.
   - Sincronización y recopilación de jugadas/pases por ronda para adjudicación equitativa de puntos por regiones.

4. **Gestión de Tablero y Regiones (Cliente / Lógica Compartida):**
   - Matriz de `Casilla(x, y, valor)`.
   - `GrupoRegion` y polimorfismo de `Region` (`TipoRojo`, `TipoAmarillo`, `TipoMorado`, `TipoAzul`, `TipoVerde`, `TipoGris`, `TipoNaranjaAlto`, `TipoNaranjaBajo`).
   - Validación de adyacencia ortogonal respecto al ancla y validación de reglas de color.

5. **Ciclo de Estados y Eventos (BLoC):**
   - **`AuthBloc`:** Gestiona estados de `NoAutenticado`, `Autenticando`, `Autenticado`, `ErrorAutenticacion`.
   - **`LobbyBloc`:** Administra la creación de sala, unirse por código de 5 dígitos, selección de mapa por el host, expulsión de participantes, alternancia del estado listo e inicio de partida.
   - **`SetupBloc`:** Administra la colocación de los 6 números iniciales distintos (1-6) en las casillas correspondientes del mapa réplica.
   - **`GamePlayBloc`:** Controla la recepción de la tirada global del servidor, selección individual del ancla (`SelectAnchor`), colocación del número adyacente (`PlaceNumber`), notificación de regiones completadas, pase de turno (`PassTurn`) y verificación de la condición de victoria (21+ puntos).
