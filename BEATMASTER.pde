import javax.sound.midi.*;
import java.util.Date;
import java.text.SimpleDateFormat;

// BeatMaster alpha PEC3
// guitar hero pero con bateria

final int MENU = 0;
final int GRABANDO = 1;
final int JUGANDO = 2;
int estado = MENU;

// notas MIDI estandar de bateria
final int MIDI_BOMBO   = 36;
final int MIDI_CAJA    = 38;
final int MIDI_CHARLES = 46;
final int MIDI_PLATO   = 49;

ArrayList<EventoBateria> eventos = new ArrayList<EventoBateria>();
boolean[] yaResuelto;

int tiempoInicioGrabacion = 0;
int tiempoInicioJuego = 0;

int score = 0;
int aciertos = 0;
int errores = 0;
int combo = 0;

int margen = 140; // ms de tolerancia para acertar
int anticipacion = 2200;

String feedback = "LISTO";

MidiDevice midiInputDevice;
String infoMIDI = "Buscando dispositivo MIDI...";

PFont fontMain;

int colFondo = color(15, 15, 20);
int colPanel = color(40, 42, 50);
int colTexto = color(240, 240, 255);
int colTextoSuave = color(170, 180, 200);
int colAcento = color(220, 30, 40);
int colLineaGolpe = color(255, 230, 60);

float laneTopY = 170;
float hitLineY = 510;


void setup() {
  size(1366, 768);
  surface.setTitle("BeatMaster - Alpha PEC3");
  smooth(4);
  fontMain = createFont("Arial", 18);
  textFont(fontMain);
  conectarMidi();
}


void draw() {
  background(colFondo);

  if (estado == MENU) {
    drawMenu();
  }
  else if (estado == GRABANDO) {
    drawGrabando();
  }
  else if (estado == JUGANDO) {
    actualizarJuego();
    drawJuego();
  }

  drawFooter();
}


// MENU
void drawMenu() {
  textAlign(CENTER, CENTER);

  fill(colAcento);
  textSize(58);
  text("BEATMASTER", width/2, 95);

  fill(colTexto);
  textSize(24);
  text("Alpha jugable para PEC3", width/2, 145);

  noStroke();
  fill(colPanel);
  rect(240, 215, width - 480, 300, 18);

  fill(colTexto);
  textSize(26);
  text("[1] Grabar patrón", width/2, 285);
  text("[2] Jugar patrón grabado", width/2, 345);

  fill(colTextoSuave);
  textSize(18);
  text("Teclado: A = bombo · S = caja · D = charles · F = plato", width/2, 415);
  text("Eventos grabados: " + eventos.size(), width/2, 455);

  fill(colLineaGolpe);
  textSize(16);
  text("Esta versión permite probar la mecánica principal, pero todavía no representa el producto final.", width/2, 560);
}


// GRABACION
void drawGrabando() {
  textAlign(CENTER, CENTER);

  fill(colAcento);
  textSize(42);
  text("Grabando patrón", width/2, 80);

  fill(colTextoSuave);
  textSize(18);
  text("Toca con el dispositivo MIDI o con A, S, D, F", width/2, 130);
  text("Pulsa G para guardar la sesión y volver al menú", width/2, 165);

  // bolita parpadeante tipo OBS
  fill(220, 30, 40, 180 + 60 * sin(frameCount * 0.15));
  noStroke();
  ellipse(70, 70, 24, 24);

  fill(colTexto);
  textSize(22);
  text("Eventos registrados: " + eventos.size(), width/2, 220);
  text("Tiempo: " + ((millis() - tiempoInicioGrabacion) / 1000) + " s", width/2, 255);

  drawTimeline();
  drawPads();
}


// JUEGO
void actualizarJuego() {
  int t = millis() - tiempoInicioJuego;

  for (int i = 0; i < eventos.size(); i++) {
    if (yaResuelto[i]) continue;
    EventoBateria e = eventos.get(i);

    // si pasó de margen sin tocar, fallo
    if (t - e.tiempoMs > margen) {
      yaResuelto[i] = true;
      errores++;
      combo = 0;
      feedback = "MISS";
    }
  }

  // se acabó la canción
  if (eventos.size() > 0) {
    EventoBateria ultima = eventos.get(eventos.size() - 1);
    if (t > ultima.tiempoMs + 1800) {
      estado = MENU;
      feedback = "FIN";
    }
  }
}


void drawJuego() {
  drawPistas();
  drawLineaGolpe();
  drawNotas();

  fill(colTexto);
  textAlign(LEFT, TOP);
  textSize(22);
  text("Score: " + score, 40, 45);
  text("Aciertos: " + aciertos, 40, 75);
  text("Errores: " + errores, 40, 105);
  text("Combo: " + combo, 40, 135);

  fill(colLineaGolpe);
  textAlign(CENTER, TOP);
  textSize(34);
  text(feedback, width/2, 35);

  fill(colTextoSuave);
  textSize(16);
  text("ESC: volver al menú", width/2, height - 50);
}


