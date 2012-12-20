// public class DrawCube{} // CLASS THIS UP PROPERLY !!!

final int FACES = 12;     // number of faces 
final int VERTICES = 5;   // VERTICES per face
final float A = 1.618033989; // (1 * sqr(5) / 2) - wikipedia
final float B = 0.618033989; // 1 / (1 * sqr(5) / 2) - wikipedia

PVector[] vert = new PVector[20]; // list of vertices
int[][] faces =  new int[FACES][VERTICES];  // list of faces (joining vertices)

// ==================================================

void dodecahedron() {

  vert[ 0] = new PVector(1, 1, 1);
  vert[ 1] = new PVector(1, 1, -1);
  vert[ 2] = new PVector(1, -1, 1);
  vert[ 3] = new PVector(1, -1, -1);
  vert[ 4] = new PVector(-1, 1, 1);
  vert[ 5] = new PVector(-1, 1, -1);
  vert[ 6] = new PVector(-1, -1, 1);
  vert[ 7] = new PVector(-1, -1, -1);

  vert[ 8] = new PVector(0, B, A);
  vert[ 9] = new PVector(0, B, -A);
  vert[10] = new PVector(0, -B, A);
  vert[11] = new PVector(0, -B, -A);

  vert[12] = new PVector(B, A, 0);
  vert[13] = new PVector(B, -A, 0);
  vert[14] = new PVector(-B, A, 0);
  vert[15] = new PVector(-B, -A, 0);

  vert[16] = new PVector(A, 0, B);
  vert[17] = new PVector(A, 0, -B);
  vert[18] = new PVector(-A, 0, B);
  vert[19] = new PVector(-A, 0, -B); 

  faces[ 0] = new int[] {  
    0, 16, 2, 10, 8
  };
  faces[ 1] = new int[] {  
    0, 8, 4, 14, 12
  };
  faces[ 2] = new int[] {  
    16, 17, 1, 12, 0
  };
  faces[ 3] = new int[] {  
    1, 9, 11, 3, 17
  };
  faces[ 4] = new int[] {  
    1, 12, 14, 5, 9
  };
  faces[ 5] = new int[] {  
    2, 13, 15, 6, 10
  };
  faces[ 6] = new int[] {  
    13, 3, 17, 16, 2
  };
  faces[ 7] = new int[] {  
    3, 11, 7, 15, 13
  };
  faces[ 8] = new int[] {  
    4, 8, 10, 6, 18
  };
  faces[ 9] = new int[] {  
    14, 5, 19, 18, 4
  };
  faces[10] = new int[] {  
    5, 19, 7, 11, 9
  };
  faces[11] = new int[] {  
    15, 7, 19, 18, 6
  };

  for (int i = 0; i < FACES; i = i+1) {

    fill(map(i, 0, FACES, 0, 255));
    

    beginShape();
    for (int i2 = 0; i2 < VERTICES; i2 = i2+1) {
      vertex(vert[faces[i][i2]].x, vert[faces[i][i2]].y, vert[faces[i][i2]].z);
    } // for
    endShape(CLOSE);
  }
  endShape();
}

void drawCube() {  
  //  background(255);

  pushMatrix();
  translate(VIEW_SIZE_X/2, VIEW_SIZE_Y/2 - 50, 0);
  scale(75, 75, 75);

  // a demonstration of the following is at 
  // http://www.varesano.net/blog/fabio/ahrs-sensor-fusion-orientation-filter-3d-graphical-rotating-cube
  //done in a weird way to get values to display on processing x,y axis properly
  rotateZ(-euler[2]);
  rotateX(-euler[1]);
  rotateY(-euler[0]);

  dodecahedron();

  popMatrix();
}

void remapDirection() {
  if (hq != null) { // use home quaternion
    quaternionToEuler(quatProd(hq, q), euler);
    //   text("Disable home position by pressing \"n\"", 20, VIEW_SIZE_Y - 30);
  }
  else {
    quaternionToEuler(q, euler);
    //  text("Point X axis to your monitor then press \"h\"", 20, VIEW_SIZE_Y - 30);
  }
}

void keyPressed() {
  if (key == 'h') {
    println("pressed h");

    // set hq the home quaternion as the quatnion conjugate coming from the sensor fusion
    hq = quatConjugate(q);
  }
  else if (key == 'n') {
    println("pressed n");
    hq = null;
  }
}

void drawcompass(float heading, int circlex, int circley, int circlediameter) {
    fill(180);

  noStroke();
  ellipse(circlex, circley, circlediameter, circlediameter);

 // fill(#ff0000);
  ellipse(circlex, circley, circlediameter/20, circlediameter/20);
  stroke(#ff0000);
  strokeWeight(4);
  line(circlex, circley, circlex - circlediameter/2 * sin(-heading), circley - circlediameter/2 * cos(-heading));
  noStroke();
  fill(160, 120);
  textAlign(CENTER, BOTTOM);
  text("N", circlex, circley - circlediameter/2 - 10);
  textAlign(CENTER, TOP);
  text("S", circlex, circley + circlediameter/2 + 10);
  textAlign(RIGHT, CENTER);
  text("W", circlex - circlediameter/2 - 10, circley);
  textAlign(LEFT, CENTER);
  text("E", circlex + circlediameter/2 + 10, circley);

}


void drawAngle(float angle, int circlex, int circley, int circlediameter, String title) {
  angle = angle + PI/2;
  
  noStroke();
  ellipse(circlex, circley, circlediameter, circlediameter);
  fill(#ff0000);
  strokeWeight(4);
  stroke(#ff0000);
  line(circlex - circlediameter/2 * sin(angle), circley - circlediameter/2 * cos(angle), circlex + circlediameter/2 * sin(angle), circley + circlediameter/2 * cos(angle));
  noStroke();
  fill(160, 120);
  textAlign(CENTER, BOTTOM);
  text(title, circlex, circley - circlediameter/2 - 30);
}

