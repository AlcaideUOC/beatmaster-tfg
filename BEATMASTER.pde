import javax.sound.midi.*;
import ddf.minim.*;
import java.io.File;
import java.util.Date;
import java.text.SimpleDateFormat;


// Trabajo Fin de Grado
// UOC 2026
// Víctor Alcaide Peletero
// Este es mi proyecto BeatMaster. La idea es un videojuego musical
// similar al Guitar Hero pero para batería y percusión.
//
// Funcionalidades principales:
//   1. Cargo una canción en MP3.
//   2. Grabo los golpes que voy dando mientras suena.
//   3. Luego puedo jugar esa grabación en dos modos distintos.
//   4. Muestra las estadísticas grabadas.
//   5. Muestra la configuración del instrumento.
//
// Lo guardo todo en un TXT, en un futuro se podría hacer un MIDI que pudiera ser intercambiable.
// En cada línea pongo el instrumento, la fuerza y el momento del golpe.
// Así es fácil de leer si abro el archivo con el bloc de notas.



// Aquí pongo las "pantallas" del juego como números.
// Números sueltos por el código (así se entiende mejor qué significan).
final int MENU = 0;
final int RECORD_READY = 1;
final int RECORDING = 2;
final int PLAY_HERO = 3;
final int PLAY_NOTES = 4;
final int PAUSED = 5;
final int ENTER_NAME = 6;
final int RESULTS = 7;
final int LEARN_MIDI = 8;

int estado = MENU;
int estadoPrevio = MENU;          // Lo uso para volver después de la pausa.



// Variables del audio.
// Minim es la librería que usamos para sonido.
Minim minim;
AudioPlayer songPlayer;           // La canción MP3.

// Los cuatro sonidos de batería que se oyen al pulsar teclas o pads.
AudioSample sonidoBombo;
AudioSample sonidoCaja;
AudioSample sonidoCharles;
AudioSample sonidoPlato;

boolean sonidosActivos = false;   // Si está en false, no suenan los samples.



// Variables del MIDI.
// Esto es para conectar el HandSonic (la batería electrónica que utilizo como prueba).
MidiDevice midiInputDevice;
Receiver midiReceiver;

// Estas variables me sirven sobre todo para depurar y ver
// qué está llegando por MIDI mientras pruebo.
String ultimoMidiTexto = "Sin golpes MIDI recibidos";
int ultimaNotaRaw = -1;
int ultimaNotaMapeada = -1;
int ultimaVelocidadMidi = 0;
int ultimoCanalMidi = -1;
int ultimoMidiFrame = -1000;

// El HandSonic no siempre manda las mismas notas que la batería General MIDI.
// Por eso guardo las notas reales que envía cada pad y luego las traduzco.
// Si pruebo otro instrumento puede que tenga que cambiar estas notas.
int RAW_BOMBO   = 36;
int RAW_CAJA    = 38;
int RAW_CHARLES = 46;
int RAW_PLATO   = 49;

// Esto es para el "modo aprender": el usuario toca los pads en orden
// y yo voy guardando qué nota envía cada uno.
String[] learnTargets = {"BOMBO", "CAJA", "CHARLES", "PLATO"};
int learnStep = 0;



// Rutas de archivos y listas de datos.
String mp3Path = "";
String sessionPath = "";
String resultsFilePath = "";

// Lista con los golpes que estoy grabando ahora mismo.
ArrayList<DrumEvent> recordedEvents = new ArrayList<DrumEvent>();

// Lista con los golpes que cargo desde un TXT para jugar.
ArrayList<DrumEvent> loadedEvents = new ArrayList<DrumEvent>();

// Lista con los resultados anteriores guardados en disco.
ArrayList<GameResult> savedResults = new ArrayList<GameResult>();

boolean songLoaded = false;
boolean sessionLoaded = false;



// Variables del juego en sí.

// La línea amarilla en la que hay que pulsar (modo carriles).
float hitLineY = 585;

// Arriba y abajo de los carriles, las notas caen por aquí.
float laneTopY = 185;
float laneBottomY = 585;

// Cuánto tiempo antes aparece una nota en pantalla en el modo carriles.
// Si lo subo mucho, las notas van muy lentas. Si lo bajo, casi no las ves venir.
int leadTimeMs = 2200;

// En el modo notas lo pongo al doble para que se vean con calma.
// Cuando lo tenía igual al modo carriles, no daba tiempo a leer las notas.
int leadTimeNotesMs = 4400;

// Margen de tiempo en milisegundos para considerar que has acertado.
// Si pulsas con menos de 120 ms de diferencia, te lo cuento como acierto.
int hitWindowMs = 120;

// Aquí apunto si cada nota cargada ya está resuelta (acertada o fallada).
// Así no la cuento dos veces.
boolean[] noteResolved;



// Estadísticas de la partida.
int score = 0;
int combo = 0;
int maxCombo = 0;
int hits = 0;
int misses = 0;
int wrongInputs = 0;          // Pulsaciones que no coinciden con ninguna nota.

String feedbackText = "LISTO";  // Texto grande tipo "ACIERTO" o "MISS".
int feedbackColor;

String inputPlayerName = "";    // Lo que va escribiendo el jugador al acabar.
String currentModeName = "";
String currentSessionName = "";



// Cosas del aspecto visual.
PFont fontMain;
String warningLine = "";        // Mensaje rápido abajo (tipo "MP3 cargado").

// Colores que uso por todo el código. Lo dejo arriba para cambiarlos rápido.
int colFondo = color(0, 0, 0);
int colPanel = color(80, 85, 105);
int colTexto = color(240, 240, 255);
int colTextoSuave = color(170, 180, 220);
int colAcento = color(255, 60, 130);
int colLineaGolpe = color(255, 220, 80);

// Lista de efectos visuales (los círculos que aparecen cuando aciertas).
ArrayList<HitEffect> hitEffects = new ArrayList<HitEffect>();

// Guardo en qué frame se pulsó por última vez cada carril.
// Así puedo iluminarlo durante unos frames después del golpe.
// 0=bombo, 1=caja, 2=charles, 3=plato.
int[] laneLastPressedFrame = {-1000, -1000, -1000, -1000};

// Cuánto dura encendido el carril después de pulsar (en frames).
int laneLightDuration = 12;



// Notas MIDI internas que usa mi juego.
// Estas no se cambian, son las "ideales" según la batería General MIDI.
// Lo que cambia es el mapeo desde lo que envía el HandSonic.
int MIDI_BOMBO   = 36;
int MIDI_CAJA    = 38;
int MIDI_CHARLES = 46;
int MIDI_PLATO   = 49;



// El setup se ejecuta una sola vez al empezar.
void setup() {
  size(1366, 768);
  surface.setTitle("BeatMaster");
  smooth(4);

  // Cargo la fuente y la pongo por defecto para todos los textos.
  fontMain = createFont("Arial", 18);
  textFont(fontMain);

  feedbackColor = colTexto;
  minim = new Minim(this);

  cargarSonidosBateria();

  // Aquí creo la ruta donde guardo los resultados.
  // sketchPath devuelve la carpeta del propio proyecto.
  resultsFilePath = sketchPath("resultados_beatmaster.tsv");
  loadSavedResults();

  // Intento conectarme al MIDI nada más arrancar.
  conectarMidiAutomatico();
}



// El draw se ejecuta muchas veces por segundo.
// Según el estado, dibujo una pantalla u otra.
void draw() {
  background(colFondo);

  if (estado == MENU) {
    drawMenu();
  } else if (estado == RECORD_READY) {
    drawRecordReady();
  } else if (estado == RECORDING) {
    updateRecording();
    drawRecording();
  } else if (estado == PLAY_HERO) {
    updatePlaying();
    drawHeroMode();
  } else if (estado == PLAY_NOTES) {
    updatePlaying();
    drawNotesMode();
  } else if (estado == PAUSED) {
    drawPaused();
  } else if (estado == ENTER_NAME) {
    drawEnterName();
  } else if (estado == RESULTS) {
    drawResultsScreen();
  } else if (estado == LEARN_MIDI) {
    drawLearnMidi();
  }

  // El pie de pantalla se dibuja siempre, da igual el estado.
  drawFooter();
}



