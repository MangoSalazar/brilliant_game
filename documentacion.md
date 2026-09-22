# Documentación de Cambios y Progreso

## ¿Qué hicimos hoy?

Hoy nos enfocamos en reestructurar las clases y la lógica principal del juego en Dart para que estuvieran alineadas exactamente con el documento de diseño **"Definicion de juego.md"**.

Los cambios principales incluyeron:
1.  **Refactorización del Tablero, Regiones y Celdas**: Pasamos de una implementación simplificada a un diseño más robusto orientado a objetos.
2.  **Implementación estricta de las reglas del juego**: Validamos que las inserciones de números dependan del color (tipo) de cada región.
3.  **Creación de Pruebas Unitarias**: Actualizamos y creamos nuevas pruebas para asegurar que cada región responde adecuadamente a intentos válidos e inválidos de insertar números.

## ¿Cómo lo hicimos?

### 1. Análisis del Documento de Diseño
Primero, se leyó el documento "Definicion de juego.md" para extraer los requerimientos técnicos y reglas:
-   **Tablero**: De dimensiones 7x7 por defecto.
-   **Celdas**: Poseen coordenadas y aceptan valores del 1 al 6.
-   **Regiones**:
    -   Tienen *puntaje*, *límite fijo de celdas*, *estado (lleno o no)*, y un *color*.
    -   Existen tres funciones esenciales solicitadas: validar si está llena, insertar un número y cambiar el estado a lleno.
-   **Reglas por Color**:
    -   **Rojo y Amarillo**: Los números no se pueden repetir.
    -   **Morado**: Todos los números deben ser idénticos.
    -   **Azul**: Se permiten un máximo de dos números distintos.
    -   **Verde**: Cualquier número es válido.

### 2. Implementación en Código (`lib/brilliant_game.dart`)
Se modificó el modelo de datos:
-   **`Coordinate`**: Nueva clase para manejar posiciones `(x, y)` en vez de un simple ID.
-   **`Cell`**: Ahora almacena su `Coordinate` y su `value`.
-   **`Region`**: 
    -   Se agregaron los campos `score`, `cellLimit` e `_isFull`.
    -   Se implementaron las funciones:
        -   `isRegionFull()`: Devuelve si la región está llena.
        -   `updateFullState()`: Evalúa la cantidad de celdas y si todas tienen valor para actualizar el estado de la región.
        -   `insertNumber(Coordinate, int)`: Valida la regla por color y, de ser válida, asigna el número a la celda.
    -   Se actualizaron los casos de validación del `switch(color)` usando los métodos de búsqueda sobre la colección interna de celdas de la región.

### 3. Ajuste de las Pruebas Unitarias (`test/brilliant_game_test.dart`)
Para asegurar la calidad del código, las pruebas unitarias se reescribieron utilizando las nuevas clases:
-   Se instanciaron regiones independientes (`redRegion`, `blueRegion`, `greenRegion`, etc.) pre-pobladas con celdas iniciales.
-   Se comprobó el estado de llenado con `isRegionFull()`.
-   Se añadieron aserciones (assets/expects) comprobando los límites:
    -   Por ejemplo, evitar ingresar un tercer número distinto en una región Azul (`blueRegion`).
    -   Evitar repetir un número en la región Roja o Amarilla.

### 4. Adaptación del Archivo Ejecutable (`bin/brilliant_game.dart`)
Actualizamos la simulación de consola principal del juego para que instancie las regiones y el tablero con el nuevo formato `Coordinate`, lo que sirvió para confirmar visualmente en consola que las reglas del sistema están operativas de forma correcta.

## Conclusión
La lógica fundamental del juego Brilliant está ahora sincronizada con el documento base, las reglas por color son respetadas de manera estricta y se cuenta con pruebas automatizadas que respaldan futuras modificaciones al sistema.
