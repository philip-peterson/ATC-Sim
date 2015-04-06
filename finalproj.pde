//vim: sw=3:tabstop=3:sts=3:expandtab

import java.awt.geom.Line2D;
import java.awt.geom.Rectangle2D;
import ddf.minim.* ;

Minim minim;
AudioPlayer musicPlayer;
PImage planeIcon;

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
} 

void mouseMoved() {
  if (currentScreen == SCREEN_MAIN) {
    screen_m.mouse(mouseX, mouseY);
  }
  else if (currentScreen == SCREEN_INST) {
    screen_i.mouse(mouseX, mouseY);
  }
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

void resetDrawState() {
  textSize(20);
  textAlign(LEFT, TOP);
  strokeWeight(1);
  stroke(0);
  fill(255);
  rectMode(CORNERS);
}

class Airplane {
  PVector v;
  PVector r;
  
  AudioPlayer fuelAlarm = minim.loadFile("School_Fire_Alarm-Cullen_Card-202875844.mp3");
  AudioPlayer proxAlarm = minim.loadFile("Industrial Alarm-SoundBible.com-1012301296.mp3");
  
  public Airplane() {
    v = new PVector(0, 0);
    r = new PVector(width/4, height/4);
  }
  
  void draw(float t, float delta_t) {
    resetDrawState();
    rect(r.x-20, r.y-50, r.x+20, r.y-1);
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
  Game(int diff) {
    this.diff = diff;
  }
  void draw(float t, float delta_t) {
    for (int i = 0; i < planes.length; i++ ) {
      planes[i].draw();
    }
  }
}