// Carga de sonidos.
void cargarSonidosBateria() {
  // Lo meto en try-catch por si los archivos no están en la carpeta data.
  // Si no funciona, al menos no se cierra el programa entero.
  try {
    sonidoBombo   = minim.loadSample("bombo.wav", 512);
    sonidoCaja    = minim.loadSample("caja.wav", 512);
    sonidoCharles = minim.loadSample("charles.wav", 512);
    sonidoPlato   = minim.loadSample("plato.wav", 512);
  } catch (Exception e) {
    println("No se pudieron cargar los sonidos de batería.");
  }
}

void reproducirSonido(int note) {
  // Si los sonidos están desactivados desde el menú, no hago nada.
  if (!sonidosActivos) return;

  // Compruebo qué sample me toca según la nota.
  // El "trigger" sirve para que el sonido pueda solaparse con el siguiente.
  if (note == MIDI_BOMBO && sonidoBombo != null) sonidoBombo.trigger();
  else if (note == MIDI_CAJA && sonidoCaja != null) sonidoCaja.trigger();
  else if (note == MIDI_CHARLES && sonidoCharles != null) sonidoCharles.trigger();
  else if (note == MIDI_PLATO && sonidoPlato != null) sonidoPlato.trigger();
}



// Pantalla del menú principal.
void drawMenu() {
  textAlign(CENTER, CENTER);

  fill(colAcento);
  textSize(56);
  text("BEATMASTER", width/2, 90);

  fill(colTexto);
  textSize(24);
  text("Videojuego musical con grabación, juego por carriles y pentagrama", width/2, 140);

  drawPanel(180, 200, width-360, 340);

  textAlign(LEFT, TOP);
  fill(colTexto);
  textSize(28);

  // Voy bajando la "y" cada línea con dy. Así si quiero añadir otra opción
  // más adelante solo tengo que copiar y pegar otro text.
  float x = 250;
  float y = 245;
  float dy = 50;

  text("[1] Grabar sesión sobre MP3", x, y); y += dy;
  text("[2] Jugar sesión en modo carriles", x, y); y += dy;
  text("[3] Jugar sesión en modo notas", x, y); y += dy;
  text("[4] Resultados", x, y); y += dy;
  text("[6] Configurar pads MIDI del HandSonic", x, y); y += dy;

  String estadoSonido = sonidosActivos ? "ACTIVADO" : "DESACTIVADO";
  text("[5] Sonidos al pulsar teclas: " + estadoSonido, x, y);

  fill(colTextoSuave);
  textSize(18);
  text("Teclado: A = bombo, S = caja, D = charles, F = plato", 250, 555);

  fill(colAcento);
  textSize(18);
  text("Sesión cargada: " + (sessionLoaded ? fileNameOnly(sessionPath) : "ninguna"), 250, 605);

  // Información para saber si el MIDI está conectado o no.
  fill(colTexto);
  text("Dispositivo MIDI: " + (midiInputDevice != null ? midiInputDevice.getDeviceInfo().getName() : "sin entrada MIDI"), 250, 635);
  text("Último MIDI: " + ultimoMidiTexto, 250, 665);
  text("Resultados guardados: " + savedResults.size(), 250, 695);
}



// Pantalla previa a grabar. Aquí ya está el MP3 pero no he pulsado todavía ESPACIO.
void drawRecordReady() {
  drawTitle("Preparado para grabar sesión");
  drawPanel(160, 180, width-320, 300);

  fill(colTexto);
  textAlign(CENTER, CENTER);
  textSize(24);
  text("MP3 cargado: " + fileNameOnly(mp3Path), width/2, 260);

  textSize(20);
  text("Pulsa [ESPACIO] para empezar a grabar", width/2, 340);
  text("Pulsa [ESC] para volver al menú", width/2, 385);
}

void startRecording() {
  // Sin canción no puedo grabar nada, así que aviso y salgo.
  if (songPlayer == null) {
    warningLine = "No hay MP3 cargado.";
    return;
  }

  // Limpio la lista por si había una grabación anterior.
  recordedEvents.clear();

  // Pongo la canción desde el principio.
  songPlayer.pause();
  songPlayer.rewind();
  songPlayer.play();

  feedbackText = "REC";
  feedbackColor = colAcento;
  estado = RECORDING;
}

void updateRecording() {
  if (songPlayer == null) return;

  // Si la canción ha llegado al final, paro la grabación sola.
  // Resto 20 ms por si acaso, porque a veces "position" no llega al "length" exacto.
  if (!songPlayer.isPlaying() && songPlayer.position() >= songPlayer.length()-20) {
    stopRecording(false);
  }
}

void drawRecording() {
  drawTitle("Grabando interpretación");
  drawPanel(80, 120, width-160, 520);

  // Barra de progreso de la canción.
  // Calculo en qué porcentaje va.
  float progress = 0;
  if (songPlayer != null && songPlayer.length() > 0) {
    progress = constrain((float)songPlayer.position() / (float)songPlayer.length(), 0, 1);
  }

  fill(38, 39, 38);
  rect(140, 200, width-280, 24, 8);
  fill(colAcento);
  rect(140, 200, (width-280)*progress, 24, 8);

  fill(colTexto);
  textAlign(CENTER, CENTER);
  textSize(22);
  text(fileNameOnly(mp3Path), width/2, 160);

  textSize(18);
  text(msToClock(songPlayer != null ? songPlayer.position() : 0) + " / " + msToClock(songPlayer != null ? songPlayer.length() : 0), width/2, 250);

  // Hago que el círculo rojo de REC parpadee usando sin(frameCount).
  // Así parece una luz que late.
  fill(255, 60, 130, 220 + 35*sin(frameCount*0.2));
  ellipse(width/2, 320, 24, 24);

  fill(colTexto);
  textSize(26);
  text("REC", width/2, 360);

  textSize(18);
  fill(colTextoSuave);
  text("Eventos grabados: " + recordedEvents.size(), width/2, 420);
  text("Pulsa [G] para detener y guardar", width/2, 455);
  text("Pulsa [ESC] para detener sin guardar", width/2, 485);

  // Pinta una timeline abajo con marcas de cada golpe que llevo.
  drawRecordingTimeline(150, 560, width-300, 40);
}

void stopRecording(boolean askToSave) {
  stopSongIfAny();
  estado = MENU;

  // Si pidió guardar y al menos hay un golpe, abro el diálogo de guardar.
  if (askToSave && recordedEvents.size() > 0) {
    selectOutput("Guardar sesión TXT", "onSaveSessionTxt");
  } else {
    warningLine = "Grabación detenida.";
  }
}



// Modo carriles (parecido al Guitar Hero clásico).
void startHeroMode() {
  // Compruebo que tengo lo necesario para empezar.
  if (!songLoaded || !sessionLoaded || loadedEvents.size() == 0) {
    warningLine = "Necesitas cargar una sesión válida.";
    return;
  }

  resetGameStats();
  prepareNoteResolved();
  hitEffects.clear();

  currentModeName = "Carriles";
  currentSessionName = fileNameOnly(sessionPath);

  if (songPlayer != null) {
    songPlayer.pause();
    songPlayer.rewind();
    songPlayer.play();
  }

  feedbackText = "EMPIEZA";
  feedbackColor = colTexto;
  estado = PLAY_HERO;
}

void drawHeroMode() {
  drawLanes();
  drawHitLine();
  drawUpcomingNotesHero();
  drawHitEffects();

  // Marcador a la izquierda.
  fill(colTexto);
  textAlign(LEFT, TOP);
  textSize(22);
  text("Score: " + score, 40, 55);
  text("Combo: " + combo, 40, 85);
  text("Aciertos: " + hits, 40, 115);
  text("Errores: " + totalErrors(), 40, 145);

  // Texto grande de "ACIERTO" / "MISS" en el centro.
  textAlign(CENTER, TOP);
  fill(feedbackColor);
  textSize(34);
  text(feedbackText, width/2, 38);

  fill(colAcento);
  textSize(34);
  text("BeatMaster - Modo carriles", width/2, 88);

  if (songPlayer != null) {
    fill(colTextoSuave);
    textSize(17);
    text(fileNameOnly(mp3Path) + "   " + msToClock(songPlayer.position()) + " / " + msToClock(songPlayer.length()), width/2, 132);
  }

  // Ayudas a la derecha.
  fill(colTextoSuave);
  textAlign(RIGHT, TOP);
  textSize(16);
  text("ESC: terminar partida", width-40, 58);
  text("ESPACIO: pausa", width-40, 82);
}



