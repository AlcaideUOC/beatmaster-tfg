/*
BeatMaster

Primera versión del proyecto.

En esta fase solo quiero comprobar que Processing recibe correctamente
las notas MIDI de la batería electrónica. Antes de implementar sonidos
o mecánicas de juego, es importante verificar que el sistema detecta
los golpes del instrumento.

También he añadido control por teclado para poder probar el programa
aunque no haya un dispositivo MIDI conectado.
*/

import javax.sound.midi.*;

// Notas MIDI típicas de batería
final int MIDI_BOMBO = 36;
final int MIDI_CAJA = 38;
final int MIDI_CHARLES = 46;
final int MIDI_PLATO = 49;

// Variable donde guardaré el dispositivo MIDI
MidiDevice device;

// Información que se mostrará en pantalla
String ultimoGolpe = "Esperando entrada...";
int velocidad = 0;


// --------------------------------------------------
// setup()
// Aquí se inicializa la ventana y se prepara la conexión MIDI
// --------------------------------------------------

void setup(){

  size(900,600);

  textAlign(CENTER,CENTER);
  textSize(32);

  iniciarMIDI();

}


// --------------------------------------------------
// draw()
// Se ejecuta continuamente y muestra la información en pantalla
// --------------------------------------------------

void draw(){

  background(20);

  fill(255);
  text("BeatMaster - prueba de entrada", width/2, 80);

  fill(200);
  text("Último golpe detectado:", width/2, 220);

  fill(255,200,0);
  text(ultimoGolpe, width/2, 300);

  fill(180);
  text("Velocidad: " + velocidad, width/2, 360);

  fill(120);
  text("Teclado de prueba", width/2, 470);

  textSize(18);
  text("A = bombo   S = caja   D = charles   F = plato", width/2, 510);

  textSize(32);

}


// --------------------------------------------------
// iniciarMIDI()
// Busca dispositivos MIDI disponibles y se conecta al primero
// que pueda enviar datos
// --------------------------------------------------

void iniciarMIDI(){

  try{

    MidiDevice.Info[] infos = MidiSystem.getMidiDeviceInfo();

    for(int i=0;i<infos.length;i++){

      MidiDevice dispositivo = MidiSystem.getMidiDevice(infos[i]);

      // Solo nos interesan los dispositivos que transmiten datos
      if(dispositivo.getMaxTransmitters()!=0){

        device = dispositivo;
        device.open();

        Transmitter transmitter = device.getTransmitter();
        transmitter.setReceiver(new BeatMasterReceiver());

        println("Dispositivo MIDI conectado: " + infos[i].getName());
        return;

      }

    }

    println("No se encontró dispositivo MIDI.");

  }
  catch(Exception e){

    e.printStackTrace();

  }

}


// --------------------------------------------------
// Clase que recibe los mensajes MIDI
// --------------------------------------------------

class BeatMasterReceiver implements Receiver{

  public void send(MidiMessage message,long timeStamp){

    if(message instanceof ShortMessage){

      ShortMessage sm = (ShortMessage)message;

      // Nos interesan los NOTE_ON
      if(sm.getCommand()==ShortMessage.NOTE_ON){

        int nota = sm.getData1();
        int vel = sm.getData2();

        // Si la velocidad es mayor que 0 significa que se ha golpeado
        if(vel>0){

          gestionarInput(nota,vel);

        }

      }

    }

  }

  public void close(){}

}


// --------------------------------------------------
// gestionarInput()
// Interpreta la nota recibida y la traduce a un instrumento
// --------------------------------------------------

void gestionarInput(int nota,int vel){

  velocidad = vel;

  if(nota==MIDI_BOMBO){

    ultimoGolpe = "BOMBO";

  }
  else if(nota==MIDI_CAJA){

    ultimoGolpe = "CAJA";

  }
  else if(nota==MIDI_CHARLES){

    ultimoGolpe = "CHARLES";

  }
  else if(nota==MIDI_PLATO){

    ultimoGolpe = "PLATO";

  }
  else{

    ultimoGolpe = "Nota MIDI: " + nota;

  }

}


// --------------------------------------------------
// keyPressed()
// Permite probar el sistema usando el teclado
// --------------------------------------------------

void keyPressed(){

  // ESC para cerrar el programa
  if(keyCode==ESC){

    key=0;
    exit();

  }

  if(key=='a'||key=='A') gestionarInput(MIDI_BOMBO,100);
  if(key=='s'||key=='S') gestionarInput(MIDI_CAJA,100);
  if(key=='d'||key=='D') gestionarInput(MIDI_CHARLES,100);
  if(key=='f'||key=='F') gestionarInput(MIDI_PLATO,100);

}
