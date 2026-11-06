/// Constantes globales y configuraciones para Brilliant Game.
abstract final class ConstantesJuego {
  // ==========================================
  // Reglas Generales y Condiciones de Victoria
  // ==========================================
  /// Puntuación mínima requerida para declarar la victoria y terminar la partida.
  static const int puntosParaGanar = 21;

  /// Cantidad de dados lanzados por turno.
  static const int cantidadDados = 2;

  /// Valor mínimo obtenido en un dado.
  static const int valorDadoMinimo = 1;

  /// Valor máximo obtenido en un dado.
  static const int valorDadoMaximo = 6;

  /// Cantidad de números que cada jugador debe ingresar durante la fase de preparación.
  static const int cantidadValoresIniciales = 6;

  /// Total de mapas predefinidos disponibles para jugar.
  static const int totalMapas = 4;

  // ==========================================
  // Parámetros de Salas y Multijugador
  // ==========================================
  /// Cantidad máxima de jugadores permitidos por sala.
  static const int maxJugadoresPorSala = 6;

  /// Longitud exacta en dígitos del código de acceso a la sala.
  static const int longitudCodigoSala = 5;

  // ==========================================
  // Dimensiones del Tablero
  // ==========================================
  static const int anchoTableroPorDefecto = 7;
  static const int altoTableroPorDefecto = 7;

  // ==========================================
  // Puntuaciones por Región y Posición (1.º, 2.º y 3.er lugar)
  // ==========================================
  /// Puntuación para Rojo, Amarillo, Morado, Azul y Gris.
  static const Map<int, int> puntuacionesEstandar = {
    1: 8,
    2: 6,
    3: 4,
  };

  /// Puntuación para ambas variantes de la región Naranja (1-3 y 4-6).
  static const Map<int, int> puntuacionesNaranja = {
    1: 6,
    2: 4,
    3: 3,
  };

  /// Puntuación para la región Verde.
  static const Map<int, int> puntuacionesVerde = {
    1: 4,
    2: 3,
    3: 2,
  };

  // ==========================================
  // Textos Descriptivos de las Regiones
  // ==========================================
  static const String descRegionRoja = 'Todos los números deben de ser distintos';
  static const String descRegionAmarilla = 'Todos los números deben de ser distintos (casillas dispersas)';
  static const String descRegionMorada = 'Todos los números deben ser idénticos';
  static const String descRegionAzul = 'Máximo dos números diferentes por zona';
  static const String descRegionVerde = 'Se puede colocar cualquier número';
  static const String descRegionGris = 'Todos los números deben ser idénticos';
  static const String descRegionNaranjaAlto = 'Solo se permiten números del 4 al 6';
  static const String descRegionNaranjaBajo = 'Solo se permiten números del 1 al 3';

  // ==========================================
  // Textos de Validación y Mensajes de Error
  // ==========================================
  static const String errorEligeAncla = 'Elige primero un dado como ancla.';
  static String errorCasillaInvalida(int valor) => 'No puedes colocar el $valor en esa casilla.';
  static const String errorRangoDado = 'El valor debe estar entre 1 y 6.';
  static const String errorValoresInicialesDuplicados = 'Los 6 valores iniciales deben ser todos distintos entre sí.';
  static const String errorCasillaNoPertenece = 'La casilla no pertenece a esta región';
  static const String errorReglasRegion = 'Valor no válido para las reglas de esta región';
  static const String errorFormaRegion = 'Las casillas de esta región deben estar conectadas, excepto si es amarilla';
  static const String errorCasillaSuperpuesta = 'La casilla ya pertenece a otra región';
  static const String errorCoordenadasFuera = 'Coordenadas fuera del tablero';
  static const String errorSalaLlena = 'La sala ya alcanzó su capacidad máxima de 6 jugadores.';
  static const String errorSalaNoExiste = 'No se encontró ninguna sala con ese código.';
  static const String errorCodigoInvalido = 'El código de sala debe tener exactamente 5 dígitos.';
  static const String errorJugadoresNoListos = 'No todos los jugadores están listos para iniciar la partida.';
  static const String errorSoloHostInicia = 'Solo el Game Master puede iniciar la partida.';
  static const String errorSoloHostExpulsa = 'Solo el Game Master puede expulsar a otros jugadores.';
  static const String errorCredencialesInvalidas = 'Usuario o contraseña incorrectos.';

  // ==========================================
  // Textos de Estado del Juego
  // ==========================================
  static const String msgPartidaTerminada = '¡Partida terminada! Un jugador ha alcanzado la victoria.';
  static const String msgTurnoPasado = 'Turno pasado.';
  static const String msgJugadorExpulsado = 'Has sido expulsado de la sala.';
}
