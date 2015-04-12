//vim: sw=3:tabstop=3:sts=3:expandtab

/* Please do not look at this code. It's horrific! */

/* Quick shim for processing.JS */
class Rectangle2D {
   float x; float y; float width; float height;
   Rectangle2D(float x, float y, float w, float h) {
      this.x = x;
      this.y = y;
      this.width = w;
      this.height = h;
   }
   boolean contains(float x2, float y2) {
      if (x2 < x || x2 > x+width) {
         return false;
      }
      if (y2 < y || y2 > y+height) {
         return false;
      }
      return true;
   }
}

PImage planeIcon;

final float MUSIC_LENGTH = 201.5;
final float FULL_FUEL = 2.5;
final float WALL_THICKNESS = 40;
final float DISTANCE_ALARM_DIST = 80;
final float CRASH_DIST = 25;
final float FUEL_ALARM_SECS = 15;

boolean proximityAlarmActive = false;
boolean fuelAlarmActive = false;

MainScreen screen_m;
InstructionScreen screen_i;
Game g;

color BT_MO_COLOR = #0036A0;  /* button mouseover color */
float PIXELS_PER_METER = 40;

PVector GLOBAL_G = new PVector(0.0, 9.8*PIXELS_PER_METER);


final int SCREEN_MAIN = 0;
final int SCREEN_INST = 1;
final int SCREEN_PLAY = 2;

int difficulty = 1; /*  Difficulty selection. Copied into the Game object when it is constructed. */

void setup() {
  size(900,900);
  background(0);
  frameRate(50);
  
  resetDrawState();
  fill(0xFF);

  textSize(10);

  pushMatrix();
  scale(7);
  textAlign(CENTER, CENTER);
  text("Loading...", (width/2)/7, (height/2)/7);
  popMatrix();
  
  
  
  
  
  
  planeIcon = loadImage("data/airplane_mode_on.png");
  
  screen_m = new MainScreen();
  screen_i = new InstructionScreen();
}


float t = 0;
float gameStartTime = 0;

void draw() {
  if(wantsExit && currentScreen != SCREEN_MAIN) {
    currentScreen = SCREEN_MAIN;
    screenDidChange();
    g = null;
    stopSound(0);
    stopSound(3);
    stopSound(2);
    stopSound(4);
    fuelAlarmActive = false;
    proximityAlarmActive = false;
    wantsExit = false;
  }

  resetDrawState();
  background(0);
  
  
  float old_t = t;
  float delta_t = 1/frameRate;
  t += delta_t;
  
  if (currentScreen == SCREEN_MAIN) {
    screen_m.tick(t, delta_t);
  }
  else if (currentScreen == SCREEN_INST) {
    screen_i.tick(t, delta_t);
  }
  else if (currentScreen == SCREEN_PLAY) {
    g.tick(t-gameStartTime, delta_t);
    if (g.over) {
      t = old_t;
    }
  }
  
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
      difficulty = min(8, difficulty+1);
    }
  }
}