// Modo notas (parecido a un pentagrama).
void startNotesMode() {
  if (!songLoaded || !sessionLoaded || loadedEvents.size() == 0) {
    warningLine = "Necesitas cargar una sesión válida.";
    return;
  }

  resetGameStats();
  prepareNoteResolved();
  hitEffects.clear();

  currentModeName = "Modo notas";
  currentSessionName = fileNameOnly(sessionPath);

  if (songPlayer != null) {
    songPlayer.pause();
    songPlayer.rewind();
    songPlayer.play();
  }

  feedbackText = "EMPIEZA";
  feedbackColor = colTexto;
  estado = PLAY_NOTES;
}

void drawNotesMode() {
  background(22, 24, 35);

  fill(colTexto);
  textAlign(CENTER, TOP);
  textSize(34);
  text("BeatMaster - Modo notas", width/2, 22);

  // Punto de referencia desde el que dibujo las 5 líneas del pentagrama.
  float baseY = 280;

  // hitX es la línea vertical donde se pulsa la nota.
  // Las notas vienen desde la derecha y se mueven hacia esta línea.
  float hitX = 170;

  // Las cinco líneas del pentagrama.
  // Están separadas 22 píxeles entre sí (es la manera que he visto para que se vean bien).
  stroke(120, 130, 160);
  strokeWeight(1);
  for (int i = 0; i < 5; i++) {
    line(80, baseY + i*22, width-80, baseY + i*22);
  }

  // La línea amarilla vertical.
  // Cuando una nota la toca, hay que pulsar.
  stroke(colLineaGolpe);
  strokeWeight(4);
  line(hitX, 180, hitX, 470);

  drawNotesGameplay(baseY, hitX);
  drawHitEffects();

  // Estadísticas abajo a la izquierda.
  fill(colTexto);
  textAlign(LEFT, TOP);
  textSize(18);
  text("Score: " + score, 90, 520);
  text("Combo: " + combo, 90, 548);
  text("Aciertos: " + hits, 90, 576);
  text("Errores: " + totalErrors(), 90, 604);

  textAlign(RIGHT, TOP);
  text("ESC: terminar partida / ESPACIO: pausa", width-90, 520);

  fill(feedbackColor);
  textAlign(CENTER, TOP);
  textSize(24);
  text(feedbackText, width/2, 520);

  if (songPlayer != null) {
    fill(colTextoSuave);
    textSize(18);
    text(msToClock(songPlayer.position()) + " / " + msToClock(songPlayer.length()), width/2, 560);
  }
}

void drawNotesGameplay(float baseY, float hitX) {
  if (songPlayer == null) return;

  int songPos = songPlayer.position();

  // Aquí uso el tiempo "lento" para que las notas se vean con calma.
  int tiempoVisible = leadTimeNotesMs;

  // Recorro todas las notas cargadas y miro cuáles hay que dibujar ahora.
  for (int i = 0; i < loadedEvents.size(); i++) {
    if (noteResolved != null && noteResolved[i]) continue;

    DrumEvent e = loadedEvents.get(i);

    // dt es cuánto tiempo falta para que la nota tenga que sonar.
    // - Si dt es grande, falta mucho (está a la derecha).
    // - Si dt es 0, justo ahora, en la línea de golpe.
    // - Si dt es negativo, ya pasó.
    int dt = e.timeMs - songPos;

    // Descarto las que están fuera de la ventana de tiempo visible.
    if (dt < -hitWindowMs) continue;
    if (dt > tiempoVisible) continue;

    // map me convierte el tiempo en una posición X de pantalla.
    // Esto es interesante: traduce de un rango a otro.
    float x = map(dt, tiempoVisible, 0, width-100, hitX);
    float y = pitchYForMidi(baseY, e.note);

    drawMusicalNote(e.note, x, y, 0.9);
  }
}



// Esto se llama todo el rato mientras estoy jugando.
// Solo sirve para comprobar si una nota se me ha pasado sin acertarla.
void updatePlaying() {
  if (songPlayer == null) return;

  // Si la canción terminó, doy la partida por acabada.
  if (!songPlayer.isPlaying() && songPlayer.position() >= songPlayer.length()-20) {
    finishGame();
    return;
  }

  int songPos = songPlayer.position();

  // Reviso las notas: si una ya quedó atrás y no la pulsé, cuenta como MISS.
  for (int i = 0; i < loadedEvents.size(); i++) {
    if (noteResolved[i]) continue;

    DrumEvent e = loadedEvents.get(i);

    if (songPos - e.timeMs > hitWindowMs) {
      noteResolved[i] = true;
      misses++;
      combo = 0;
      feedbackText = "MISS";
      feedbackColor = color(255, 70, 70);
    }
  }
}

void gestionarInput(int note, int velocity) {
  // Esta es la función que se llama cada vez que se pulsa algo,
  // ya sea con el teclado (A, S, D, F) o con el HandSonic por MIDI.

  reproducirSonido(note);

  // Si reconozco el carril, lo enciendo durante unos frames.
  int laneIndex = laneIndexForMidi(note);
  if (laneIndex >= 0) {
    laneLastPressedFrame[laneIndex] = frameCount;
  }

  // Caso 1: estoy grabando -> guardo el golpe con el momento exacto.
  if (estado == RECORDING && songPlayer != null) {
    int relMs = songPlayer.position();
    recordedEvents.add(new DrumEvent(note, velocity, relMs));
  }

  // Caso 2: estoy jugando -> miro si la pulsación coincide con alguna nota.
  if ((estado == PLAY_HERO || estado == PLAY_NOTES) && songPlayer != null) {
    int currentTime = songPlayer.position();

    // Busco la nota más cercana en tiempo que sea del mismo instrumento.
    // Empiezo con un "bestDelta" enorme, y voy quedándome con el más pequeño.
    int bestIndex = -1;
    int bestDelta = 999999;

    for (int i = 0; i < loadedEvents.size(); i++) {
      if (noteResolved[i]) continue;

      DrumEvent e = loadedEvents.get(i);
      if (e.note != note) continue;          // Mismo instrumento solo.

      int delta = abs(currentTime - e.timeMs);
      if (delta < bestDelta) {
        bestDelta = delta;
        bestIndex = i;
      }
    }

    // Si la mejor opción está dentro de la ventana de acierto, sumo puntos.
    if (bestIndex != -1 && bestDelta <= hitWindowMs) {
      noteResolved[bestIndex] = true;
      hits++;
      combo++;
      maxCombo = max(maxCombo, combo);
      score += 100;

      feedbackText = "ACIERTO";
      feedbackColor = colLineaGolpe;

      // Creo un efecto visual en el sitio donde se acertó.
      DrumEvent hitEvent = loadedEvents.get(bestIndex);
      float effectX;
      float effectY;

      if (estado == PLAY_HERO) {
        effectX = laneCenterForMidi(hitEvent.note);
        effectY = hitLineY;
      } else {
        // En el modo notas pongo el efecto siempre en el mismo sitio.
        effectX = width/2;
        effectY = 520;
      }

      hitEffects.add(new HitEffect(hitEvent.note, effectX, effectY));
    } else {
      // Si no encajó con ninguna nota cercana, lo cuento como pulsación mala.
      wrongInputs++;
      combo = 0;
      feedbackText = "MISS";
      feedbackColor = color(255, 70, 70);
    }
  }
}

void finishGame() {
  // Si estaba en pausa, primero "deshago" la pausa.
  if (estado == PAUSED) {
    estado = estadoPrevio;
  }

  if (estado != PLAY_HERO && estado != PLAY_NOTES) return;

  markRemainingNotesAsMissed();
  stopSongIfAny();

  inputPlayerName = "";
  feedbackText = "FIN";
  feedbackColor = colAcento;
  estado = ENTER_NAME;
}

