/*
  Brooke Mitchell CMPO211/311 Processing Code for Pentacle Interface and Live FFT Visualizing System
 
 
 Massive thanks to Fabio Varesio, extends freeeIMU cube demo code at, http://www.varesano.net/blog/fabio
 thanks to bloom for examples on drawing a dodecahedron http://processing.org/discourse/yabb2/YaBB.pl?num=1272064104/5
 perspective and lights testing taken from online examples http://processing.org/learning/3d/perspective.html
 
 Design of euler readings system and communications spec:
 Copyright (C) 2011 Fabio Varesano - http://www.varesano.net/
 
 This program is free software: you can redistribute it and/or modify
 it under the terms of the version 3 GNU General Public License as
 published by the Free Software Foundation.
 
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import processing.serial.*;
import processing.opengl.*;
import oscP5.*;
import netP5.*;

Serial myPort;  // USB Port
final String serialPort = "/dev/tty.usbserial-A8004xvi";

OscP5 oscP5;
NetAddress sendRemoteLocation;

int lf = 10; // 10 is '\n' in ASCII
byte[] inBuffer = new byte[22]; // this is the number of chars on each line from the Arduino (including /r/n)
float[] mapEurel = new float [euler.length];
float[] fPiezo = new float [piezo.length];

Delta1 delta1 = new Delta1();
Delta1 delta2 = new Delta1();
Delta1 delta3 = new Delta1();


//screen resolution
final int VIEW_SIZE_X = 1024, VIEW_SIZE_Y = 768;

boolean freefall;

public int[] hsv = new int [1];

PFont font;

float scaleVal = 18.0;
float angleInc = PI/  96.0;
float angle = 0.0;

int peak;
float rms;

void setup() 
{

  font = loadFont("CourierNew36.vlw"); 

  size(VIEW_SIZE_X, VIEW_SIZE_Y, OPENGL);

  smooth(); 
  noStroke();

  //init osc and serial
  myPort = new Serial(this, serialPort, 57600);
  oscP5 = new OscP5(this, 12000);

  //  oscP5.plug(this, "peak", "/peak");
  //  oscP5.plug(this, "rms", "/rms");


  sendRemoteLocation = new NetAddress("127.0.0.1", 12000);   

  delay(200);
  myPort.clear();
  myPort.write("1");
}

void draw() {
  background(190);
  // in values Map
  remapDirection();
  readQ();
  drawCube();

  //TEXT READOUT
  textFont(font, 20);
  textAlign(LEFT, TOP);
  text("q:\n" + q[0] + "\n" + q[1] + "\n" + q[2] + "\n" + q[3], 20, 10);
  text("euler Angles:\nYaw (psi)  : " + degrees(euler[0]) + "\nPitch (theta): " + degrees(euler[1]) + "\nRoll (phi)  : " + degrees(euler[2]), 200, 10);

  drawcompass(euler[0], VIEW_SIZE_X/2 - 350, VIEW_SIZE_Y/2, 200);
  drawAngle(euler[1], VIEW_SIZE_X/2, VIEW_SIZE_Y -120, 200, "Pitch:");
  drawAngle(euler[2], VIEW_SIZE_X/2 + 350, VIEW_SIZE_Y/2, 200, "Roll:");

  oscSend(euler);
  oscSend2(piezo);
  if (freefall == true) {
    oscSend3();
  }
  
    int test1 = abs(delta1.diff(degrees(euler[0])));
  int test2 = abs(delta2.diff(degrees(euler[1])));
  int test3 = abs(delta3.diff(degrees(euler[2])));
  
    text("Delta(Change):", 120, 580);
  text("X: ", 20, 615);

  rect(40, 600, test1, 15);
  text("Y: ", 20, 645);

  rect(40, 630, test2, 15);
  text("Z: ", 20, 675);

  rect(40, 660, test3, 15);
}

void oscSend(float[] euler) {
  OscBundle eulerBundle = new OscBundle();

  //arrayCopy(euler, constrEurel

  arraycopy(euler, mapEurel);

  for (int i = 0; i < 3; i++) {
    OscMessage eulerMessage = new OscMessage("/euler" + i);

    mapEurel[i] = map(degrees(mapEurel[i]), -180, 180, 0, 1);

    mapEurel[i] = constrain(mapEurel[i], 0.05, 0.95);

    eulerMessage.add(mapEurel[i]);   //add eulers[] to osc message



    eulerBundle.add(eulerMessage);
    eulerMessage.clear();
  }
  eulerBundle.setTimetag(eulerBundle.now());

  oscP5.send(eulerBundle, sendRemoteLocation);
}


void oscSend2(int[] piezo) {


  OscBundle piezoBundle = new OscBundle();


  for (int i = 0; i< piezo.length; i++) {

    OscMessage piezoMessage = new OscMessage("/piezo" + i);


    // fPiezo[i] = map((piezo[i]),0, 120, 0, 1);  

    piezoMessage.add(piezo[i]);   //add piezo[] to osc message
    piezoBundle.add(piezoMessage);
    piezoMessage.clear();
  }

  oscP5.send(piezoBundle, sendRemoteLocation);
}

void oscSend3() {
  OscMessage myMessage = new OscMessage("/freefall");
  myMessage.add(1);
  oscP5.send(myMessage, sendRemoteLocation);
  //just for testing
  //  println("freefall sent");
}

class Delta1 {
  int lastValue;
  int val;

  Delta1 () {  
    lastValue = 0;
    val = 0;
  } 


  public int diff(float f) {


    val = int(f) - lastValue;
    lastValue = int(f);
    delay(20);  
    return val;
  }
}


