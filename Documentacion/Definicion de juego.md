# Definición del Juego: Brilliant

## 1. Visión General
**Brilliant** es un juego de mesa digital de estrategia y colocación de números, diseñado para dispositivos móviles y desarrollado en **Dart** (usando el framework Flutter). 

Está concebido para partidas **multijugador** competitivas por turnos, donde cada jugador compite en tiempo real sobre su propia copia idéntica de un tablero seleccionado, buscando completar regiones y acumular puntos antes que sus contrincantes.

- **Plataforma:** Dispositivos móviles (Android / iOS).
- **Tecnología:** Dart & Flutter (arquitectura con BLoC).
- **Modalidad:** Multijugador por turnos (cada jugador cuenta con su propio tablero independiente).
- **Condición de victoria:** La partida termina en cuanto un jugador alcanza **21 o más puntos**. Gana quien cumpla esta condición primero.

---

## 2. Componentes del Juego

### 2.1. El Tablero y las Celdas (Casillas)
- **Tablero:** Estructurado como una cuadrícula o plano cartesiano bidimensional de dimensiones configurables por mapa (por defecto de **7x7** celdas).
- **Celdas / Casillas:** Objetos atómicos del tablero caracterizados por:
  - **Coordenadas:** Par `(x, y)` dentro de la matriz.
  - **Valor numérico:** Puede estar vacía (`null`) o contener un número entero del **1 al 6**.
  - **Pertenencia a Región:** La mayoría de casillas pertenecen a una región de color específica (las casillas no asignadas a ninguna región no son jugables).

### 2.2. Mapas del Juego
- El juego incluye **4 mapas predefinidos** con diferentes distribuciones espaciales y tamaños de regiones.
- Al iniciar una partida, se selecciona **uno de los 4 mapas**.
- **Todos los jugadores juegan en réplicas exactas del mismo mapa seleccionado**, garantizando equidad y balance competitivo.

### 2.3. Dados
- Se utilizan **2 dados estándar de 6 caras** (valores del 1 al 6) lanzados en cada turno.

---

## 3. Fases de la Partida

### Fase 1: Configuración e Inicio (Setup)
1. **Selección de Mapa:** La mesa o creador de la sala elige uno de los 4 mapas disponibles.
2. **Colocación Inicial de 6 Números:**
   - Cada mapa designa casillas iniciales preestablecidas.
   - Cada jugador debe ingresar **6 números únicos** (del 1 al 6, sin repetir) en dichas casillas específicas de su tablero.
   - Esto establece las bases y puntos de partida numéricos de cada participante.
3. **Inicio del Juego:** Una vez que todos los jugadores han colocado sus 6 números iniciales, la partida comienza oficialmente.

### Fase 2: Ronda y Turno de Juego (Gameplay)
En cada turno de un jugador:
1. **Lanzamiento de dados:** Se tiran los 2 dados (con resultados del 1 al 6).
2. **Selección del Dado Ancla:**
   - El jugador elige uno de los dos dados como su **dado ancla**.
   - El valor resultante del dado ancla debe buscarse entre los números que **ya se encuentran colocados** en su propio tablero.
3. **Colocación del Dado No Ancla:**
   - El valor del **segundo dado (el no ancla)** es el número que el jugador debe escribir en el tablero.
   - **Regla de adyacencia:** El número no ancla debe colocarse en una casilla vacía que sea **ortogonalmente adyacente** (arriba, abajo, izquierda o derecha) a una casilla que contenga el número ancla seleccionado.
   - **Regla de región:** Además de la adyacencia, la casilla destino debe admitir dicho número conforme a las reglas específicas de la región a la que pertenece.
4. **Pase de Turno:** Si el jugador no dispone de casillas válidas para colocar el número resultante o decide no jugar, puede pasar el turno (`PassTurn`). El turno se traslada al siguiente jugador con una nueva tirada de dados.

---

## 4. Regiones / Zonas del Tablero

El tablero se divide en **7 tipos de regiones principales** (incluyendo variantes) diferenciadas por su color y reglas de colocación de números para cubrir las mecánicas de los distintos mapas.

