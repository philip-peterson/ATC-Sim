//vim: sw=3:tabstop=3:sts=3:expandtab

import java.awt.geom.Line2D;
import java.awt.geom.Rectangle2D;
import ddf.minim.* ;

Minim minim;
AudioPlayer musicPlayer;
PImage planeIcon;

final float MUSIC_LENGTH = 201.5;
final float FULL_FUEL = 2;
final float WALL_THICKNESS = 40;

MainScreen screen_m;
InstructionScreen screen_i;
Game g;

color BT_MO_COLOR = #0036A0;  /* button mouseover color */
float PIXELS_PER_METER = 40;

PVector GLOBAL_G = new PVector(0.0, 9.8*PIXELS_PER_METER);


final int SCREEN_MAIN = 0;
final int SCREEN_INST = 1;
final int SCREEN_PLAY = 2;
int currentScreen = SCREEN_MAIN;

int difficulty = 0; /*  Difficulty selection. Copied into the Game object when it is constructed. */

void setup() {
  size(900,900);
  background(0);
  frameRate(50);
  
  resetDrawState();
  fill(0xFF);
  textSize(70);
  textAlign(CENTER, CENTER);
  text("Loading...", width/2, height/2);
  
  
  minim = new Minim(this) ;
  musicPlayer = minim.loadFile("chopin.mp3");
  

  planeIcon = loadImage("airplane_mode_on.png");
  
  screen_m = new MainScreen();
  screen_i = new InstructionScreen();
}


float t = 0;

void draw() {
  resetDrawState();
  background(0);
  
  
  
  float delta_t = 1/frameRate;
  t += delta_t;
  
  if (currentScreen == SCREEN_MAIN) {
    screen_m.draw(t, delta_t);
  }
  else if (currentScreen == SCREEN_INST) {
    screen_i.draw(t, delta_t);
  }
  else if (currentScreen == SCREEN_PLAY) {
    g.draw(t, delta_t);
  }
  
  randomPosition(REGION_W);
} 

void mouseMoved() {
  if (currentScreen == SCREEN_MAIN) {
    screen_m.mouse(mouseX, mouseY);
  }
  else if (currentScreen == SCREEN_INST) {
    screen_i.mouse(mouseX, mouseY);
  }
  else if (currentScreen == SCREEN_PLAY) {
    g.moved(mouseX, mouseY);
  }
}

void mouseDragged() {
  mouseMoved();
}

void keyPressed() {
  if (currentScreen == SCREEN_MAIN) {
    if (keyCode == 37) {
      difficulty = max(0, difficulty-1);
    }
    if (keyCode == 39) {
      difficulty = min(27, difficulty+1);
    }
  }
}

void mouseClicked() {
  if (currentScreen == SCREEN_MAIN) {
    int res = screen_m.click(mouseX, mouseY);
    if (res == 1) {
      currentScreen = SCREEN_INST; // Go to instructions
    }
    if (res == 2) {
      g = new Game(difficulty);
      musicPlayer.play(12500);
      currentScreen = SCREEN_PLAY; // Go to difficulty selection
    }
  }
  else if (currentScreen == SCREEN_INST) {
    int res = screen_i.click(mouseX, mouseY);
    if (res == 1) {
      currentScreen = SCREEN_MAIN; // Go to instructions
    }
  }
  
}

void mousePressed() {
  if (currentScreen == SCREEN_PLAY) {
    g.pressed(mouseX, mouseY);
  }
}

void mouseReleased() {
  if (currentScreen == SCREEN_PLAY) {
    g.released(mouseX, mouseY);
  }
}

void resetDrawState() {
  textSize(20);
  textAlign(LEFT, TOP);
  strokeWeight(1);
  stroke(0);
  fill(255);
  rectMode(CORNERS);
  imageMode(CENTER);
}

class Airplane {
  float theta;
  float targetTheta;
  PVector r;
  final float SPEED = 20.0;
  float fuel;
  float maxFuel;
  int dest;
  