void markRemainingNotesAsMissed() {
  // Al acabar la partida, las notas que queden sin resolver cuentan como MISS.
  // Si no hago esto, las estadísticas se quedarían raras.
  if (noteResolved == null) return;

  for (int i = 0; i < noteResolved.length; i++) {
    if (!noteResolved[i]) {
      noteResolved[i] = true;
      misses++;
      combo = 0;
    }
  }
}



// Dibujo de carriles y notas.
void drawLanes() {
  float[] xs = laneCenters();
  String[] names = {"Bombo", "Caja", "Charles", "Plato"};

  // Pinto los cuatro carriles.
  // Si el carril está "iluminado" lo dibujo más fuerte.
  for (int i = 0; i < xs.length; i++) {
    int note = midiForLane(i);
    int c = colorForMidi(note);
    boolean iluminado = isLaneLit(i);

    noStroke();

    if (iluminado) {
      fill(c, 120);
    } else {
      fill(c, 42);
    }

    rect(xs[i] - 70, laneTopY, 140, laneBottomY - laneTopY, 20);

    // La línea vertical del medio del carril.
    if (iluminado) {
      stroke(c);
      strokeWeight(5);
    } else {
      stroke(85, 82, 76);
      strokeWeight(2);
    }

    line(xs[i], laneTopY, xs[i], laneBottomY);

    // Nombre del instrumento debajo y un dibujito pequeño de la nota.
    noStroke();
    fill(colTexto);
    textAlign(CENTER, CENTER);
    textSize(18);
    text(names[i], xs[i], laneBottomY + 40);

    drawOvalNote(note, xs[i], laneBottomY + 84, 1.15);
  }
}

void drawHitLine() {
  // Línea amarilla horizontal donde hay que tocar.
  stroke(colLineaGolpe);
  strokeWeight(5);
  line(100, hitLineY, width-100, hitLineY);

  // Le añado un rectángulo amarillo bajito por detrás, queda mejor visualmente.
  noStroke();
  fill(colLineaGolpe, 45);
  rect(100, hitLineY - 12, width-200, 24, 12);
}

void drawUpcomingNotesHero() {
  if (songPlayer == null) return;

  int songPos = songPlayer.position();

  // Igual que en el modo notas, pero las notas caen de arriba a abajo.
  for (int i = 0; i < loadedEvents.size(); i++) {
    if (noteResolved != null && noteResolved[i]) continue;

    DrumEvent e = loadedEvents.get(i);
    int dt = e.timeMs - songPos;

    if (dt < -hitWindowMs) continue;
    if (dt > leadTimeMs) continue;

    // Aquí map me da la Y: arriba cuando falta mucho, abajo cuando es ya.
    float y = map(dt, leadTimeMs, 0, laneTopY, hitLineY);
    float x = laneCenterForMidi(e.note);

    drawOvalNote(e.note, x, y, 1.0);
  }
}

void drawOvalNote(int note, float x, float y, float s) {
  // pushMatrix y popMatrix me permiten mover y escalar solo este dibujo.
  // Así no afecto al resto de la pantalla.
  pushMatrix();
  translate(x, y);
  scale(s);

  int c = colorForMidi(note);

  stroke(c);
  strokeWeight(3);
  fill(c, 230);

  // Cada instrumento tiene una forma de óvalo distinta. Era una idea para
  // que se distingan a simple vista sin tener que leer la letra.
  if (note == MIDI_BOMBO) {
    ellipse(0, 0, 62, 46);
  } else if (note == MIDI_CAJA) {
    ellipse(0, 0, 54, 54);
  } else if (note == MIDI_CHARLES) {
    ellipse(0, 0, 72, 26);
  } else {
    ellipse(0, 0, 76, 30);
  }

  // Encima escribo la letra ("BOMBO", "CAJA"...) por si acaso.
  fill(0, 120);
  noStroke();
  textAlign(CENTER, CENTER);
  textSize(11);
  text(labelForMidi(note), 0, 0);

  popMatrix();
}

void drawMusicalNote(int note, float x, float y, float s) {
  // Esta es mi versión simple de una nota musical de pentagrama.
  // Tiene la "cabeza" redonda y un palito hacia arriba, con un trazo curvo.
  // Es una representación simplificada, suficiente para identificar la nota.
  pushMatrix();
  translate(x, y);
  scale(s);

  int c = colorForMidi(note);

  stroke(c);
  strokeWeight(3);
  fill(c, 235);

  ellipse(0, 0, 24, 17);      // Cabeza de la nota.
  line(11, 0, 11, -45);       // Palito vertical.

  // Trazo curvo (la "banderita" de la nota).
  noFill();
  bezier(11, -45, 38, -35, 37, -12, 14, -14);

  noStroke();
  fill(colTexto);
  textAlign(CENTER, CENTER);
  textSize(10);
  text(labelForMidi(note), 0, 27);

  popMatrix();
}

void drawHitEffects() {
  // Recorro la lista de efectos al revés porque voy borrando elementos.
  // Si lo hiciera al derecho, se modificaría el índice cuando borre.
  for (int i = hitEffects.size() - 1; i >= 0; i--) {
    HitEffect h = hitEffects.get(i);
    h.draw();

    if (h.isFinished()) {
      hitEffects.remove(i);
    }
  }
}

void drawRecordingTimeline(float x, float y, float w, float h) {
  // Pinto un rectángulo gris de fondo y dentro voy poniendo las marcas
  // de los golpes que llevo grabados. Cada marca es una rayita vertical.
  noStroke();
  fill(38, 39, 38);
  rect(x, y, w, h, 8);

  if (songPlayer == null || recordedEvents.size() == 0) return;

  int len = max(songPlayer.length(), 1);

  for (DrumEvent e : recordedEvents) {
    float nx = map(e.timeMs, 0, len, x, x+w);
    fill(colorForMidi(e.note));
    rect(nx, y + 6, 3, h - 12);
  }
}



// Pantalla de pausa: dibujo lo de antes con una capa negra encima.
void drawPaused() {
  if (estadoPrevio == PLAY_HERO) {
    drawHeroMode();
  } else if (estadoPrevio == PLAY_NOTES) {
    drawNotesMode();
  } else {
    drawMenu();
  }

  // Capa semitransparente para que se vea oscurecido.
  fill(0, 0, 0, 170);
  rect(0, 0, width, height);

  fill(colTexto);
  textAlign(CENTER, CENTER);
  textSize(42);
  text("PAUSA", width/2, height/2 - 30);
  textSize(20);
  text("Pulsa ESPACIO para continuar", width/2, height/2 + 20);
}

void pauseOrResume() {
  // Si estoy en pausa, vuelvo al estado de antes.
  // Si no, guardo el estado actual y paso a pausa.
  if (estado == PAUSED) {
    if (songPlayer != null) songPlayer.play();
    estado = estadoPrevio;
  } else {
    estadoPrevio = estado;
    if (songPlayer != null) songPlayer.pause();
    estado = PAUSED;
  }
}



// Pantalla para escribir el nombre al acabar la partida.
void drawEnterName() {
  drawTitle("Guardar resultado");
  drawPanel(170, 150, width-340, 420);

  fill(colTexto);
  textAlign(CENTER, CENTER);
  textSize(28);
  text("La partida ha terminado", width/2, 210);

  textSize(18);
  fill(colTextoSuave);
  text("Escribe tu nombre y pulsa ENTER", width/2, 250);

  // Caja donde se ve lo que va escribiendo el jugador.
  fill(34, 36, 36);
  rect(290, 285, width-580, 56, 10);

  // El "cursor" que parpadea, hecho con un truco simple del frameCount.
  fill(colAcento);
  textSize(26);
  String cursor = (frameCount / 25) % 2 == 0 ? "_" : "";
  text(inputPlayerName + cursor, width/2, 313);

  // Resumen de la partida.
  fill(colTexto);
  textSize(18);
  text("Modo: " + currentModeName, width/2, 385);
  text("Sesión: " + currentSessionName, width/2, 415);
  text("Score: " + score + "   |   Aciertos: " + hits + "   |   Errores: " + totalErrors(), width/2, 445);
  text("Combo máximo: " + maxCombo, width/2, 475);

  fill(colTextoSuave);
  text("ENTER = guardar    |    ESC = cancelar", width/2, 545);
}

