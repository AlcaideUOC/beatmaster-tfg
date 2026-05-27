# BeatMaster

BeatMaster es un videojuego musical orientado al aprendizaje y práctica de la batería y la percusión mediante instrumentos electrónicos y entrada MIDI en tiempo real.

El proyecto ha sido desarrollado como Trabajo Fin de Grado del Grado en Técnicas de Interacción Digital y Multimedia de la Universitat Oberta de Catalunya (UOC).

---

## Descripción del proyecto

BeatMaster explora la posibilidad de utilizar la ejecución instrumental real como mecánica principal dentro de un videojuego musical. A diferencia de otros rhythm games basados en controladores simplificados, el sistema propone utilizar una batería electrónica o pads de percusión conectados mediante MIDI para interactuar directamente con el juego.

La ejecución rítmica del usuario se interpreta como eventos dentro del sistema interactivo, permitiendo transformar la práctica musical en una experiencia lúdica basada en retos, retroalimentación inmediata y progresión.

El sistema permite grabar interpretaciones sobre canciones en formato MP3 y reutilizarlas posteriormente como niveles jugables mediante distintos modos visuales.

El objetivo principal del proyecto es investigar cómo las mecánicas de videojuego pueden contribuir a mejorar la motivación y la práctica sostenida en el aprendizaje de la batería.

---

## Objetivos del proyecto

Los objetivos principales del proyecto son:

- Diseñar un sistema interactivo basado en ejecución rítmica real.
- Utilizar instrumentos electrónicos de percusión como interfaz de control.
- Implementar detección y procesamiento de eventos MIDI en tiempo real.
- Integrar la práctica musical dentro de una estructura de videojuego.
- Explorar el potencial de la gamificación aplicada al aprendizaje musical.
- Permitir la grabación y reutilización de patrones rítmicos jugables.
- Desarrollar distintos modos de representación visual para la interpretación musical.

---

## Funcionalidades implementadas

La versión actual de BeatMaster incluye:

- Carga de canciones en formato MP3.
- Grabación de sesiones de percusión sincronizadas con audio.
- Guardado de sesiones en archivos de texto.
- Reproducción de sesiones grabadas.
- Modo de juego por carriles estilo rhythm game.
- Modo de visualización de notas.
- Sistema de puntuación, aciertos, errores y combo.
- Registro de resultados y estadísticas.
- Compatibilidad con teclado.
- Compatibilidad con dispositivos MIDI.
- Configuración dinámica de pads MIDI.
- Reproducción de sonidos de batería mediante samples WAV.

---

## Tecnologías utilizadas

El prototipo se ha desarrollado utilizando:

- Processing 4.
- Java.
- MIDI (Musical Instrument Digital Interface).
- `javax.sound.midi`.
- Minim.
- Instrumentos electrónicos de percusión.
- Procesamiento de eventos rítmicos en tiempo real.

---

## Versión Gold Master

La versión final ejecutable del videojuego está disponible en la sección **Releases** del repositorio.

Release final:

**BeatMaster Gold Master**

### Ejecución de la Gold Master

1. Descargar el archivo `BeatMaster_GoldMaster_Windows.zip`.
2. Descomprimir el contenido del ZIP.
3. Ejecutar `BeatMaster.exe`.

No requiere instalación adicional.

---

## Estructura del repositorio

```text
beatmaster-tfg/
├── data/
│   ├── bombo.wav
│   ├── caja.wav
│   ├── charles.wav
│   └── plato.wav
├── songs/
│   ├── BEATMASTER.mp3
│   └── BEATMASTER-Drumless.mp3
├── BEATMASTER.pde
├── README.md
└── LICENSE
```

---

## Recursos incluidos en el repositorio

### Código fuente

- `BEATMASTER.pde`: archivo principal del proyecto desarrollado en Processing.

### Recursos sonoros

La carpeta `data/` contiene los sonidos individuales utilizados por el videojuego:

- `bombo.wav`
- `caja.wav`
- `charles.wav`
- `plato.wav`

Estos sonidos proceden de librerías gratuitas de audio y se utilizan como efectos sonoros dentro del prototipo.

### Canciones incluidas

La carpeta `songs/` contiene dos archivos MP3 utilizados para las pruebas del proyecto:

- `BEATMASTER.mp3`: versión completa de la canción.
- `BEATMASTER-Drumless.mp3`: versión sin batería, destinada a la interpretación o grabación de la parte de percusión.

La canción ha sido compuesta y producida por Víctor Alcaide Peletero y Mike Martínez específicamente para este proyecto académico.

### Ejecutable final

La versión Gold Master se distribuye mediante el archivo:

`BeatMaster_GoldMaster_Windows.zip`

Disponible en la sección **Releases** del repositorio.

El ZIP incluye:

- ejecutable de Windows;
- librerías necesarias;
- recursos de audio;
- canciones de prueba.

---

## Controles

### Menú principal

- `1`: grabar sesión sobre MP3.
- `2`: jugar sesión en modo carriles.
- `3`: jugar sesión en modo notas.
- `4`: resultados.
- `5`: activar o desactivar sonidos.
- `6`: configurar pads MIDI.

### Durante la grabación o partida

- `A`: bombo.
- `S`: caja.
- `D`: charles.
- `F`: plato.
- `ESPACIO`: iniciar grabación o pausar.
- `G`: detener y guardar grabación.
- `ESC`: volver, cancelar o finalizar.

---

## Requisitos

### Para ejecutar el código fuente

- Processing 4.
- Librería Minim.
- Java MIDI API (`javax.sound.midi`).
- Opcional: batería electrónica o controlador MIDI compatible.

### Para ejecutar la versión Gold Master

- Sistema operativo Windows.
- No requiere instalación.
- Opcional: dispositivo MIDI compatible.

---

## Cómo ejecutar el código fuente

1. Descargar o clonar el repositorio.
2. Abrir `BEATMASTER.pde` con Processing.
3. Verificar que las carpetas `data/` y `songs/` están disponibles.
4. Ejecutar el sketch desde Processing.
5. Opcionalmente, conectar un dispositivo MIDI antes de iniciar el programa.

---

## Estado actual del proyecto

El proyecto se encuentra en estado funcional y corresponde a la versión Gold Master desarrollada para la entrega final del Trabajo Fin de Grado.

La versión actual implementa las funcionalidades principales previstas en la fase de diseño conceptual, incluyendo grabación, reproducción, interacción MIDI y modos jugables basados en ejecución rítmica.

---

## Contexto académico

Este repositorio forma parte del Trabajo Fin de Grado titulado:

**BeatMaster: Videojuego musical para el aprendizaje de la batería mediante instrumentos electrónicos de percusión**

Grado en Técnicas de Interacción Digital y Multimedia  
Universitat Oberta de Catalunya (UOC)

Autor: **Víctor Alcaide Peletero**

---

## Licencia

El código fuente del proyecto BeatMaster se distribuye bajo licencia MIT.

La memoria académica asociada al proyecto se distribuye bajo licencia Creative Commons Reconocimiento-NoComercial 4.0 Internacional (CC BY-NC 4.0).
