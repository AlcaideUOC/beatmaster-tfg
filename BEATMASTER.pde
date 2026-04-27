import javax.sound.midi.*;

/*
BeatMaster

Esta versión parte de la primera prueba de entrada MIDI.
El objetivo sigue siendo comprobar que Processing recibe correctamente
los golpes de una batería electrónica, pero se añade una interfaz más
clara y un pequeño registro de los golpes detectados.

También se mantiene el control por teclado para poder probar el programa
aunque no haya ningún dispositivo MIDI conectado.

En esta fase todavía no hay grabación de patrones, guardado de archivos
ni mecánica jugable.
*/


// ─────────────────────────────
// Notas MIDI principales
// ─────────────────────────────

final int MIDI_BOMBO   = 36;
final int MIDI_CAJA    = 38;
final int MIDI_CHARLES = 46;
final int MIDI_PLATO   = 49;


// ─────────────────────────────
// Variables de entrada MIDI
// ─────────────────────────────

MidiDevice device;
Receiver receiver;

boolean midiConectado = false;
String infoMIDI = "Buscando dispositivo MIDI...";


// ─────────────────────────────
// Información del último golpe
// ─────────────────────────────

String ultimoGolpe = "Esperando entrada...";
int ultimaNota = 0;
int velocidad = 0;
int totalGolpes = 0;


// ─────────────────────────────
// Contadores por instrumento
// ─────────────────────────────

int golpesBombo = 0;
int golpesCaja = 0;
int golpesCharles = 0;
int golpesPlato = 0;
int golpesOtros = 0;


// ─────────────────────────────
// Colores de la interfaz
// ─────────────────────────────

int colFondo = color(20);
int colTexto = color(240);
int colTextoSuave = color(170);
int colAcento = color(255, 200, 0);
int colPanel = color(45, 50, 70);


// ─────────────────────────────
// setup()
// Inicializa la ventana y prepara la conexión MIDI
// ─────────────────────────────

void setup() {
  size(900, 600);

  surface.setTitle("BeatMaster - prueba MIDI ampliada");

  textAlign(CENTER, CENTER);
  textSize(28);

  iniciarMIDI();
}


// ─────────────────────────────
// draw()
// Muestra en pantalla la información de entrada
// ─────────────────────────────

void draw() {
  background(colFondo);

  dibujarTitulo();
  dibujarPanelPrincipal();
  dibujarContadores();
  dibujarAyudaTeclado();
  dibujarEstadoMIDI();
}


// ─────────────────────────────
// Título principal
// ─────────────────────────────

void dibujarTitulo() {
  fill(colAcento);
  textSize(40);
  text("BeatMaster", width/2, 55);

  fill(colTextoSuave);
  textSize(18);
  text("Prueba ampliada de entrada MIDI", width/2, 95);
}


// ─────────────────────────────
// Panel central con el último golpe detectado
// ─────────────────────────────

void dibujarPanelPrincipal() {
  noStroke();
  fill(colPanel);
  rect(90, 135, width - 180, 210, 18);

  fill(colTextoSuave);
  textSize(20);
  text("Último golpe detectado", width/2, 175);

  fill(colAcento);
  textSize(42);
  text(ultimoGolpe, width/2, 235);

  fill(colTexto);
  textSize(20);
  text("Nota MIDI: " + ultimaNota, width/2, 290);
  text("Velocidad: " + velocidad, width/2, 320);
}


// ─────────────────────────────
// Contadores de golpes por instrumento
// ─────────────────────────────

void dibujarContadores() {
  fill(colTexto);
  textSize(20);
  text("Golpes registrados: " + totalGolpes, width/2, 380);

  fill(colTextoSuave);
  textSize(16);
  text("Bombo: " + golpesBombo +
       "   Caja: " + golpesCaja +
       "   Charles: " + golpesCharles +
       "   Plato: " + golpesPlato +
       "   Otros: " + golpesOtros, width/2, 420);
}


// ─────────────────────────────
// Instrucciones para probar con teclado
// ─────────────────────────────