void drawResultsScreen() {
  drawTitle("Resultados guardados");
  drawPanel(60, 110, width-120, 510);

  fill(colTextoSuave);
  textAlign(LEFT, CENTER);
  textSize(17);
  text("ESC vuelve al menú", 90, 145);

  // Coordenadas y separación entre filas de la tabla.
  float tableX = 90;
  float y = 195;
  float rowH = 38;

  // Cabeceras de columnas.
  fill(colAcento);
  textSize(16);
  text("Fecha", tableX, y);
  text("Nombre", tableX + 160, y);
  text("Modo", tableX + 320, y);
  text("Sesión", tableX + 470, y);
  text("Score", tableX + 720, y);
  text("Aciertos", tableX + 810, y);
  text("Errores", tableX + 910, y);
  text("Combo", tableX + 1010, y);

  stroke(80);
  line(tableX, y + 16, width-90, y + 16);
  noStroke();

  // Si todavía no hay nada guardado.
  if (savedResults.size() == 0) {
    fill(colTextoSuave);
    textAlign(CENTER, CENTER);
    textSize(24);
    text("Todavía no hay resultados guardados", width/2, height/2);
    return;
  }

  textSize(14);
  // Solo pinto como mucho 10 filas para que no se salga de la pantalla.
  int maxRows = min(savedResults.size(), 10);

  for (int i = 0; i < maxRows; i++) {
    GameResult r = savedResults.get(i);
    float rowY = 240 + i * rowH;

    // Fondo alterno (filas pares un poco más oscuras) para que se lea mejor.
    if (i % 2 == 0) {
      fill(31, 33, 45);
      rect(tableX-10, rowY-14, width-180, 28, 6);
    }

    fill(colTexto);
    textAlign(LEFT, CENTER);
    text(r.dateStr, tableX, rowY);
    text(r.playerName, tableX + 160, rowY);
    text(r.mode, tableX + 320, rowY);
    text(trimText(r.sessionName, 28), tableX + 470, rowY);
    text(str(r.score), tableX + 720, rowY);
    text(str(r.hits), tableX + 810, rowY);
    text(str(r.errors), tableX + 910, rowY);
    text(str(r.maxCombo), tableX + 1010, rowY);
  }
}

void handleNameInput() {
  // ENTER: confirmo el nombre y guardo el resultado.
  if (keyCode == ENTER || keyCode == RETURN) {
    String finalName = trim(inputPlayerName);
    if (finalName.length() == 0) finalName = "Sin nombre";

    saveCurrentResult(finalName);
    inputPlayerName = "";
    estado = MENU;
    warningLine = "Resultado guardado.";
    return;
  }

  // ESC: cancelo. Tengo que poner key = 0 para que Processing no cierre el sketch.
  if (keyCode == ESC) {
    key = 0;
    inputPlayerName = "";
    estado = MENU;
    warningLine = "Guardado cancelado.";
    return;
  }

  // Borrar el último carácter.
  if (keyCode == BACKSPACE) {
    if (inputPlayerName.length() > 0) {
      inputPlayerName = inputPlayerName.substring(0, inputPlayerName.length()-1);
    }
    return;
  }

  // Borrar todo de golpe.
  if (keyCode == DELETE) {
    inputPlayerName = "";
    return;
  }

  // Si es un carácter normal, lo voy añadiendo (hasta 24 caracteres).
  // Compruebo que no sea una tecla "rara" tipo flechas (CODED).
  if (key != CODED && key >= 32 && key != TAB) {
    if (inputPlayerName.length() < 24) {
      inputPlayerName += key;
    }
  }
}

void saveCurrentResult(String playerName) {
  // Creo el resultado con todos los datos de la partida y lo meto al principio
  // para que aparezca arriba del todo en la tabla.
  GameResult r = new GameResult(
    sanitizeField(playerName),
    sanitizeField(currentModeName),
    sanitizeField(currentSessionName),
    nowAsString(),
    score,
    hits,
    totalErrors(),
    maxCombo
  );

  savedResults.add(0, r);
  saveResultsFile();
}

void loadSavedResults() {
  savedResults.clear();

  String[] lines = loadStrings(resultsFilePath);
  if (lines == null || lines.length == 0) return;

  // Empiezo en 1 porque la primera línea es la cabecera del TSV.
  for (int i = 1; i < lines.length; i++) {
    GameResult r = gameResultFromTSV(lines[i]);
    if (r != null) savedResults.add(r);
  }
}

void saveResultsFile() {
  // Creo un array de strings: cabecera + una línea por resultado.
  String[] out = new String[savedResults.size() + 1];
  out[0] = "fecha\tnombre\tmodo\tsesion\tscore\thits\terrores\tmaxCombo";

  for (int i = 0; i < savedResults.size(); i++) {
    out[i+1] = savedResults.get(i).toTSV();
  }

  saveStrings(resultsFilePath, out);
}



// Carga y guardado de sesiones en formato TXT.
void loadSong(String path) {
  try {
    // Si ya había una canción cargada, la cierro para liberar memoria.
    if (songPlayer != null) songPlayer.close();

    songPlayer = minim.loadFile(path, 2048);

    if (songPlayer != null) {
      mp3Path = path;
      songLoaded = true;
      warningLine = "MP3 cargado: " + fileNameOnly(path);
    } else {
      warningLine = "No se pudo cargar el MP3.";
    }
  } catch(Exception e) {
    warningLine = "Error cargando MP3.";
  }
}

void saveSessionTxt(String txtPath) {
  // El formato del TXT es muy simple:
  //   Línea 1: mp3=ruta_del_mp3
  //   Líneas siguientes: event=nota,velocidad,tiempo
  String[] lines = new String[recordedEvents.size() + 1];
  lines[0] = "mp3=" + mp3Path;

  for (int i = 0; i < recordedEvents.size(); i++) {
    DrumEvent e = recordedEvents.get(i);
    lines[i+1] = "event=" + e.note + "," + e.velocity + "," + e.timeMs;
  }

  saveStrings(txtPath, lines);
}

void loadSessionFile(String txtPath) {
  String[] lines = loadStrings(txtPath);
  if (lines == null) {
    warningLine = "No se pudo cargar la sesión.";
    return;
  }

  loadedEvents.clear();

  String foundMp3 = "";

  // Recorro el archivo línea por línea.
  // Si empieza por "mp3=" me guardo la ruta de la canción.
  // Si empieza por "event=" lo parto por comas y guardo el golpe.
  for (String line : lines) {
    if (line == null) continue;
    line = trim(line);

    if (line.startsWith("mp3=")) {
      foundMp3 = line.substring(4).trim();
    } else if (line.startsWith("event=")) {
      String data = line.substring(6).trim();
      String[] p = split(data, ',');

      if (p != null && p.length >= 3) {
        int note = parseIntSafe(p[0]);
        int velocity = parseIntSafe(p[1]);
        int timeMs = parseIntSafe(p[2]);
        loadedEvents.add(new DrumEvent(note, velocity, timeMs));
      }
    }
  }

  // Si la sesión trae un MP3, intento cargarlo también.
  if (foundMp3.length() > 0) {
    loadSong(foundMp3);
  }

  sessionPath = txtPath;
  sessionLoaded = loadedEvents.size() > 0;

  if (sessionLoaded) {
    warningLine = "Sesión cargada: " + fileNameOnly(txtPath) + " (" + loadedEvents.size() + " golpes)";
  } else {
    warningLine = "La sesión no tiene golpes válidos.";
  }
}

