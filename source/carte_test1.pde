// À FAIRE POUR REPASSER LE PROJET SOUS RASPBERRY PI :
//    - Décommenter les lignes d'ajout de fin de fichier XML : FAIT.

import de.fhpotsdam.unfolding.*;
import de.fhpotsdam.unfolding.providers.*;
import de.fhpotsdam.unfolding.geo.*;
import de.fhpotsdam.unfolding.geo.Location;
import de.fhpotsdam.unfolding.data.*;
import de.fhpotsdam.unfolding.data.Feature;
import de.fhpotsdam.unfolding.data.MarkerFactory;
import de.fhpotsdam.unfolding.events.EventDispatcher;
import de.fhpotsdam.unfolding.providers.StamenMapProvider;
import de.fhpotsdam.unfolding.utils.*;
import de.fhpotsdam.unfolding.marker.*;
import de.fhpotsdam.unfolding.utils.MapUtils;
import de.fhpotsdam.unfolding.utils.GeoUtils;
import de.fhpotsdam.unfolding.interactions.*;

import java.util.List;
import java.util.ArrayList;
import java.util.EnumSet;
import java.util.Calendar;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.nio.ByteBuffer;
import java.nio.LongBuffer;
import java.nio.channels.FileChannel;

/* import com.pi4j.io.gpio.GpioController;
import com.pi4j.io.gpio.GpioFactory;
import com.pi4j.io.gpio.GpioPin;
import com.pi4j.io.gpio.GpioPinDigitalInput;
import com.pi4j.io.gpio.GpioPinDigitalOutput;
import com.pi4j.io.gpio.PinDirection;
import com.pi4j.io.gpio.PinMode;
import com.pi4j.io.gpio.PinPullResistance;
import com.pi4j.io.gpio.PinState;
import com.pi4j.io.gpio.RaspiPin;
import com.pi4j.io.gpio.trigger.GpioCallbackTrigger;
import com.pi4j.io.gpio.trigger.GpioPulseStateTrigger;
import com.pi4j.io.gpio.trigger.GpioSetStateTrigger;
import com.pi4j.io.gpio.trigger.GpioSyncStateTrigger;
import com.pi4j.io.gpio.event.GpioPinListener;
import com.pi4j.io.gpio.event.GpioPinDigitalStateChangeEvent;
import com.pi4j.io.gpio.event.GpioPinEvent;
import com.pi4j.io.gpio.event.GpioPinListenerDigital;
import com.pi4j.io.gpio.event.PinEventType; */

import java.io.FileWriter;
import java.io.IOException;

import java.applet.*;
import java.awt.*;
import processing.core.*;
import processing.core.PApplet;
import processing.core.PGraphics;
import processing.core.PImage;

// VARIABLES RELATIVES AUX DESSINS DE LA CARTE
UnfoldingMap map;
UnfoldingMap map1, map2, map3;

List<Feature> features;
List<Location> liste_locations;
MarkerManager<Marker> markerManager;
SimpleLinesMarker ligne;

ArrayList<SimplePointMarker> marqueurs;
ArrayList<String> marqueurs_desc;

final String src = "simulation.gpx";
final String dest = "carte.gpx";

// VARIABLES RELATIVES AU FONCTIONNEMENT DE LA FENÊTRE
int compteur = 0;
int delaiAttente = 1000;
boolean modeTpsReel = false;

void setup() {
  size(1100, 600);
  frameRate(60);
  frame.setTitle("Semaine spéciale 2 - GPS");

  // Création des différentes cartes
  map1 = new UnfoldingMap(this, new Google.GoogleMapProvider());
  map2 = new UnfoldingMap(this, new Microsoft.AerialProvider());
  map3 = new UnfoldingMap(this, new Microsoft.RoadProvider());
  MapUtils.createDefaultEventDispatcher(this, map1, map2, map3);  

  map = map2;   
  map.zoomAndPanTo(new Location(46.215075f, 5.241613f), 18);        // Par défaut, on initialise la position sur l'IUT. L'enregistrement en temps réel la change.

  marqueurs = new ArrayList();
  marqueurs_desc = new ArrayList();

  markerManager = map.getDefaultMarkerManager();
  copyFile(src, dest);
  updateCarte(false);
}

void draw() {
  background(color(50, 50, 50));  
  map.draw();
  
  if (modeTpsReel == true) {
    delay(1000);
    markerManager.clearMarkers();

    copyFile(src, dest);
    updateCarte(false);
  }

  map.updateMap();
  compteur++;

  // Configuration des ellipses
  if ((!modeTpsReel) || (modeTpsReel)) {
    fill(255, 192, 0);       
    noStroke();
    int i = 0;
    for (SimplePointMarker marqueur : marqueurs) {     
      fill(255, 192, 0);
      i++;
      ScreenPosition positionM = marqueur.getScreenPosition(map);
      ellipse(positionM.x, positionM.y, 30, 30);

      fill(0, 0, 0);
      textSize(15);
      text(i, (positionM.x - textWidth(Integer.toString(i))) + ((30 - textWidth(Integer.toString(i))) / 4), positionM.y + 4);

      // Si on rencontre un marqueur en temps réel
      boolean doitEteindre = false;
      if (marqueur.isInside(map.getScreenPosition(map.getCenter()).x, map.getScreenPosition(map.getCenter()).y, map.getScreenPosition(marqueur.getLocation()).x, map.getScreenPosition(marqueur.getLocation()).y)) {
        allumerLED();
        doitEteindre = true;
      } else {
        if (doitEteindre) {
            eteindreLED();
            doitEteindre = false;  
        }
      }
    }
  }
  
  // Configuration des boutons de choix
  int rectDimL = 100;
  int rectDimH = 30;

  fill(250, 250, 250);
  stroke(50, 50, 50, 255);
  rect(15, height - rectDimH - 15, rectDimL, rectDimH);

  textSize(12);
  fill(50, 50, 50);
  if (modeTpsReel) {
    text("TEMPS RÉEL", 15 + 15, height - rectDimH - 15 + 20);
  } else {
    text("MODE ARRÊTÉ", 15 + 8, height - rectDimH - 15 + 20);
  }

  // Configuration des coordonnées
  Location location = map.mapDisplay.getLocation(mouseX, mouseY);
  text("Latitude : " + location.getLat(), 15 + 15 + rectDimL, height - rectDimH - 15 + 13);
  text("Longitude : " + location.getLon(), 15 + 15 + rectDimL, height - rectDimH + 13);
}