  AudioPlayer fuelAlarm = minim.loadFile("School_Fire_Alarm-Cullen_Card-202875844.mp3");
  AudioPlayer proxAlarm = minim.loadFile("Industrial Alarm-SoundBible.com-1012301296.mp3");
  
  public Airplane(float x, float y, float theta, int dest, float safety) {
    maxFuel = max(width, height)*.5*sqrt(2)/SPEED;
    fuel = maxFuel*safety;
    maxFuel *= FULL_FUEL;
    
    this.dest = dest;
    this.theta = theta;
    targetTheta = theta;
    r = new PVector(x, y);
  }
  
  boolean overlap(float x, float y) {
    float a = x-r.x;
    float b = y-r.y;
    return sqrt(a*a+b*b) < 20;
  }
  
  color getFuelColor() {
    float pct = fuel/maxFuel;
    if (pct < .5) {
      return #FF0000;
    }
    else if (pct > .75) {
      return #00FF00;
    }
    return #FFFF00;
  }
  
  void draw(float t, float delta_t) {
    resetDrawState();
    pushMatrix();
      translate(round(r.x), round(r.y));
      pushMatrix();
        scale(.2);
        rotate(-theta);
        if (fuel/maxFuel < .3) {
          // Flash plane quickly if low on fuel
          tint(lerpColor(#FF0000, #00FFFF, sin(t*30)));
        }
        else {
          if (abs(targetTheta - theta) > .2) {
            // Plane flashes if turning
            tint(lerpColor(#FFFFFF, #C5BCC6, sin(t*10)));
          }
          else {
            tint(#FFFFFF);
          }
        }
        image(planeIcon, 0,0);
        tint(#FFFFFF);
      popMatrix();
      
      
      /* Draw fuel gauge */
      translate(0, 30);
      stroke(0x88);
      strokeWeight(1);
      fill(0);
      rectMode(CORNERS);
      rect(-20,-3,20,3);
      noStroke();
      fill(getFuelColor());
      rect(-20,-3,lerp(-20, 20, fuel/maxFuel),3);
      textAlign(LEFT, CENTER);
      textSize(9);
      text(floor(fuel)+"s", 30, 0);
      
      /* Draw destination */
      
      text("Dest: "+regionToString(dest), -20, 10);
      
    popMatrix();
    
    
    /* Draw drag widget if necessary */
    if (g.isPlaneSelected(this)) {
      strokeWeight(3);
      stroke(0xFF);
      line(g.m.x, g.m.y, r.x, r.y);
    }
    
    float TURN_SPEED = .1;
    
    if (targetTheta > theta) {
      theta = min(theta + delta_t*TURN_SPEED, targetTheta);
    }
    else {
      theta = max(theta - delta_t*TURN_SPEED, targetTheta);
    }
    
    
    r.add(new PVector(SPEED*cos(theta)*delta_t, -SPEED*sin(theta)*delta_t));
    
    fuel = max(fuel-delta_t, 0);
  }
  
}

String diffToString(int diff) {
  if (diff == 0) { 
    return "Easy";
  }
  if (diff == 1) {
    return "Medium";
  }
  if (diff == 2) {
    return "Hard";
  }
  return "Very Hard ("+(diff-2)+")";
}

class MainScreen {
  
  Rectangle2D.Float bt1;
  Rectangle2D.Float bt2;
  
  MainScreen() {
    float W = 150;
    float H = 50;
    bt1 = new Rectangle2D.Float(width*(.5-.2)-W/2, height*.9-H/2, W, H);
    bt2 = new Rectangle2D.Float(width*(.5+.2)-W/2, height*.9-H/2, W, H);
  }
  
  boolean mo1 = false;
  boolean mo2 = false;
  
  void mouse(float x, float y) {
    mo1 = mo2 = false;
    if (bt1.contains(x,y)) {
      mo1 = true;
    }
    if (bt2.contains(x,y)) {
      mo2 = true;
    }
  }
  
  int click(float x, float y) {
    if (bt1.contains(x,y)) {
      return 1;
    }
    if (bt2.contains(x,y)) {
      return 2;
    }
    return -1;
  }
  
  void draw(float t, float delta_t) {
    resetDrawState();
    color(0xFF);
    noStroke();
    
    textSize(70);
    textAlign(CENTER, CENTER);
    text("ATC-Sim", width/2, height*.2);
    
    textSize(13);
    text("By Philip Peterson", width/2, height*.3);
    textSize(15);
    
    textAlign(RIGHT, CENTER);
    textSize(25);
    text("Difficulty: ", width/2, height*.7);
    
    textAlign(LEFT, CENTER);
    text(diffToString(difficulty), width/2, height*.7);
    
    textAlign(CENTER, CENTER);
    textSize(13);
    text("(Use left/right arrow keys to change)", width/2, height*.73);
    
    textSize(15);
    if (t % 1 < .5) {
      fill(#FFFF00);
    }
    text("Turn up the sound!", width/2, height*.8);
    
    fill(0xFF);
    
    textSize(10);
    text(
    "The following are CC by SA (https://creativecommons.org/licenses/by/3.0/us/)\n"
    +"Airplane icon by VisualPharm. Colors were inverted.\n"
    +"Industrial Alarm Sound by Mike Koenig. No changes.\n"
    +"School Fire Alarm Sound by Cullen Card. No changes."
    
    , width/2, height*.5);
    
    
    stroke(0xFF);
    strokeWeight(2.0);
    
    fill(0x44);
    if (mo1) {
      fill(BT_MO_COLOR);
    }
    rect(bt1.x, bt1.y, bt1.x+bt1.width, bt1.y+bt1.height, 20);
    
    fill(0x44);
    if (mo2) {
      fill(BT_MO_COLOR);
    }
    rect(bt2.x, bt2.y, bt2.x+bt2.width, bt2.y+bt2.height, 20);
    
    fill(0xFF);
    textSize(20);
    text("Instructions", bt1.x+bt1.width/2, bt1.y+bt1.height/2-2);
    text("Play", bt2.x+bt2.width/2, bt2.y+bt2.height/2-2);
  }
}

class InstructionScreen {
  
  Rectangle2D.Float bt1;
  
  InstructionScreen() {
    float W = 150;
    float H = 50;
    bt1 = new Rectangle2D.Float(width*(.5-.2)-W/2, height*.9-H/2, W, H);
  }
  
  boolean mo1 = false;
  
  void mouse(float x, float y) {
    mo1 = false;
    if (bt1.contains(x,y)) {
      mo1 = true;
    }
  }
  
  int click(float x, float y) {
    if (bt1.contains(x,y)) {
      return 1;
    }
    return -1;
  }
  
  void draw(float t, float delta_t) {
    resetDrawState();
    color(0xFF);
    noStroke();
    
    textAlign(LEFT, TOP);
    text(
    
    "Click and drag an airplane to change its linear direction.\n\n\n\n"
    
    +"Right-click and drag an airplane to make it go in circles.\n\n\n\n"
    
    +"Each airplane has to make it to its destination before it runs out of fuel.\n\n\n\n"
    
    +"Be sure to take into account the amount of time it takes a plane to turn.\n\n\n\n"
    
    +"If an airplane goes off the radar in the wrong direction, it will reverse its\n  direction, but it will lose a lot of fuel.\n\n\n\n"
    
    +"All airplanes are at the same altitude. Don't let them crash!", 20.0, 20.0);
    
    /* Draw buttons */
    
    stroke(0xFF);
    strokeWeight(2.0);
    
    fill(0x44);
    if (mo1) {
      fill(BT_MO_COLOR);
    }
    rect(bt1.x, bt1.y, bt1.x+bt1.width, bt1.y+bt1.height, 20);
    
    /* Draw button text */
    
    textAlign(CENTER, CENTER);
    fill(0xFF);
    textSize(20);
    text("Back to Menu", bt1.x+bt1.width/2, bt1.y+bt1.height/2-2);
  }
}

class Game {
  int diff;
  Airplane planes[];
  float times[];
  
  int indexOfLastPlane = 0;
  
  Game(int diff) {
    this.diff = diff;
    int numPlanes = (diff+2)*20;
    planes = new Airplane[numPlanes];
    times = new float[numPlanes];
    
    float avgTime = MUSIC_LENGTH/numPlanes;
    times[0] = 0;
    for (int i = 0; i < numPlanes; i++) {
      PVector start = randomPosition((i % 8));
      
      int endRegion = getRandomEndRegion(i%8);;
      PVector end = randomPosition(endRegion);
      
      PVector difference = PVector.sub(end, start);
      difference.y = -difference.y;
      float theta = thetaFromVector(difference);
      
      planes[i] = new Airplane(start.x, start.y, theta, endRegion, 1.8);
      if (i > 0) {
        times[i] = times[i-1]+random(1, avgTime+1);
      }
    }
  }
  
  void draw(float t, float delta_t) {
    resetDrawState();
    
 
    // Draw corner zones
    
    fill(color(0x33, 0x33, 0x33, 0x88));
    stroke(0xFF);
    strokeWeight(1.0);
    beginShape();
    
    
    /* NW */
    vertex(0,0);
    vertex(width/4, 0);
    vertex(width/4, WALL_THICKNESS);
    vertex(WALL_THICKNESS, height/4);
    vertex(0, height/4);
    endShape(CLOSE);
    
    /* SW */
    beginShape();
    vertex(0, height);
    vertex(width/4, height);
    vertex(width/4, height-WALL_THICKNESS);
    vertex(WALL_THICKNESS, height-height/4);
    vertex(0, height-height/4);
    endShape(CLOSE);
    
    /* SE */
    beginShape();
    vertex(width, height);
    vertex(width, height-height/4);
    vertex(width-WALL_THICKNESS, height-height/4);
    vertex(width-width/4, height-WALL_THICKNESS);
    vertex(width-width/4, height);
    endShape(CLOSE);
    
    /* NE */
    beginShape();
    vertex(width, 0);
    vertex(width-width/4, 0);
    vertex(width-width/4, WALL_THICKNESS);
    vertex(width-WALL_THICKNESS, height/4);
    vertex(width, height/4);
    endShape(CLOSE);
    
    /* Draw sides */
    rectMode(CORNERS);
    
    rect(0, height/4, WALL_THICKNESS, height-height/4); // W
    
    rect(width-WALL_THICKNESS, height/4, width, height-height/4); // E
    
    rect(width/4, height-WALL_THICKNESS, width-width/4, height); // S

    rect(width/4, 0, width-width/4, WALL_THICKNESS); // N

    /* Draw labels */
    textSize(13);
    fill(0xFF);
    textAlign(CENTER, CENTER);
    text("N", width/2, WALL_THICKNESS/2);
    text("S", width/2, height-WALL_THICKNESS/2);
    text("W", WALL_THICKNESS/2, height/2);
    text("E", width-WALL_THICKNESS/2, height/2);
    
    text("NW", width*.1, height*.1);
    text("NE", width-width*.1, height*.1);
    text("SW", width*.1, height-height*.1);
    text("SE", width-width*.1, height-height*.1);
    
        // Draw planes
    
    for (int i = 0; i < planes.length; i++ ) {
      if (i > indexOfLastPlane) {
        if (times[i] <= t) {
          indexOfLastPlane = i;
        }
      }
      if (i <= indexOfLastPlane) {
        planes[i].draw(t, delta_t);
      }
    }

  }
  
  /*
  Mouse Modes:
  0 = normal, unclicked
  1 = left clicked
  */
  int mouseMode = 0;
  PVector m = new PVector(0,0);
  int selectedPlane = -1;
  
  void released(float x, float y) {
    if (selectedPlane != -1) {
      Airplane p = planes[selectedPlane];
      float a, b;
      a = x - p.r.x;
      b = -(y - p.r.y);
      float theta = thetaFromVector(new PVector(a,b));
      
      
      //theta = theta % (2*PI);
      p.targetTheta = theta;
      
    }
    mouseMode = 0;
    selectedPlane = -1;
  }
  
  void pressed(float x, float y) {
    for (int i = 0; i < planes.length; i++ ){
      if (planes[i].overlap(x,y)) {
        mouseMode = 1;
        selectedPlane = i;
        return;
      }
    }
    selectedPlane = -1;
    mouseMode = 0;
  }
  
  void moved(float x, float y) {
    m.x = x;
    m.y = y;
  }
  
  boolean isPlaneSelected(Airplane p) {
    if (selectedPlane == -1) 
      return false;
    return planes[selectedPlane] == p;    
  }
}

final int REGION_NW = 0;
final int REGION_N = 1;
final int REGION_NE = 2;
final int REGION_E = 3;
final int REGION_SE = 4;
final int REGION_S = 5;
final int REGION_SW = 6;
final int REGION_W = 7;

float[] getRegionBounds(int region) {
  float ax, ay, bx, by;
  float minx = 0, miny = 0, maxx = 0, maxy = 0;
  
  ax = WALL_THICKNESS/2;
  ay = WALL_THICKNESS/2;
  bx = width/8;
  by = height/8;
  
  if (region == REGION_NW) {
    minx = ax;
    miny = ay;
    maxx = bx;
    maxy = by;
  }
  else if (region == REGION_SW) {
    minx = ax;
    maxy = height-ay;
    maxx = bx;
    miny = height-by;
  }
  else if (region == REGION_SE) {
    maxx = width-ax;
    maxy = height-ay;
    minx = width-bx;
    miny = height-by;
  }
  else if (region == REGION_NE) {
    maxx = width-ax;
    miny = ay;
    minx = width-bx;
    maxy = by;
  }
  
  else if (region == REGION_N) {
    minx = width/4;
    maxx = width-width/4;
    miny = WALL_THICKNESS/4;
    maxy = WALL_THICKNESS*3.0/4;
  }
  else if (region == REGION_S) {
    minx = width/4;
    maxx = width-width/4;
    maxy = height-WALL_THICKNESS/4;
    miny = height-WALL_THICKNESS*3.0/4;
  }
  else if (region == REGION_E) {
    miny = height/4;
    maxy = height-height/4;
    maxx = width-WALL_THICKNESS/4;
    minx = width-WALL_THICKNESS*3.0/4;
  }
  else if (region == REGION_W) {
    miny = height/4;
    maxy = height-height/4;
    minx = WALL_THICKNESS/4;
    maxx = WALL_THICKNESS*3.0/4;
  }
  
  float bounds[] = new float[4];
  bounds[0] = minx;
  bounds[1] = miny;
  bounds[2] = maxx;
  bounds[3] = maxy;
  return bounds;
}

PVector randomPosition(int region) {
  float bounds[] = getRegionBounds(region);
  float minx = bounds[0];
  float miny = bounds[1];
  float maxx = bounds[2];
  float maxy = bounds[3];
  return new PVector(random(minx, maxx), random(miny, maxy));
}

float thetaFromVector(PVector v) {
  float theta = 0;
  float a = v.x;
  float b = v.y;
  
  if ( abs(a) < .01 ) {
    theta = (b > 0) ? PI/2 : -PI/2;
  }
  else {
    theta = atan(b/a);
    if (a < 0) {
      theta += PI;
    }
  }
  return theta;
}

String regionToString(int region) {
  switch(region) {
    case REGION_N:
      return "N";
    case REGION_S:
      return "S";
    case REGION_E:
      return "E";
    case REGION_W:
      return "W";
    case REGION_NE:
      return "NE";
    case REGION_SE:
      return "SE";
    case REGION_SW:
      return "SW";
    case REGION_NW:
      return "NW";
  }
  return "?";
}

int getRandomEndRegion(int start_region) {
  int possibles[] = new int[4];
  possibles[0] = start_region+3;
  possibles[1] = start_region+4;
  possibles[2] = start_region-3;
  possibles[3] = start_region-4;
  for (int i = 0; i < possibles.length; i++) {
    possibles[i] = (possibles[i]+8) % 8;
  }
  return possibles[(int)(round(random(0,3)))];
}