void onSaveSessionTxt(File f) {
  // Esta función la llama selectOutput cuando el usuario elige dónde guardar.
  // Si pulso Cancelar, f viene null y no hago nada.
  if (f == null) return;

  String outPath = f.getAbsolutePath();
  // Si no se ha puesto la extensión .txt, se la pongo yo.
  if (!outPath.toLowerCase().endsWith(".txt")) {
    outPath += ".txt";
  }

  saveSessionTxt(outPath);

  // También dejo cargada la sesión que acabo de guardar, así no hay que abrirla a mano.
  sessionPath = outPath;
  sessionLoaded = true;
  loadedEvents.clear();

  for (DrumEvent e : recordedEvents) {
    loadedEvents.add(e);
  }

  warningLine = "Sesión guardada: " + fileNameOnly(outPath);
}

void onSelectRecordMp3(File f) {
  if (f == null) return;
  loadSong(f.getAbsolutePath());
  estado = RECORD_READY;
}

void onSelectSessionForHero(File f) {
  if (f == null) return;
  loadSessionFile(f.getAbsolutePath());
  if (songLoaded && sessionLoaded) startHeroMode();
}

void onSelectSessionForNotes(File f) {
  if (f == null) return;
  loadSessionFile(f.getAbsolutePath());
  if (songLoaded && sessionLoaded) startNotesMode();
}



// Esta función se llama cada vez que aprieto una tecla.
// Lo que pase depende del estado del juego.
void keyPressed() {
  warningLine = "";

  // En el menú uso los números como atajos.
  if (estado == MENU) {
    if (key == '1') {
      selectInput("Selecciona un MP3 para grabar", "onSelectRecordMp3");
      return;
    } else if (key == '2') {
      selectInput("Selecciona una sesión TXT para modo carriles", "onSelectSessionForHero");
      return;
    } else if (key == '3') {
      selectInput("Selecciona una sesión TXT para modo notas", "onSelectSessionForNotes");
      return;
    } else if (key == '4') {
      estado = RESULTS;
      return;
    } else if (key == '5') {
      sonidosActivos = !sonidosActivos;
      warningLine = "Sonidos " + (sonidosActivos ? "activados" : "desactivados");
      return;
    } else if (key == '6') {
      learnStep = 0;
      estado = LEARN_MIDI;
      warningLine = "Toca los pads en el orden indicado.";
      return;
    }
  }

  // En la pantalla "preparado para grabar", ESPACIO empieza la grabación.
  if (estado == RECORD_READY && key == ' ') {
    startRecording();
    return;
  }

  if (estado == RECORD_READY && keyCode == ESC) {
    key = 0;
    stopSongIfAny();
    estado = MENU;
    return;
  }

  // Mientras grabo, G guarda y ESC corta sin guardar.
  if (estado == RECORDING) {
    if (key == 'g' || key == 'G') {
      stopRecording(true);
      return;
    } else if (keyCode == ESC) {
      key = 0;
      stopRecording(false);
      return;
    }
  }

  // En modo de juego: ESPACIO pausa, ESC termina.
  if (estado == PLAY_HERO || estado == PLAY_NOTES) {
    if (key == ' ') {
      pauseOrResume();
      return;
    }

    if (keyCode == ESC) {
      key = 0;
      finishGame();
      return;
    }
  }

  if (estado == PAUSED) {
    if (key == ' ') {
      pauseOrResume();
      return;
    }

    if (keyCode == ESC) {
      key = 0;
      finishGame();
      return;
    }
  }

  // En la pantalla de poner nombre tengo lógica aparte.
  if (estado == ENTER_NAME) {
    handleNameInput();
    return;
  }

  if (estado == RESULTS) {
    if (keyCode == ESC) {
      key = 0;
      estado = MENU;
      return;
    }
  }

  // Pantalla de configurar el MIDI: ESC cancela, R restablece valores por defecto.
  if (estado == LEARN_MIDI) {
    if (keyCode == ESC) {
      key = 0;
      estado = MENU;
      warningLine = "Configuración MIDI cancelada.";
      return;
    }

    if (key == 'r' || key == 'R') {
      RAW_BOMBO = 36;
      RAW_CAJA = 38;
      RAW_CHARLES = 46;
      RAW_PLATO = 49;
      learnStep = 0;
      warningLine = "Mapeo MIDI restablecido a 36, 38, 46, 49.";
      return;
    }
  }

  // En cualquier momento que se esté grabando o jugando,
  // las teclas A/S/D/F valen para tocar los cuatro instrumentos
  // (así puedo probar sin tener el HandSonic conectado).
  if (estado == RECORDING || estado == PLAY_HERO || estado == PLAY_NOTES) {
    if (key == 'a' || key == 'A') gestionarInput(MIDI_BOMBO, 100);
    if (key == 's' || key == 'S') gestionarInput(MIDI_CAJA, 100);
    if (key == 'd' || key == 'D') gestionarInput(MIDI_CHARLES, 100);
    if (key == 'f' || key == 'F') gestionarInput(MIDI_PLATO, 100);
  }
}



// Conexión con el MIDI.
// Esto fue lo más tedioso de toda la práctica.
void conectarMidiAutomatico() {
  try {
    // Pido al sistema la lista de dispositivos MIDI.
    MidiDevice.Info[] infos = MidiSystem.getMidiDeviceInfo();

    // Imprimo todo por consola para poder ver qué hay conectado.
    // Esto me ayudó un montón para depurar.
    println("================================================");
    println("DISPOSITIVOS MIDI DETECTADOS POR PROCESSING");
    println("================================================");

    for (int i = 0; i < infos.length; i++) {
      MidiDevice dev = MidiSystem.getMidiDevice(infos[i]);

      println(i + " -> Nombre: " + infos[i].getName());
      println("     Descripción: " + infos[i].getDescription());
      println("     Vendor: " + infos[i].getVendor());
      println("     Versión: " + infos[i].getVersion());
      println("     Max Transmitters: " + dev.getMaxTransmitters());
      println("     Max Receivers: " + dev.getMaxReceivers());
      println("--------------------------------------------");

      String nombre = infos[i].getName().toLowerCase();
      String descripcion = infos[i].getDescription().toLowerCase();

      // Para recibir MIDI me hace falta un dispositivo que tenga "Transmitters".
      // Si tiene 0, no me sirve.
      // Primero pruebo a buscar uno que sea "UM-ONE" o "Roland", que es lo que uso yo para el TFG.
      if (midiInputDevice == null
        && dev.getMaxTransmitters() != 0
        && (
        nombre.contains("um-one")
        || descripcion.contains("um-one")
        || nombre.contains("roland")
        || descripcion.contains("roland")
        )) {

        midiInputDevice = dev;
      }
    }

    // Si no encontré ninguno con esos nombres, selecciono el primero que valga.
    // Así sigue funcionando aunque Windows lo llame de otra manera.
    if (midiInputDevice == null) {
      println("No se ha encontrado UM-ONE/Roland por nombre. Probando primera entrada MIDI disponible...");

      for (int i = 0; i < infos.length; i++) {
        MidiDevice dev = MidiSystem.getMidiDevice(infos[i]);

        if (dev.getMaxTransmitters() != 0) {
          midiInputDevice = dev;
          break;
        }
      }
    }

    // Si he encontrado uno, lo abro y le conecto mi Receiver.
    // El Receiver es una clase mía que recibe los mensajes MIDI.
    if (midiInputDevice != null) {
      midiInputDevice.open();

      Transmitter t = midiInputDevice.getTransmitter();
      midiReceiver = new MidiInputReceiver();
      t.setReceiver(midiReceiver);

      println("================================================");
      println("MIDI CONECTADO CORRECTAMENTE A:");
      println(midiInputDevice.getDeviceInfo().getName());
      println("================================================");

      warningLine = "MIDI conectado: " + midiInputDevice.getDeviceInfo().getName();
    } else {
      println("NO SE HA ENCONTRADO NINGUNA ENTRADA MIDI");
      warningLine = "Sin entrada MIDI. Puedes usar A/S/D/F.";
    }
  } catch(Exception e) {
    println("ERROR MIDI:");
    e.printStackTrace();
    warningLine = "Error al conectar MIDI. Se usará teclado.";
  }
}