void updateCarte(boolean premierPassage) {
  int taille_ll = 0;
  features = GPXReader.loadData(this, dest);   
  ShapeFeature sfeature = (ShapeFeature) features.get(0);
  ligne = new SimpleLinesMarker(sfeature.getLocations());

  if ((premierPassage) || (modeTpsReel == true)) {
    // CENTRER LA CARTE SUR LE DERNIER POINT OBTENU
    liste_locations = sfeature.getLocations();
    taille_ll = liste_locations.size();
    
    if (taille_ll > 0) {
      map.zoomAndPanTo(liste_locations.get(taille_ll - 1), 18);
      
    }
  }  

  ligne.setColor(color(200, 0, 0));
  ligne.setHighlightColor(color(0, 200, 0));
  ligne.setStrokeWeight(5);

  markerManager.addMarker(ligne);

  int rectDimL = 130;
  int rectDimH = 30;    

  fill(250, 250, 250);
  stroke(50, 50, 50, 255);
  rect(width - rectDimL - 15, height - rectDimH - 15, rectDimL, rectDimH);

  textSize(12);
  fill(50, 50, 50);

  // Le programme affiche la dernière ligne, puis calcule la vitesse qui va avec
  text("VITESSE : ", width - rectDimL - 15 + 5, height - rectDimH - 15 + 20);
  if (taille_ll > 2) {     
    System.out.println("ÉCHELLE : " + map.getScaleFromZoom(map.getZoom()));
    double distance = GeoUtils.getDistance(liste_locations.get(taille_ll - 2), liste_locations.get(taille_ll - 3));      // Distance en kilomètres

    double speed = distance / (double) 0.000277777778;  // Nombre d'heures dans une seconde
    text( (double)Math.round(speed * 10) / 10 + " km/h", width - rectDimL - 15 + 60, height - rectDimH - 15 + 20);
    System.out.println("VITESSE : " + (double)Math.round(speed * 10) / 10 + " km/h");
  }
}

void keyReleased() {
  if (key == ' ') {
    marqueurs.add(new SimplePointMarker(map.getCenter()));
    marqueurs_desc.add("Message de repérage de zone par défaut");
  } else if (key == '1') {
    map = map1; 
    markerManager = map.getDefaultMarkerManager();
    updateCarte(true);
  } else if (key == '2') {
    map = map2;
    markerManager = map.getDefaultMarkerManager();
    updateCarte(true);
  } else if (key == '3') {
    map = map3;
    markerManager = map.getDefaultMarkerManager();
    updateCarte(true);
  }
}

void mouseClicked(MouseEvent e) {
  int sX = e.getX();
  int sY = e.getY();

  if (clicMode(sX, sY)) {
    modeTpsReel = !modeTpsReel;
    map.draw();
  }

  if (modeTpsReel) {
    map.setZoomRange(18, 18);
  } else {
    map.setZoomRange(12, 18);
  }

  int index = 0;
  for (SimplePointMarker marqueur : marqueurs) {
    System.out.println(mouseX + " " + mouseY + " " + marqueur.getLocation());
    if (marqueur.isInside(mouseX, mouseY, map.getScreenPosition(marqueur.getLocation()).x, map.getScreenPosition(marqueur.getLocation()).y)) {
      System.out.println(index + " " + "YES" + " " + marqueurs_desc.get(index));
    }

    index++;
  }
}

void mousePressed() {
  int delaiAttente = 300;
}

void mouseReleased() {
  int delaiAttente = 1000;
}

boolean clicMode(int sX, int sY) {
  if ((sX >= 15) && (sX <= 115)) {
    if ((sY >= height - 30 - 15) && (sY <= height - 15)) {
      return true;
    }
  }

  System.out.println("..");
  return false;
}

void allumerLED() {
  exec(new String[] {"./LED"});                // Exécution dans le même dossier que l'application
}

void eteindreLED() {
  exec(new String[] {"./LED2"}); 
}

void copyFile(String src, String dest) {                
  FileChannel in = null; // Canal d'entrée
  FileChannel out = null; // Canal de sortie

  try {
    // Initialisation
    in = new FileInputStream(src).getChannel();
    out = new FileOutputStream(dest).getChannel();

    // Copie depuis le in vers le out
    in.transferTo(0, in.size(), out);

    // RENDRE L'ARBORESCENCE DU FICHIER FINAL CORRECTE
    FileWriter writer = null;
    String texte = "</trkseg></trk></gpx>";

    try {
      writer = new FileWriter(dest, true);
      writer.write(texte, 0, texte.length());
    } 
    catch(IOException ex) {
      ex.printStackTrace();
    } 
    finally {
      if (writer != null) {
        writer.close();
      }
    }
  } 
  catch (Exception e) {
    e.printStackTrace();
  } 
  finally {
    if (in != null) {
      try {
        in.close();
      } 
      catch (IOException e) { 
        ;
      }
    }

    if (out != null) {
      try {
        out.close();
      } 
      catch (IOException e) { 
        ;
      }
    }
  }
}