void drawPistas() {
  String[] nombres = {"Bombo", "Caja", "Charles", "Plato"};

  for (int i = 0; i < 4; i++) {
    float x = laneX(i);

    noStroke();
    fill(colorPorIndice(i), 45);
    rect(x - 65, laneTopY, 130, hitLineY - laneTopY, 18);

    stroke(90);
    strokeWeight(2);
    line(x, laneTopY, x, hitLineY);

    noStroke();
    fill(colTexto);
    textAlign(CENTER, CENTER);
    textSize(17);
    text(nombres[i], x, hitLineY + 45);
  }
}


void drawLineaGolpe() {
  stroke(colLineaGolpe);
  strokeWeight(5);
  line(120, hitLineY, width - 120, hitLineY);

  noStroke();
  fill(colLineaGolpe, 45);
  rect(120, hitLineY - 10, width - 240, 20, 10);
}


void drawNotas() {
  int t = millis() - tiempoInicioJuego;

  for (int i = 0; i < eventos.size(); i++) {
    if (yaResuelto[i]) continue;

    EventoBateria e = eventos.get(i);
    int diferencia = e.tiempoMs - t;

    if (diferencia < -margen) continue;
    if (diferencia > anticipacion) continue;

    // cuanto más cerca en tiempo, más abajo en pantalla
    float y = map(diferencia, anticipacion, 0, laneTopY, hitLineY);
    float x = laneXFromNota(e.nota);

    drawNota(e.nota, x, y);
  }
}


void drawNota(int nota, float x, float y) {
  int c = colorPorNota(nota);
  noStroke();
  fill(c);
  ellipse(x, y, 46, 46);
  fill(20);
  textAlign(CENTER, CENTER);
  textSize(13);
  text(nombreCorto(nota), x, y);
}


void drawTimeline() {
  float x = 180;
  float y = 330;
  float w = width - 360;
  float h = 36;

  noStroke();
  fill(35, 40, 60);
  rect(x, y, w, h, 8);

  int dur = max(millis() - tiempoInicioGrabacion, 1); // evitar /0

  for (EventoBateria e : eventos) {
    float nx = map(e.tiempoMs, 0, dur, x, x + w);
    fill(colorPorNota(e.nota));
    rect(nx, y + 7, 4, h - 14);
  }
}


void drawPads() {
  drawPad(300,  505, "Bombo",   MIDI_BOMBO);
  drawPad(545,  505, "Caja",    MIDI_CAJA);
  drawPad(790,  505, "Charles", MIDI_CHARLES);
  drawPad(1035, 505, "Plato",   MIDI_PLATO);
}


void drawPad(float x, float y, String nombre, int nota) {
  int c = colorPorNota(nota);
  noStroke();
  fill(c);
  ellipse(x, y, 150, 150);
  fill(20);
  textAlign(CENTER, CENTER);
  textSize(15);
  text(nombre, x, y);
}


void drawFooter() {
  fill(colTextoSuave);
  textAlign(LEFT, BOTTOM);
  textSize(14);
  text(infoMIDI, 16, height - 14);
  textAlign(RIGHT, BOTTOM);
  text("BeatMaster · alpha PEC3", width - 16, height - 14);
}


void iniciarGrabacion() {
  eventos.clear();
  tiempoInicioGrabacion = millis();
  feedback = "GRABANDO";
  estado = GRABANDO;
}


void finalizarGrabacion() {
  guardarTXT();
  estado = MENU;
}


void iniciarJuego() {
  if (eventos.size() == 0) {
    feedback = "NO HAY PATRÓN";
    return;
  }

  yaResuelto = new boolean[eventos.size()];
  score = 0;
  aciertos = 0;
  errores = 0;
  combo = 0;
  feedback = "EMPIEZA";
  tiempoInicioJuego = millis();
  estado = JUGANDO;
}


// punto de entrada para los golpes (MIDI o teclado)
void gestionarInput(int note, int velocity) {
  if (estado == GRABANDO) {
    int t = millis() - tiempoInicioGrabacion;
    eventos.add(new EventoBateria(note, velocity, t));
  }
  if (estado == JUGANDO) {
    evaluarGolpe(note);
  }
  println("nota: " + note + " vel: " + velocity);
}


void evaluarGolpe(int note) {
  int t = millis() - tiempoInicioJuego;
  int mejorIdx = -1;
  int mejorDelta = 999999;

  // busco la nota más cercana en tiempo del mismo instrumento
  for (int i = 0; i < eventos.size(); i++) {
    if (yaResuelto[i]) continue;
    EventoBateria e = eventos.get(i);
    if (normalizarNota(e.nota) != normalizarNota(note)) continue;

    int delta = abs(t - e.tiempoMs);
    if (delta < mejorDelta) {
      mejorDelta = delta;
      mejorIdx = i;
    }
  }

  if (mejorIdx != -1 && mejorDelta <= margen) {
    yaResuelto[mejorIdx] = true;
    aciertos++;
    combo++;
    score += 100 + combo * 5;
    feedback = mejorDelta < 70 ? "PERFECTO" : "BIEN";
  } else {
    errores++;
    combo = 0;
    feedback = "MISS";
  }
}