class MidiInputReceiver implements Receiver {
  // Esta clase la llama Java cada vez que llega un mensaje MIDI.
  // No hace falta que yo la llame, se llama sola.
  public void send(MidiMessage msg, long timeStamp) {
    byte[] b = msg.getMessage();

    // Un mensaje MIDI suele tener 3 bytes: status, dato1, dato2.
    if (b.length >= 3) {
      // & 0xFF sirve para tratar el byte como
      // un número positivo entre 0 y 255 (Java los trata con signo si no).
      int status = b[0] & 0xFF;
      int command = status & 0xF0;
      int channel = status & 0x0F;
      int rawNote = b[1] & 0xFF;
      int vel = b[2] & 0xFF;

      // Voy guardando datos para luego pintarlos en la pantalla o en consola.
      ultimoCanalMidi = channel + 1;
      ultimaNotaRaw = rawNote;
      ultimaVelocidadMidi = vel;
      ultimoMidiFrame = frameCount;

      // NOTE_ON normal: command 144 con velocidad mayor que 0.
      if (command == 144 && vel > 0) {
        int mappedNote = mapRawMidiToGameNote(rawNote);
        ultimaNotaMapeada = mappedNote;

        ultimoMidiTexto = "Canal " + (channel + 1) + " | nota " + rawNote + " -> " + labelForMidi(mappedNote) + " | vel " + vel;

        println("MIDI RECIBIDO -> canal: " + (channel + 1)
          + " | nota raw: " + rawNote
          + " | nota juego: " + mappedNote
          + " | instrumento: " + labelForMidi(mappedNote)
          + " | velocidad: " + vel
          + " | command: " + command);

        // Caso especial: si estoy en la pantalla de configurar pads,
        // no quiero jugar ni grabar, solo me apunto qué nota envía cada pad.
        if (estado == LEARN_MIDI) {
          aprenderNotaMidi(rawNote);
          return;
        }

        gestionarInput(mappedNote, vel);
      }

      // Truco: algunos teclados mandan NOTE_ON con velocidad 0 en vez de NOTE_OFF.
      // Por eso lo trato como NOTE_OFF también.
      else if (command == 144 && vel == 0) {
        ultimoMidiTexto = "NOTE OFF: nota " + rawNote;
        println("MIDI NOTE OFF -> nota raw: " + rawNote + " | canal: " + (channel + 1));
      }

      // NOTE_OFF de verdad (command 128).
      else if (command == 128) {
        ultimoMidiTexto = "NOTE OFF: nota " + rawNote;
        println("MIDI NOTE OFF -> nota raw: " + rawNote + " | canal: " + (channel + 1));
      }

      // Cualquier otro mensaje (program change, aftertouch...).
      // Aquí no hago nada en el juego, pero al menos lo veo por consola.
      else {
        ultimoMidiTexto = "Otro MIDI: command " + command + " | nota/dato " + rawNote;
        println("OTRO MIDI -> command: " + command + " | canal: " + (channel + 1) + " | dato1: " + rawNote + " | dato2: " + vel);
      }
    }
  }

  public void close() {
    // No tengo que hacer nada al cerrar, pero es obligatorio implementarlo.
  }
}

int mapRawMidiToGameNote(int rawNote) {
  // Como el HandSonic puede mandar notas distintas a las del General MIDI,
  // tengo que traducirlas a las cuatro notas que uso yo en el juego.
  if (rawNote == RAW_BOMBO) return MIDI_BOMBO;
  if (rawNote == RAW_CAJA) return MIDI_CAJA;
  if (rawNote == RAW_CHARLES) return MIDI_CHARLES;
  if (rawNote == RAW_PLATO) return MIDI_PLATO;

  // Si llega una nota que no he configurado, devuelvo la misma para que aparezca
  // en la consola. Así puedo verla y luego configurarla con la opción [6].
  return rawNote;
}

void aprenderNotaMidi(int rawNote) {
  // Esto es para el modo "aprender pads".
  // Voy paso a paso pidiendo: toca bombo, toca caja, toca charles, toca plato.

  // Pequeño truco: si la misma nota llega dos veces seguidas
  // (a veces el pad rebota), la ignoro para no asignar dos pads al mismo.
  if (learnStep > 0) {
    int anterior = -1;
    if (learnStep == 1) anterior = RAW_BOMBO;
    if (learnStep == 2) anterior = RAW_CAJA;
    if (learnStep == 3) anterior = RAW_CHARLES;
    if (learnStep == 4) anterior = RAW_PLATO;

    if (rawNote == anterior) return;
  }

  if (learnStep == 0) {
    RAW_BOMBO = rawNote;
    warningLine = "Bombo configurado con nota " + rawNote;
  } else if (learnStep == 1) {
    RAW_CAJA = rawNote;
    warningLine = "Caja configurada con nota " + rawNote;
  } else if (learnStep == 2) {
    RAW_CHARLES = rawNote;
    warningLine = "Charles configurado con nota " + rawNote;
  } else if (learnStep == 3) {
    RAW_PLATO = rawNote;
    warningLine = "Plato configurado con nota " + rawNote;
  }

  learnStep++;

  // Cuando ya he configurado los 4, vuelvo al menú.
  if (learnStep >= 4) {
    estado = MENU;
    warningLine = "Mapeo MIDI guardado para esta ejecución.";
  }
}

void drawLearnMidi() {
  background(18, 20, 30);

  drawTitle("Configurar HandSonic");

  drawPanel(150, 140, width-300, 440);

  fill(colTexto);
  textAlign(CENTER, CENTER);
  textSize(24);
  text("Toca los pads en este orden:", width/2, 190);

  textSize(34);
  fill(colAcento);

  // Texto grande con lo que toca tocar en este momento.
  String objetivo = "CONFIGURACIÓN COMPLETA";
  if (learnStep >= 0 && learnStep < learnTargets.length) {
    objetivo = learnTargets[learnStep];
  }

  text(objetivo, width/2, 245);

  fill(colTexto);
  textSize(20);
  text("1. Bombo   2. Caja   3. Charles   4. Plato", width/2, 310);

  fill(colTextoSuave);
  textSize(18);
  text("Último MIDI: " + ultimoMidiTexto, width/2, 360);

  text("Mapeo actual:", width/2, 420);
  text("Bombo=" + RAW_BOMBO + "   Caja=" + RAW_CAJA + "   Charles=" + RAW_CHARLES + "   Plato=" + RAW_PLATO, width/2, 455);

  fill(colLineaGolpe);
  textSize(16);
  text("ESC: cancelar   |   R: restablecer a 36, 38, 46, 49", width/2, 530);
}



// Funciones de ayuda que uso por todo el código.
// Las he separado aquí para que el resto se entienda mejor.

void drawTitle(String t) {
  fill(colAcento);
  textAlign(CENTER, CENTER);
  textSize(40);
  text(t, width/2, 55);
}

void drawPanel(float x, float y, float w, float h) {
  // Solo es un rectángulo con bordes redondeados para meter cosas dentro.
  noStroke();
  fill(colPanel);
  rect(x, y, w, h, 18);
}

void drawFooter() {
  // Pinto la barrita de abajo con info del MIDI y mensajes rápidos.
  fill(colTextoSuave);
  textAlign(LEFT, BOTTOM);
  textSize(14);

  String midiDeviceName = (midiInputDevice != null ? midiInputDevice.getDeviceInfo().getName() : "sin dispositivo MIDI");
  String midiLine = "MIDI: " + midiDeviceName;
  if (ultimaNotaRaw >= 0) {
    midiLine += " | última nota: " + ultimaNotaRaw + " -> " + labelForMidi(ultimaNotaMapeada);
  }
  text(midiLine, 16, height-12);

  textAlign(RIGHT, BOTTOM);
  fill(colLineaGolpe);
  if (warningLine != null && warningLine.length() > 0) {
    text(warningLine, width-16, height-12);
  }
}

void stopSongIfAny() {
  // Pequeña función para parar la canción y dejarla al principio.
  // Así no tengo que copiar este código en varios sitios.
  if (songPlayer != null) {
    songPlayer.pause();
    songPlayer.rewind();
  }
}

void resetGameStats() {
  // Pone todos los contadores a 0 al empezar una partida.
  score = 0;
  combo = 0;
  maxCombo = 0;
  hits = 0;
  misses = 0;
  wrongInputs = 0;
}