### 4.1. Propiedades de cada Región
- **Límite de celdas:** Número fijo de casillas que componen el grupo.
- **Forma y conectividad:** Todas las casillas de una región deben estar conectadas entre sí (adyacencia continua), **excepto la Región Amarilla**, cuyas casillas pueden estar dispersas o aisladas por distintas partes del tablero.
- **Estado de completitud:** Booleano que indica si la región ya tiene todas sus casillas llenas.
- **Validación de reglas:** Método que verifica si un número del 1 al 6 puede ser insertado en base a los números ya existentes en la zona.

### 4.2. Reglas Específicas por Color

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

## 5. Sistema de Puntuación

Los puntos se consiguen a medida que los jugadores completan regiones a lo largo de la partida. 

### 5.1. Dinámica de Carrera por Puntos
- Al completar el 100% de las casillas de una región, el jugador recibe el puntaje correspondiente.
- **Orden de finalización (1.º, 2.º y 3.er lugar):**
  - El primer jugador de la partida en completar una región específica se lleva la puntuación máxima (**1.er lugar**).
  - El segundo jugador en completar esa misma región recibe la puntuación de **2.º lugar**.
  - El tercer jugador recibe la puntuación de **3.er lugar**.
  - Cualquier jugador subsecuente no recibe puntos por esa región ya agotada.
- **Empates en la misma ronda:** Si dos (o más) jugadores terminan la misma zona dentro de la misma ronda de juego, **ambos reciben la misma puntuación** correspondiente a la posición en disputa (por ejemplo, si ambos la completan en la misma ronda disputando el primer puesto, ambos obtendrán la puntuación completa de 1.er lugar).
- **Feedback visual:** Cuando una jugada esté a punto de completar una región (le falta 1 casilla y la jugada actual es válida), la región se ilumina por completo y muestra en su centro la puntuación que otorgaría.

### 5.2. Tabla de Puntuaciones por Región

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

## 6. Fin de la Partida y Declaración de Ganador

- **Condición de Fin:** La partida concluye de inmediato cuando cualquier jugador alcanza **21 o más puntos**.
- **Ganador:** Se proclama ganador al jugador que haya alcanzado los 21 puntos (o la puntuación más alta en la ronda de cierre).
- **Final alternativo:** Si todos los jugadores llenan por completo todas las regiones de sus tableros antes de que alguien alcance 21 puntos, gana el jugador con mayor puntaje acumulado.

---

## 7. Requerimientos Técnicos y de Lógica de Negocio (Dart)

Para el funcionamiento del motor de juego se definen las siguientes operaciones y entidades fundamentales:

1. **Gestión de Regiones (`GrupoRegion` y `Region`):**
   - `estaLlena`: Retorna `true` si todas las casillas de la región contienen un valor no nulo.
   - `esPosibleAgregar(List<int> actuales, int posible)`: Valida la regla específica según el color.
   - `puedeAgregar(int valor)`: Determina si la región no está llena y si el valor es admisible.
   - `agregarValor(Casilla casilla, int valor)`: Inserta el valor validando que esté entre 1 y 6, pertenencia a la casilla y consistencia con las reglas.
   - `validarForma()`: Comprueba la adyacencia y continuidad de las casillas del grupo (excepto para `TipoAmarillo`).

2. **Gestión del Tablero (`Tablero`):**
   - Matriz de `Casilla(x, y, valor)`.
   - `clonar()`: Duplica de forma independiente el tablero y sus regiones para inicializar el estado individual de cada jugador en partidas multijugador.
   - Detección de casillas adyacentes ocupadas y cálculo de casillas válidas a partir del ancla seleccionada.

3. **Ciclo de Estados y Eventos (BLoC):**
   - **`SetupBloc`:** Administra la colocación de los 6 números iniciales distintos (1-6) en las casillas correspondientes del mapa.
   - **`GamePlayBloc`:** Controla la tirada de dados, elección del ancla (`SelectAnchor`), colocación del número adyacente (`PlaceNumber`), asignación de puntuaciones por orden de llegada, pase de turno (`PassTurn`) y verificación de la condición de victoria (21+ puntos).
