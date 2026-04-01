import javax.sound.midi.*;
import ddf.minim.*;

// Estados básicos de la aplicación
final int INICIO = 0;
final int GRABANDO = 1;
int estado = INICIO;

// Objetos de audio
Minim minim;
AudioSample sBombo, sCaja, sCharles, sPlato;

// Indica si se ha detectado un dispositivo MIDI
boolean midiConectado = false;

// Tiempo inicial del programa
int tiempoInicio;

// Texto principal
String mensaje = "Iniciando sistema...";

void setup() {
  size(900, 600);
  textAlign(CENTER, CENTER);

  // Inicialización del sistema de audio
  minim = new Minim(this);

  // Carga de sonidos desde la carpeta data
  sBombo   = minim.loadSample("bombo.wav", 256);
  sCaja    = minim.loadSample("caja.wav", 256);
  sCharles = minim.loadSample("charles.wav", 256);
  sPlato   = minim.loadSample("plato.wav", 256);

  // Se intenta establecer conexión con el dispositivo MIDI
  conectarHardware();

  // Se guarda el instante inicial del programa
  tiempoInicio = millis();
}

void draw() {
  background(15);

  fill(255);
  textSize(36);

  if (!midiConectado) {
    mensaje = "No se ha detectado dispositivo MIDI";
    text(mensaje, width/2, height/2);
    return;
  }

  if (estado == INICIO) {
    mensaje = "¡Preparado!";
    text(mensaje, width/2, height/2);

    // Después de dos segundos pasa al estado de grabación
    if (millis() - tiempoInicio >= 2000) {
      estado = GRABANDO;
    }
  }

  else if (estado == GRABANDO) {
    mensaje = "Grabando...";
    text(mensaje, width/2, height/2);

    // Indicador visual de grabación
    fill(255, 0, 0, sin(frameCount * 0.1) * 100 + 155);
    ellipse(60, 60, 20, 20);
  }

  // Texto informativo para salir del programa
  fill(200);
  textSize(16);
  text("Pulsa ESC para salir de BeatMaster", width/2, height - 40);
}

// Reproducción de sonidos según la nota MIDI recibida
void gestionarInput(int nota, int vel) {
  if (nota == 36) sBombo.trigger();
  if (nota == 38) sCaja.trigger();
  if (nota == 41) sPlato.trigger();
  if (nota == 46) sCharles.trigger();
}

// Búsqueda de un dispositivo MIDI de entrada
void conectarHardware() {
  MidiDevice.Info[] infos = MidiSystem.getMidiDeviceInfo();

  for (MidiDevice.Info info : infos) {
    if ((info.getName().contains("UM-ONE") || info.getName().toUpperCase().contains("MIDI")) && getIn(info)) {
      try {
        MidiDevice dev = MidiSystem.getMidiDevice(info);
        dev.getTransmitter().setReceiver(new MidiInputReceiver());
        dev.open();
        midiConectado = true;
        break;
      } catch (Exception e) {
      }
    }
  }
}

// Receptor de mensajes MIDI
class MidiInputReceiver implements Receiver {
  public void send(MidiMessage msg, long timeStamp) {
    byte[] b = msg.getMessage();

    if (b.length >= 3 && (b[0] & 0xFF) >= 144 && (b[2] & 0xFF) > 0) {
      gestionarInput(b[1] & 0xFF, b[2] & 0xFF);
    }
  }

  public void close() {
  }
}

// Permite salir del programa con la tecla ESC
void keyPressed() {
  if (keyCode == ESC) {
    exit();
  }
}

// Comprueba si el dispositivo puede transmitir datos MIDI
boolean getIn(MidiDevice.Info info) {
  try {
    return MidiSystem.getMidiDevice(info).getMaxTransmitters() != 0;
  }
  catch (Exception e) {
    return false;
  }
}
