Character c;

void setup() {
  size(500,500);
  background(#0088FF);
  frameRate(20);
  
  resetDrawState();
  textSize(70);
  textAlign(CENTER, CENTER);
  text("Loading...", width/2, height/2);
  
  c = new Character();
}

void draw() {
  background(#0088FF);
  c.draw();
} 

void resetDrawState() {
  textSize(20);
  textAlign(LEFT, TOP);
  strokeWeight(1);
  stroke(0);
  fill(255);
  rectMode(CORNERS);
}

class Character {
  PVector v;
  PVector r;
  public Character() {
    v = new PVector(0, 0);
    r = new PVector(width/2, height);
  }
  
  void draw() {
    resetDrawState();
    rect(r.x-20, r.y-50, r.x+20, r.y-1);
  }
  
  PVector getNextDesiredLocation(float delta_t) {
    
    return PVector.add(
      PVector.add(r, PVector.mult(v, delta_t))
    );
  }
}
