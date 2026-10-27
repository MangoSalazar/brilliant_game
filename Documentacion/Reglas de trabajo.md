# Reglas de Trabajo y Estándares de Desarrollo: Brilliant Game

Este documento establece las directrices de ingeniería de software, arquitectura, control de versiones y flujo de trabajo que rigen el desarrollo de **Brilliant Game**.

---

## 1. Principios de Diseño y Arquitectura (SOLID)

Todo el código de la lógica del juego debe estructurarse siguiendo estrictamente los principios **SOLID**:

1. **S - Principio de Responsabilidad Única (Single Responsibility Principle - SRP):**
   - Cada clase, módulo o BLoC debe tener una única razón para cambiar.
   - *Ejemplo:* `Region` y sus subtipos se encargan únicamente de las reglas de validación de color y puntuación; `Tablero` gestiona exclusivamente la matriz de celdas y la adyacencia espacial; `ConstantesJuego` centraliza los valores y mensajes estáticos.

2. **O - Principio de Abierto/Cerrado (Open/Closed Principle - OCP):**
   - Las entidades deben estar abiertas a la extensión pero cerradas a la modificación.
   - *Ejemplo:* Si se añaden nuevas regiones o mecánicas (como Gris o Naranja), se crean nuevas subclases de `Region` sin necesidad de reescribir ni romper la lógica central de `GrupoRegion` o `Tablero`.

3. **L - Principio de Sustitución de Liskov (Liskov Substitution Principle - LSP):**
   - Cualquier subclase debe poder sustituir a su clase base sin alterar el comportamiento esperado del sistema.
   - *Ejemplo:* Cualquier instancia de `Region` (`TipoRojo`, `TipoGris`, `TipoNaranjaAlto`, etc.) puede ser utilizada indistintamente por el motor del tablero para validar jugadas mediante `esPosibleAgregar`.

4. **I - Principio de Segregación de Interfaces (Interface Segregation Principle - ISP):**
   - Preferir interfaces pequeñas y específicas frente a interfaces monolíticas con métodos que no todas las clases implementadoras necesitan.
   - Mantener contratos concisos y desacoplados.

5. **D - Principio de Inversión de Dependencias (Dependency Inversion Principle - DIP):**
   - Los módulos de alto nivel no deben depender de módulos de bajo nivel; ambos deben depender de abstracciones.
   - Las clases de negocio (`GrupoRegion`, `Tablero`) interactúan con abstracciones (`Region`) y reciben sus dependencias en lugar de instanciarlas rígidamente.

---

## 2. Código Limpio y Eficaz (Clean Code)

- **Legibilidad y Nomenclatura:** Nombres claros, descriptivos y en español coherente para entidades de negocio y reglas del juego.
- **Sin Dependencias Innecesarias:** Mantener la lógica interna del juego (modelos, BLoCs, validaciones) 100% pura y desacoplada de paquetes visuales o de interfaz de usuario (UI) hasta que se decida abordar la capa de presentación.
- **Centralización:** Cero "números mágicos" o cadenas de texto duplicadas en la lógica de negocio; todo debe referenciarse a través de `ConstantesJuego`.
- **Calidad y Verificación:** Toda nueva regla, mecánica o refactorización debe contar con sus respectivas pruebas unitarias en la carpeta `test/`.

---

## 3. Control de Versiones (Git)

- **Commits atómicos por implementación:** Se realizará un commit estructurado y descriptivo inmediatamente después de completar cada funcionalidad, ajuste o refactorización.
- **Formato de mensajes de commit:**
  - `feat: ...` para nuevas funcionalidades o reglas.
  - `refactor: ...` para mejoras de código y separación de responsabilidades.
  - `docs: ...` para cambios en documentación o definiciones de juego.
  - `test: ...` para adición o actualización de pruebas unitarias.

---

## 4. Protocolo Obligatorio de Cierre de Sesión

Cuando el usuario indique explícitamente que la sesión de trabajo ha concluido (por ejemplo: *"acabamos con la sesión"*, *"terminamos por hoy"*, *"cerramos sesión"*), se ejecutarán de forma automática y secuencial los siguientes pasos:

1. **Commit de cambios pendientes:** Confirmar y registrar en Git todos los archivos modificados o agregados hasta el momento con un mensaje descriptivo.
2. **Actualización de contexto:** Documentar en el archivo `Documentacion/Contexto de conversaciones.md` el resumen de lo realizado, decisiones de diseño tomadas, estado actual del repositorio y siguientes pasos pendientes.
3. **Push al repositorio remoto:** Ejecutar `git push origin <rama>` para sincronizar y respaldar todo el progreso en el repositorio remoto.