void mouseClicked() {
  if (currentScreen == SCREEN_MAIN) {
    int res = screen_m.click(mouseX, mouseY);
    if (res == 1) {
      currentScreen = SCREEN_INST; // Go to instructions
      screenDidChange();
    }
    if (res == 2) {
      gameStartTime = t;
      g = new Game(difficulty);
      playSound(0, 12.500);
      currentScreen = SCREEN_PLAY; // Go to difficulty selection
      screenDidChange();
    }
  }
  else if (currentScreen == SCREEN_INST) {
    int res = screen_i.click(mouseX, mouseY);
    if (res == 1) {
      currentScreen = SCREEN_MAIN; // Go to instructions
      screenDidChange();
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
  textAlign(LEFT, TOP);
  strokeWeight(1);
  stroke(0);
  fill(255);
  rectMode(CORNERS);
  imageMode(CENTER);
}

/*
Airplane class. Represents a single airplane across its life.
*/
class Airplane {
  float theta;
  float targetTheta;
  PVector r;
  final float SPEED = 20.0;
  float fuel;
  float maxFuel;
  int dest;
  int source;
  boolean haveNotReachedDestination = true;
  
  /*
     Constructor for Airplane.
     x = initial x-position
     y = initial y-position
     theta = initial angle (CCW from right)
     source = region number for the source (origin) of the plane
     dest = region number for the destination of the plane
     safety = the factor of safety (should be above 1.0) for the plane's fuel.
  */
  public Airplane(float x, float y, float theta, int source, int dest, float safety) {
    maxFuel = max(width, height)*.5*sqrt(2)/SPEED;
    fuel = maxFuel*safety;
    maxFuel *= FULL_FUEL;
    
    this.source = source;
    this.dest = dest;
    this.theta = theta;
    targetTheta = theta;
    r = new PVector(x, y);
  }
  
  /*
     Return true if (x,y) is a valid click point for the plane.
   */
  boolean overlap(float x, float y) {
    float a = x-r.x;
    float b = y-r.y;
    return sqrt(a*a+b*b) < 20;
  }
  
  /*
     Return a color for the fuel bar.
   */
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
  
  /*
   Draws the plane and updates its state.
   - Draws with flashing if low on fuel or turning.
   - Draws fuel gauge
   - Draw destination
   - Draw drag widget for this plane if necessary
   - Update theta to point toward targetTheta
   - Warp plane to starting region if necessary
   - Check if fuel is out, trigger endgame if so.
  */
  void tick(float t, float delta_t) {
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

      pushMatrix();
      scale(.9);
      text(floor(fuel)+"s", 300/9, 0);
      popMatrix();
      
      /* Draw destination */
      
      textx("Dest: "+regionToString(dest), .9, -20, 10);
      
    popMatrix();
    
    
    if (g.over) {
      return;
    }
    
    /* Draw drag widget if necessary */
    if (g.isPlaneSelected(this)) {
      strokeWeight(3);
      stroke(0xFF);
      line(g.m.x, g.m.y, r.x, r.y);
    }
    
    float TURN_SPEED = .4;
    
    float deltaTheta = Angle.sub(targetTheta, theta);
    
    
    if (deltaTheta > 0) {
      theta = theta + delta_t*TURN_SPEED;
    }
    else {
      theta = theta - delta_t*TURN_SPEED;
    }
    
    theta = theta + 2*PI;
    theta = theta % (2*PI);
    
    if (abs(Angle.sub(targetTheta, theta)) < delta_t*TURN_SPEED) {
      theta = targetTheta;
    }
    
    
    r.add(new PVector(SPEED*cos(theta)*delta_t, -SPEED*sin(theta)*delta_t));
    
    int region = getRegionFromPoint(r);
    boolean warpToStart = false;
    if (region != -1) {
      
      if (region == dest) {
        // This plane is no longer "alive" (has succeeded in its journey)
        this.haveNotReachedDestination = false;
        playSound(1);
        return;
      }
      else if (region == source) {
        // If region is the source, ignore unless the plane is off the screen
        if (r.x < 0 || r.x > width || r.y < 0 || r.y > height) {
          warpToStart = true;
        }
      }
      else {
        // If the plane is in a strange region, re-spawn from source,
        // directing toward destination
        warpToStart = true;
      }
    }
    
    if (warpToStart) {
        r = randomPosition(source);
        PVector difference = PVector.sub(randomPosition(dest), r);
        difference.y = -difference.y;
        theta = thetaFromVector(difference);
        targetTheta = theta;
    }
    
    fuel = max(fuel-delta_t, 0);
    
    if (fuel <= 0) {
      g.over = true;
      g.planeThatRanOut = this;
      stopSound(3);
      stopSound(0);
    }
  }
  
}

/* 
Produces human-readable name for difficulty level.
*/
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

  if (diff == 6) {
    return "Are you crazy?";
  }

  if (diff == 7) {
    return "Insane!";
  }

  if (diff == 8) {
    return "There's no way you're beating this.";
  }

  String r = "Hard";
  for (int i = 0; i < (diff-2); i++) {
    r = "Very " + r;
  }
  return r;
}

class MainScreen {
  
  Rectangle2D bt1;
  Rectangle2D bt2;
  
  /*
  Constructor for MainScreen.
  */
  MainScreen() {
    float W = 150;
    float H = 50;
    bt1 = new Rectangle2D(width*(.5-.2)-W/2, height*.9-H/2, W, H);
    bt2 = new Rectangle2D(width*(.5+.2)-W/2, height*.9-H/2, W, H);
  }
  
  boolean mo1 = false;
  boolean mo2 = false;
  
  /*
  Handles mouseover for instructions/play buttons
  */
  void mouse(float x, float y) {
    mo1 = mo2 = false;
    if (bt1.contains(x,y)) {
      mo1 = true;
    }
    if (bt2.contains(x,y)) {
      mo2 = true;
    }
  }
  
  /*
  Handles click detection for the instructions and play
  buttons
  */
  int click(float x, float y) {
    if (bt1.contains(x,y)) {
      return 1;
    }
    if (bt2.contains(x,y)) {
      return 2;
    }
    return -1;
  }
  
  /*
  Displays:
   - blinking "turn up the sound"
   - selected difficulty
   - credits
   - title
   - instructions/play buttons 
  */
  void tick(float t, float delta_t) {
    resetDrawState();
    color(0xFF);
    noStroke();

    textAlign(CENTER, CENTER);
    
    pushMatrix();
    translate(width/2, height*.2);
    scale(7);
    text("ATC-Sim", 0, 0);
    popMatrix();
    
    pushMatrix();
    translate(width/2, height*.3);
    scale(1.3);
    text("By Philip Peterson", 0, 0);
    popMatrix();

    textAlign(RIGHT, CENTER);
    pushMatrix();
    translate(width/2, height*.7);
    scale(2.5);
    text("Difficulty: ", 0, 0);
    
    textAlign(LEFT, CENTER);
    text(diffToString(difficulty), 0, 0);
    popMatrix();
    
    pushMatrix();
    textAlign(CENTER, CENTER);
    translate(width/2, height*.73);
    scale(1.3);
    text("(Use left/right arrow keys to change)", 0, 0);
    popMatrix();
    
    pushMatrix();
    translate(width/2, height*.8);
    scale(1.5);
    if (t % 1 < .5) {
      fill(#FFFF00);
    }
    text("Turn up the sound!", 0, 0);
    popMatrix();
    
    fill(0xFF);
    
    pushMatrix();
    translate(width/2, height/2);
    scale(1.0);
    text(
    "The following are CC-by-SA (https://creativecommons.org/licenses/by/3.0/us/)\n"
    +"Airplane icon by VisualPharm. Colors were inverted. Converted to Ogg format.\n"
    +"Industrial Alarm sound by Mike Koenig. Converted to Ogg format.\n"
    +"School Fire Alarm sound by Cullen Card. Converted to Ogg format.\n"
    +"Explosion Ultra Bass sound by Mark DiAngelo. Converted to Ogg format.\n"
    +"\n"
    +"The following is CC-0:\n"
    +"Good! sound by syseQ. Converted to Ogg format.\n"
    +"\n"
    
    , 0,0);

    translate(0, 100);
   
    scale(1.5);
    text("Performance of Chopin's \"Winter Wind\" by Antonio Pompa-Baldi\nUsed with permission.\n(Soundcloud: AntonioPompaBaldi1)", 0, 0);
    popMatrix();
    
    
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

    pushMatrix();
    translate(bt1.x+bt1.width/2, bt1.y+bt1.height/2-2);
    scale(2.0);
    text("Instructions", 0, 0);
    popMatrix();

    pushMatrix();
    translate(bt2.x+bt2.width/2, bt2.y+bt2.height/2-2);
    scale(2.0);
    text("Play", 0, 0);
    popMatrix();
  }
}

class InstructionScreen {
  
  Rectangle2D.Float bt1;
  
  /* Constructor for InstructionScreen */
  InstructionScreen() {
    float W = 150;
    float H = 50;
    bt1 = new Rectangle2D(width*(.5-.2)-W/2, height*.9-H/2, W, H);
  }
  
  boolean mo1 = false;
  
  /* Checks if the mouse is over the button */
  void mouse(float x, float y) {
    mo1 = false;
    if (bt1.contains(x,y)) {
      mo1 = true;
    }
  }
  
  /* Checks if the mouse has clicked the button */
  int click(float x, float y) {
    if (bt1.contains(x,y)) {
      return 1;
    }
    return -1;
  }
  
  /* Draws instructions and button to screen. */
  void tick(float t, float delta_t) {
    resetDrawState();
    color(0xFF);
    noStroke();
    
    textAlign(LEFT, TOP);
    textx(
    
    "Each airplane has to make it to its destination before it runs out of fuel.\nThe goal is to get all the airplanes to their destination, or to have the time run out\n"
    +"without crashing.\n\n\n"
    
    +"Click and drag an airplane to change its heading.\nNote that this takes time because of inertia.\nWhen an airplane is turning, it will pulsate in brightness to indicate this.\n\n\n"
    
    +"If an airplane goes off the radar in the wrong direction, it will get warped back\nto the start, costing you fuel.\n\n\n\n"
    
    +"You can stop the game by pressing (Esc).\n\n\n\n"
    
    +"All airplanes are at the same altitude. Don't let them crash!", 2.4, 20.0, 20.0);
    
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
    pushMatrix();
    translate(bt1.x+bt1.width/2, bt1.y+bt1.height/2-2);
    scale(2.0);
    text("Back to Menu", 0, 0);
    popMatrix();
  }
}

/*
   Represents a game session.
*/
class Game {
  int diff;
  int crash1 = -1;
  int crash2 = -1;
  Airplane planeThatRanOut = null;
  
  Airplane planes[];
  float times[];
  boolean over = false;
  
  int indexOfLastPlane = 0;
  
  /*
   Construct a new Game with difficulty in range [0, infinity)
   Initializes the list of planes, with staggered start times.
  */
  Game(int difficulty) {
    this.diff = diff;
    int numPlanes = (diff+1)*20;
    
    planes = new Airplane[numPlanes];
    times = new float[numPlanes];
    
    float avgTime = MUSIC_LENGTH/numPlanes;
    times[0] = 0;
    
    for (int i = 0; i < numPlanes; i++) {
      PVector start = randomPosition((i % 8));
      
      int endRegion = getRandomEndRegion(i%8);;
      PVector end = randomPosition(jitterRegion(endRegion));
      
      PVector difference = PVector.sub(end, start);
      difference.y = -difference.y;
      float theta = thetaFromVector(difference);
      
      // From levels 0 to 5, gradually decrease safety margin.
      float safety = lerp(2.5, 1.8, min(difficulty/5.0, 1.0));
      planes[i] = new Airplane(start.x, start.y, theta, i%8, endRegion, safety);
      if (i > 0) {
        float timeSafety = lerp(1,.5,max(difficulty/6.0, 0));
        float timeDiff = avgTime+timeSafety;
        if (difficulty > 8) {
          timeDiff = timeSafety+2;
        }
        times[i] = times[i-1]+random(timeSafety, timeDiff);
      }
    }
  }
  
  int ctr;
  static final int TICKS_BETWEEN_ALARM_CHECKS = 10;
  
  /*
   Draws essentially everything related to the HUD.
   Also updates most of the logic.
      - Checks if the game has ended, displays message if so.
      - Displays time remaining
      - Updates alarms every few ticks.
      - Draws border pieces.
      - Tells planes that are still alive/relevant to tick.
  */
  void tick(float t, float delta_t) {
    resetDrawState();
    
    if (MUSIC_LENGTH - t <= 0) {
      over = true; // Won!
    }
    
    fill(0x33);
    textAlign(CENTER, CENTER);

    pushMatrix();
    translate( width/2, height/2);
    scale(4.0);
    text("Time remaining: " + secsToTime(round(MUSIC_LENGTH - t)), 0, 0);
    translate(0, 20);
    fill(#FF0000);
    if (proximityAlarmActive && (t % .5) < .25) {
       text("PROXIMITY ALARM", 0, 0);
    }
    translate(0, -40);
    fill(#FF8800);
    if (fuelAlarmActive && ((t+.25) % 1) < .5) {
       text("FUEL ALARM", 0, 0);
    }
    popMatrix();
    
    if (!over) {
      ctr++;
      if (ctr == TICKS_BETWEEN_ALARM_CHECKS) {
        ctr = 0;
        checkAlarms();
      }
    }
 
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
    
    rect(width/4, height-WALL_THICKNESS, width-width/4, height-1); // S

    rect(width/4, 0, width-width/4, WALL_THICKNESS); // N

    /* Draw labels */
    fill(0xFF);
    textAlign(CENTER, CENTER);

    textx("N",  1.3, width/2, WALL_THICKNESS/2);
    textx("S",  1.3, width/2, height-WALL_THICKNESS/2);
    textx("W",  1.3, WALL_THICKNESS/2, height/2);
    textx("E",  1.3, width-WALL_THICKNESS/2, height/2);
    
    textx("NW", 1.3, width*.1, height*.1);
    textx("NE", 1.3, width-width*.1, height*.1);
    textx("SW", 1.3, width*.1, height-height*.1);
    textx("SE", 1.3, width-width*.1, height-height*.1);
    
        // Draw planes
    
    for (int i = 0; i < planes.length; i++ ) {
      
      if (!over) {
        // Update indexOfLastPlane if necessary
        if (i > indexOfLastPlane) {
          if (times[i] <= t) {
            indexOfLastPlane = i;
          }
        }
      }
      
      if (times[i] <= t && planes[i].haveNotReachedDestination) {
        planes[i].tick(t, delta_t);
      }
    }
    
    if (over) {
      textAlign(CENTER);
      color(0xFF);
      textx("GAME OVER", 2.0, width*.5, height*.4);
      
      ellipseMode(CENTER);
      strokeWeight(5);
      stroke(#FFFF00);
      noFill();
      
      // Display failure explanation
      if (planeThatRanOut != null) {
        textx("RAN OUT OF FUEL", 2.0, width*.5, height*.5);
        ellipse(planeThatRanOut.r.x, planeThatRanOut.r.y, 100, 100);
      }
      
      else if (crash1 != -1 && crash2 != -1) {
        textx("MID-AIR COLLISION", 2.0, width*.5, height*.5);
        ellipse(planes[crash1].r.x, planes[crash1].r.y, 80, 80);
      }
      
      else {
        textx("YOU WON!", 2.0, width*.5, height*.5);
      }
      
      textx("Press (Esc) to return to menu.", 2.0, width*.5, height*.6);
      
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
  
  /*
    When mouse is released: tell plane to move to face the direction indicated by player.
  */
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
  
  /*
   
  */
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
  
  void checkAlarms() {
    boolean isDistanceAlarm = false;
    boolean isCrashAlarm = false;
    boolean isFuelAlarm = false;
    int crash1 = -1;
    int crash2 = -1;
    boolean atLeastOneAlive = false;
    for (int i = 0; i <= indexOfLastPlane; i++) {
      if (planes[i].haveNotReachedDestination) {
        atLeastOneAlive = true;
         if (planes[i].fuel < FUEL_ALARM_SECS) {
           isFuelAlarm = true;
         }
      }
      for (int j = 0; j <= indexOfLastPlane; j++) {
        if (i == j) {
          continue;
        }
        if (!planes[i].haveNotReachedDestination || !planes[j].haveNotReachedDestination) {
          continue;
        }
        
        float a = planes[i].r.x - planes[j].r.x;
        float b = planes[i].r.y - planes[j].r.y;
        float r = sqrt(a*a+b*b);
        
        if (r <= DISTANCE_ALARM_DIST)  {
          isDistanceAlarm = true;
          if (r <= CRASH_DIST) {
            isCrashAlarm = true;
            crash1 = i;
            crash2 = j;
          }
        }
      }
      if (isCrashAlarm) {
        break;
      }
    }
    
    if(isFuelAlarm) {
      loopSound(4);
      fuelAlarmActive = true;
    }
    else {
      stopSound(4);
      fuelAlarmActive = false;
    }
    
    if(isCrashAlarm) {
      playSound(2);
      stopSound(0);
      stopSound(3);
      g.over = true;
      g.crash1 = crash1;
      g.crash2 = crash2;
    }
    else if(isDistanceAlarm) {
      loopSound(3);
      proximityAlarmActive = true;
    }
    else {
      stopSound(3);
      proximityAlarmActive = false;
      if(!atLeastOneAlive) {
        over = true;
      }
    }
    
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
  theta += 2*PI;
  theta = theta % (2*PI);
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

int getRegionFromPoint(PVector p) {
  if (p.x <= WALL_THICKNESS) {
    if (p.y <= height/4) {
      return REGION_NW;
    }
    if (p.y >= 3*height/4) {
      return REGION_SW;
    }
    return REGION_W;
  }
  if (p.x >= width-WALL_THICKNESS) {
    if (p.y <= height/4) {
      return REGION_NE;
    }
    if (p.y >= 3*height/4) {
      return REGION_SE;
    }
    return REGION_E;
  }
  if (p.y <= WALL_THICKNESS) {
    if (p.x <= width/4) {
      return REGION_NW;
    }
    if (p.x >= width*3/4) {
      return REGION_NE;
    }
    return REGION_N;
  }
  if (p.y >= height-WALL_THICKNESS) {
    if (p.x <= width/4) {
      return REGION_SW;
    }
    if (p.x >= width*3/4) {
      return REGION_SE;
    }
    return REGION_S;
  }
  return -1;
}

static class Angle {
  public static float normalize(float theta) {
    return ((theta % (2*PI)) + (2*PI)) % (2*PI);
  }
  
 /**
  * Computes "b-a" in angular terms, i.e. the smallest
  * (in terms of magnitude) angle x such that a+x = b.
  */
  public static float sub(float b, float a) {
    a = normalize(a);
    b = normalize(b);
    
    float diff = b-a;
    float mag = abs(diff);
    
    float answer = b-a;
    if (mag < PI) {
      return answer;
    }
    else {
      if (answer > 0) {
        return answer-2*PI;
      }
      else {
        return 2*PI-answer;
      }
    }
  }
}

String secsToTime(int secs) {
  
  secs = max(secs, 0);
  String s = floor(secs/60)+":";
  secs = secs % 60;
  if (secs < 10) {
    s += "0";
  }
  s += secs;
  return s;
}

// Convenience function for drawing text because Processing.js's
// textSize is broken as of writing this code.
void textx(String t, float s, float x, float y) {
   pushMatrix();
   translate(x,y);
   scale(s);
   text(t, 0, 0);
   popMatrix();
}

int jitterRegion(int region) {
   int t = region + round(random(-1, 1));
   if (t < 0) 
      t += 8;
   t = t % 8;
   return t;
}