void prepareNoteResolved() {
  // Creo el array de booleans del mismo tamaño que la lista de eventos cargados.
  // En Java los booleans empiezan a false, así que no haría falta el bucle,
  // pero lo dejo por si acaso en el futuro cambio el tipo.
  noteResolved = new boolean[loadedEvents.size()];
  for (int i = 0; i < noteResolved.length; i++) {
    noteResolved[i] = false;
  }
}

int totalErrors() {
  // Los errores totales son las notas que se me pasaron (misses)
  // más las teclas que pulsé cuando no tocaba (wrongInputs).
  return misses + wrongInputs;
}

String nowAsString() {
  // Devuelve la fecha y hora actual en formato bonito.
  SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd HH:mm");
  return sdf.format(new Date());
}

String sanitizeField(String s) {
  // Quito tabuladores y saltos de línea para que no se rompa el formato TSV.
  if (s == null) return "";
  return s.replace('\t', ' ').replace('\n', ' ').replace('\r', ' ').trim();
}

String trimText(String s, int maxLen) {
  // Si un texto es muy largo, lo recorto y le pongo "..." al final.
  if (s == null) return "";
  if (s.length() <= maxLen) return s;
  return s.substring(0, maxLen-3) + "...";
}

String fileNameOnly(String p) {
  // De una ruta completa me quedo solo con el nombre del archivo.
  // Así en pantalla no se ven todas las carpetas, queda más limpio.
  if (p == null || p.length() == 0) return "";
  return new File(p).getName();
}

String msToClock(int ms) {
  // Convierte milisegundos a formato mm:ss.
  // Por ejemplo 65000 ms -> "01:05".
  int totalSec = max(ms, 0) / 1000;
  int min = totalSec / 60;
  int sec = totalSec % 60;
  return nf(min, 2) + ":" + nf(sec, 2);
}

int parseIntSafe(String s) {
  // Parsea un String a int, pero si falla devuelve 0 en vez de romperse.
  // Así si el TXT está corrupto el programa no se cae entero.
  try {
    return Integer.parseInt(trim(s));
  } catch(Exception e) {
    return 0;
  }
}

float[] laneCenters() {
  // Las cuatro X de los carriles. Fuí probando hasta que quedó bien.
  return new float[] {300, 530, 760, 990};
}

float laneCenterForMidi(int note) {
  // Dada una nota, devuelvo la X del carril que le toca.
  if (note == MIDI_BOMBO) return laneCenters()[0];
  if (note == MIDI_CAJA) return laneCenters()[1];
  if (note == MIDI_CHARLES) return laneCenters()[2];
  return laneCenters()[3];
}

int midiForLane(int i) {
  // Al revés: dado un índice de carril, devuelvo qué instrumento es.
  if (i == 0) return MIDI_BOMBO;
  if (i == 1) return MIDI_CAJA;
  if (i == 2) return MIDI_CHARLES;
  return MIDI_PLATO;
}

int laneIndexForMidi(int note) {
  // Devuelve el índice del carril (0..3) según el instrumento.
  // Si no es ninguno de los cuatro, devuelve -1.
  if (note == MIDI_BOMBO) return 0;
  if (note == MIDI_CAJA) return 1;
  if (note == MIDI_CHARLES) return 2;
  if (note == MIDI_PLATO) return 3;
  return -1;
}

boolean isLaneLit(int laneIndex) {
  // Está encendido si han pasado menos frames que la duración permitida.
  return frameCount - laneLastPressedFrame[laneIndex] < laneLightDuration;
}

String labelForMidi(int note) {
  // Devuelve el nombre del instrumento como texto.
  if (note == MIDI_BOMBO) return "BOMBO";
  if (note == MIDI_CAJA) return "CAJA";
  if (note == MIDI_CHARLES) return "CHARLES";
  return "PLATO";
}

int colorForMidi(int note) {
  // Cada instrumento tiene su color. Los elegí para que se distingan fácilmente.
  if (note == MIDI_BOMBO) return color(0, 170, 255);     // azul
  if (note == MIDI_CAJA) return color(255, 70, 70);      // rojo
  if (note == MIDI_CHARLES) return color(255, 210, 40);  // amarillo
  return color(120, 255, 140);                           // verde para el plato
}

float pitchYForMidi(float baseY, int note) {
  // En el pentagrama cada instrumento va a una altura distinta.
  // No es teoría musical exacta, pero así al menos se distinguen unos de otros.
  if (note == MIDI_BOMBO) return baseY + 95;
  if (note == MIDI_CAJA) return baseY + 45;
  if (note == MIDI_CHARLES) return baseY + 5;
  return baseY - 30;
}

GameResult gameResultFromTSV(String line) {
  // Convierte una línea de TSV en un objeto GameResult.
  // Si la línea está mal, devuelvo null y luego se ignora.
  String[] p = split(line, '\t');
  if (p == null || p.length < 8) return null;

  return new GameResult(
    p[1],
    p[2],
    p[3],
    p[0],
    parseIntSafe(p[4]),
    parseIntSafe(p[5]),
    parseIntSafe(p[6]),
    parseIntSafe(p[7])
  );
}



// Esto se ejecuta cuando se cierra la aplicación.
// Aprovecho para cerrar el MIDI bien y que Windows no se quede colgado.
void stop() {
  try {
    if (midiReceiver != null) {
      midiReceiver.close();
    }

    if (midiInputDevice != null && midiInputDevice.isOpen()) {
      midiInputDevice.close();
    }
  } catch(Exception e) {
    println("Error cerrando MIDI.");
  }

  super.stop();
}



// Clases auxiliares.

class DrumEvent {
  // Representa un golpe: qué instrumento, con qué fuerza y cuándo.
  int note;
  int velocity;
  int timeMs;

  DrumEvent(int note, int velocity, int timeMs) {
    this.note = note;
    this.velocity = velocity;
    this.timeMs = timeMs;
  }
}

class HitEffect {
  // Es el circulito que aparece y crece cuando aciertas una nota.
  // Va creciendo y a la vez se vuelve transparente, hasta desaparecer.
  int note;
  float x;
  float y;
  int startFrame;
  int duration = 24;    // Dura 24 frames (aprox medio segundo a 50 fps).

  HitEffect(int note, float x, float y) {
    this.note = note;
    this.x = x;
    this.y = y;
    this.startFrame = frameCount;
  }

  boolean isFinished() {
    // Si ya pasaron más frames que la duración, lo doy por terminado.
    return frameCount - startFrame > duration;
  }

  void draw() {
    // t va de 0 (recién creado) a 1 (a punto de terminar).
    float t = (frameCount - startFrame) / float(duration);

    // El tamaño crece y la transparencia baja según avanza t.
    float size = map(t, 0, 1, 20, 90);
    float alpha = map(t, 0, 1, 230, 0);

    noFill();
    strokeWeight(4);
    stroke(colorForMidi(note), alpha);
    ellipse(x, y, size, size);

    fill(255, alpha);
    textAlign(CENTER, CENTER);
    textSize(18);
    text("ACIERTO", x, y - 58);
  }
}

class GameResult {
  // Guarda los datos de una partida ya terminada.
  // Es lo que se ve luego en la tabla de resultados.
  String playerName;
  String mode;
  String sessionName;
  String dateStr;

  int score;
  int hits;
  int errors;
  int maxCombo;

  GameResult(String playerName, String mode, String sessionName, String dateStr, int score, int hits, int errors, int maxCombo) {
    this.playerName = playerName;
    this.mode = mode;
    this.sessionName = sessionName;
    this.dateStr = dateStr;
    this.score = score;
    this.hits = hits;
    this.errors = errors;
    this.maxCombo = maxCombo;
  }

  String toTSV() {
    // Devuelve la línea ya formateada con tabuladores para guardarla en el TSV.
    return
      sanitizeField(dateStr) + "\t" +
      sanitizeField(playerName) + "\t" +
      sanitizeField(mode) + "\t" +
      sanitizeField(sessionName) + "\t" +
      score + "\t" +
      hits + "\t" +
      errors + "\t" +
      maxCombo;
  }
}