void dibujarAyudaTeclado() {
  fill(colTextoSuave);
  textSize(16);
  text("Teclado de prueba", width/2, 485);

  fill(colTexto);
  text("A = bombo   S = caja   D = charles   F = plato", width/2, 515);

  fill(colTextoSuave);
  text("ESC = salir", width/2, 545);
}


// ─────────────────────────────
// Estado de la conexión MIDI
// ─────────────────────────────

void dibujarEstadoMIDI() {
  fill(colTextoSuave);
  textAlign(LEFT, BOTTOM);
  textSize(13);
  text(infoMIDI, 16, height - 14);

  textAlign(CENTER, CENTER);
}


// ─────────────────────────────
// iniciarMIDI()
// Busca dispositivos MIDI disponibles y conecta el primero válido
// ─────────────────────────────

void iniciarMIDI() {
  try {
    MidiDevice.Info[] infos = MidiSystem.getMidiDeviceInfo();

    for (int i = 0; i < infos.length; i++) {
      MidiDevice dispositivo = MidiSystem.getMidiDevice(infos[i]);

      if (dispositivo.getMaxTransmitters() != 0) {
        device = dispositivo;
        device.open();

        Transmitter transmitter = device.getTransmitter();
        receiver = new BeatMasterReceiver();

        transmitter.setReceiver(receiver);

        midiConectado = true;
        infoMIDI = "MIDI conectado: " + infos[i].getName();

        println(infoMIDI);
        return;
      }
    }

    midiConectado = false;
    infoMIDI = "No se encontró dispositivo MIDI. Puedes usar el teclado.";
    println(infoMIDI);
  }
  catch(Exception e) {
    midiConectado = false;
    infoMIDI = "Error al iniciar MIDI. Puedes usar el teclado.";
    e.printStackTrace();
  }
}


// ─────────────────────────────
// Clase que recibe los mensajes MIDI
// ─────────────────────────────

class BeatMasterReceiver implements Receiver {

  public void send(MidiMessage message, long timeStamp) {
    if (message instanceof ShortMessage) {
      ShortMessage sm = (ShortMessage) message;

      if (sm.getCommand() == ShortMessage.NOTE_ON) {
        int nota = sm.getData1();
        int vel = sm.getData2();

        if (vel > 0) {
          gestionarInput(nota, vel);
        }
      }
    }
  }

  public void close() {
  }
}


// ─────────────────────────────
// gestionarInput()
// Interpreta la nota recibida y actualiza la información visual
// ─────────────────────────────

void gestionarInput(int nota, int vel) {
  ultimaNota = nota;
  velocidad = vel;
  totalGolpes++;

  if (nota == MIDI_BOMBO) {
    ultimoGolpe = "BOMBO";
    golpesBombo++;
  } else if (nota == MIDI_CAJA) {
    ultimoGolpe = "CAJA";
    golpesCaja++;
  } else if (nota == MIDI_CHARLES) {
    ultimoGolpe = "CHARLES";
    golpesCharles++;
  } else if (nota == MIDI_PLATO) {
    ultimoGolpe = "PLATO";
    golpesPlato++;
  } else {
    ultimoGolpe = "OTRA NOTA";
    golpesOtros++;
  }

  println("Nota MIDI: " + nota + " | Velocidad: " + vel);
}


// ─────────────────────────────
// keyPressed()
// Permite probar el sistema usando el teclado
// ─────────────────────────────

void keyPressed() {
  if (keyCode == ESC) {
    key = 0;
    exit();
  }

  if (key == 'a' || key == 'A') {
    gestionarInput(MIDI_BOMBO, 100);
  }

  if (key == 's' || key == 'S') {
    gestionarInput(MIDI_CAJA, 100);
  }

  if (key == 'd' || key == 'D') {
    gestionarInput(MIDI_CHARLES, 100);
  }

  if (key == 'f' || key == 'F') {
    gestionarInput(MIDI_PLATO, 100);
  }
}
