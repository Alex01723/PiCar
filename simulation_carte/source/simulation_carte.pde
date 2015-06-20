import java.util.List;
import java.util.ArrayList;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.nio.ByteBuffer;
import java.nio.LongBuffer;
import java.nio.channels.FileChannel;

import java.io.FileWriter;
import java.io.IOException;

final String dest = "../simulation.gpx";
double lat = 46.215075;
double lon = 5.241613;
int heure = 12;
int minute = 10;
int seconde = 0;
String bufferSeconde = "0";

boolean sortir = false;
int nbTraces = 400;

void keyPressed() {
  if (key == ' ') {
    sortir = true;
  }
}

void setup() {
  try {
    new FileWriter(new File(dest)).close();
  } catch (IOException ex) {
      ex.printStackTrace();
  }
  
  FileWriter writer = null;
  String texte = "<?xml version=\"1.0\" encoding=\"utf-8\"?><gpx version=\"1.1\" creator=\"GPSD 3.6 - http://catb.org/gpsd\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns=\"http://www.topografix.com/GPX/1/1\" xsi:schemaLocation=\"http://www.topografix.com/GPX/1/1 http://www.topografix.com/GPX/1/1/gpx.xsd\"><metadata><time>2015-02-16T15:20:47.000Z</time></metadata><trk><src>GPSD 3.6</src><trkseg>";

  try { 
    writer = new FileWriter(dest, true);
    writer.write(texte, 0, texte.length());
  } 
  catch(IOException ex) {
    ex.printStackTrace();
  } finally {
    if (writer != null) {
      try {
        writer.close();
      } catch(IOException ex) {
        ex.printStackTrace();
      }
    }
  }

  System.out.println("LANCEMENT DE LA SIMULATION");
  int compteur = 0;
  while (!sortir) {   
    delay(1000);
    
    // Pour que le temps réel s'arrête
    if (compteur == nbTraces) {
        System.out.println("FIN DE LA SIMULATION");
        break; 
    }
    
    compteur++;
    
    if (seconde < 10) {
       bufferSeconde = "0"; 
    } else {
       bufferSeconde = ""; 
    }
    
    // System.out.println(heure + " " + minute + " " + bufferSeconde + seconde);
    FileWriter writer2 = null;
    texte = "\n<trkpt lat=\"" + lat + "\" lon=\"" + lon + "\">\n<ele>-40.700000</ele>\n<time>2015-06-16T" + heure + ":" + minute + ":" + bufferSeconde + seconde + ".000Z</time><src>GPSD tag=\"GLL\"\n</src><fix>3d</fix>\n<sat>3</sat>\n</trkpt>";
    
    if (Math.random() > 0.8) {
      lon += (Math.random() / (double) 5000);
    } else {
      lon -= (Math.random() / (double) 5000);
    }
    
    if (Math.random() > 0.8) {
      lat += (Math.random() / (double) 5000);
    } else {
      lat -= (Math.random() / (double) 5000);
    }
    
    try {
      writer2 = new FileWriter(dest, true);
      writer2.write(texte, 0, texte.length());
    } 
    catch(IOException ex) {
      ex.printStackTrace();
    } 
    finally {
      if (writer2 != null) {
        try {
          writer2.close();
        } catch(IOException ex) {
          ex.printStackTrace();
        }
      }
    }

    seconde++;
    if (seconde == 60) {
      seconde = 0;
      minute++;
    }
  }

  // Rendre l'arborescence du fichier final correcte
  /* FileWriter writer3 = null;
  texte = "</trkseg></trk></gpx>";

  try {
    writer3 = new FileWriter(dest, true);
    writer3.write(texte, 0, texte.length());
  } catch(IOException ex) {
    ex.printStackTrace();
  } finally {
    if (writer3 != null) {
      try {
          writer3.close();
      } catch(IOException ex) {
        ex.printStackTrace();
      }
    }
  } */
}