// algunos pads mandan 41 en vez de 49 para el plato
int normalizarNota(int nota) {
  if (nota == 41) return MIDI_PLATO;
  return nota;
}


void guardarTXT() {
  if (eventos.size() == 0) return;

  String fecha = new SimpleDateFormat("yyyyMMdd_HHmmss").format(new Date());
  String nombreArchivo = "beatmaster_alpha_" + fecha + ".txt";

  String[] lineas = new String[eventos.size() + 1];
  lineas[0] = "nota\tvelocidad\ttiempoMs";

  for (int i = 0; i < eventos.size(); i++) {
    EventoBateria e = eventos.get(i);
    lineas[i + 1] = e.nota + "\t" + e.velocidad + "\t" + e.tiempoMs;
  }

  saveStrings(nombreArchivo, lineas);
  println("guardado: " + nombreArchivo);
}


void conectarMidi() {
  try {
    MidiDevice.Info[] infos = MidiSystem.getMidiDeviceInfo();
    for (MidiDevice.Info info : infos) {
      MidiDevice dev = MidiSystem.getMidiDevice(info);
      if (midiInputDevice == null && dev.getMaxTransmitters() != 0) {
        midiInputDevice = dev;
      }
    }

    if (midiInputDevice != null) {
      midiInputDevice.open();
      Transmitter t = midiInputDevice.getTransmitter();
      t.setReceiver(new MidiInputReceiver());
      infoMIDI = "MIDI conectado: " + midiInputDevice.getDeviceInfo().getName();
    } else {
      infoMIDI = "No se encontró entrada MIDI. Se puede usar teclado.";
    }
  }
  catch(Exception e) {
    infoMIDI = "Error al conectar MIDI. Se puede usar teclado.";
  }
}


// el NoteOff a veces llega como NoteOn con vel 0, hay que filtrarlo
class MidiInputReceiver implements Receiver {
  public void send(MidiMessage msg, long timeStamp) {
    byte[] b = msg.getMessage();
    if (b.length >= 3) {
      int status = b[0] & 0xFF;
      int note   = b[1] & 0xFF;
      int vel    = b[2] & 0xFF;
      if (status >= 144 && status <= 159 && vel > 0) {
        gestionarInput(note, vel);
      }
    }
  }
  public void close() {}
}


void keyPressed() {
  if (estado == MENU && key == '1') { iniciarGrabacion(); return; }
  if (estado == MENU && key == '2') { iniciarJuego();     return; }

  if (estado == GRABANDO && (key == 'g' || key == 'G')) {
    finalizarGrabacion();
    return;
  }

  // truco para que ESC no cierre processing
  if (estado == JUGANDO && keyCode == ESC) {
    key = 0;
    estado = MENU;
    return;
  }

  if (key == 'a' || key == 'A') gestionarInput(MIDI_BOMBO,   100);
  if (key == 's' || key == 'S') gestionarInput(MIDI_CAJA,    100);
  if (key == 'd' || key == 'D') gestionarInput(MIDI_CHARLES, 100);
  if (key == 'f' || key == 'F') gestionarInput(MIDI_PLATO,   100);
}


float laneX(int i) {
  if (i == 0) return 320;
  if (i == 1) return 560;
  if (i == 2) return 800;
  return 1040;
}


float laneXFromNota(int nota) {
  int n = normalizarNota(nota);
  if (n == MIDI_BOMBO)   return laneX(0);
  if (n == MIDI_CAJA)    return laneX(1);
  if (n == MIDI_CHARLES) return laneX(2);
  return laneX(3);
}


// colores tipo Guitar Hero
int colorPorNota(int nota) {
  int n = normalizarNota(nota);
  if (n == MIDI_BOMBO)   return color(60, 200, 70);    // verde
  if (n == MIDI_CAJA)    return color(220, 30, 40);    // rojo
  if (n == MIDI_CHARLES) return color(255, 230, 60);   // amarillo
  return color(40, 130, 230);                          // azul
}


int colorPorIndice(int i) {
  int[] notas = {MIDI_BOMBO, MIDI_CAJA, MIDI_CHARLES, MIDI_PLATO};
  return colorPorNota(notas[i]);
}


String nombreCorto(int nota) {
  int n = normalizarNota(nota);
  if (n == MIDI_BOMBO)   return "K";
  if (n == MIDI_CAJA)    return "S";
  if (n == MIDI_CHARLES) return "H";
  return "C";
}


class EventoBateria {
  int nota;
  int velocidad;
  int tiempoMs;

  EventoBateria(int nota, int velocidad, int tiempoMs) {
    this.nota = nota;
    this.velocidad = velocidad;
    this.tiempoMs = tiempoMs;
  }
}
