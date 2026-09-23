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


