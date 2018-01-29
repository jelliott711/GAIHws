int Len = 1200;
int Height = 600;
int time;
int Heartbeat = 1000;
int numBeats = 0;
void setup() {
  size(1200, 600);
  frameRate(30);
  time = millis();
}
int i = 5;
int tx1 = Len - 200;
int ty1 = 100;
int tx2 = Len - 200;
int ty2 = 50;
int tx3 = Len - 150;
int ty3 = 75;
int avgX = (tx1 + tx2 + tx3) / 3;
int avgY = (ty1 + ty2 + ty3) / 3;
boolean doneRot = false;
float deg = 0;
void draw() {
  if(millis() - time >= Heartbeat && numBeats != 2 && numBeats != 5){
    time = millis();
    numBeats++; 
  }
  if(doneRot){
    doneRot = false;
    time = millis();
    numBeats++; 
  }
  if(numBeats == 2){
    background(0);
    translate(avgX, avgY);
    rotate(deg);
    translate(-avgX, -avgY);
    triangle(tx1, ty1, tx2, ty2, tx3, ty3);
    translate(avgX, avgY);
    rotate(-deg);
    translate(-avgX, -avgY);
    rect (Len-100, 50, 50, 50);
    deg += 0.05;
    if(deg >= PI){
      doneRot = true; 
    }
  } else if(numBeats == 5){
    background(0);
    translate(avgX, avgY);
    rotate(deg);
    translate(-avgX, -avgY);
    triangle(tx1, ty1, tx2, ty2, tx3, ty3);
    translate(avgX, avgY);
    rotate(-deg);
    translate(-avgX, -avgY);
    rect (Len-100, 50, 50, 50);
    deg -= 0.05;
    if(deg <= 0.0){
      doneRot = true; 
    }
  } else if(numBeats >= 7 && i < 1000){
    background(0);
    rect(Len - 100, 50, 50, 50);
    translate(-i, 0);
    triangle(tx1, ty1, tx2, ty2, tx3, ty3);
    i+=5;
  } else {
    background(0);
    translate(avgX, avgY);
    rotate(deg);
    translate(-avgX, -avgY);
    triangle(tx1, ty1, tx2, ty2, tx3, ty3);
    translate(avgX, avgY);
    rotate(-deg);
    translate(-avgX, -avgY);
    rect (Len-100, 50, 50, 50);
  }
}