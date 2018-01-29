
PVector currentPos;
float followRad = 15;
float targetRad = 10;

int targetHitRadius = 40;
int targetSlowRadius = 75;
int maxMoveSpeed = 5;
float curVelMag = 1;
PVector curVel;
PVector accel;
PVector decel;

float angleHitRadius = PI/30;
float angleSlowRadius = PI/10;
float maxAngleSpeed = PI/25;
float accelerationMag = 0.0;
int   accelFrames = 10;
float decelerationMag = 0.0;
int decelFrames = 10;

float curAngle = 0;
float curAngleSpeed = maxAngleSpeed;
ArrayList<PVector> blackHoles;
float blackHoleConst = 150.0f;

int maxX = 400;
int maxY = 400;

void setup() {
  size(400, 400);
  currentPos = new PVector(200.0, 200.0);
  blackHoles = new ArrayList<PVector>();
}

void draw() {
  background(100);
  fill(0);
  noCursor();
  PVector target = new PVector(mouseX, mouseY);
  PVector path = PVector.sub(target, currentPos);
  PVector targetEdge = PVector.sub(target, PVector.mult(path.normalize(), targetRad + targetHitRadius));
  PVector currentEdge = PVector.sub(currentPos, PVector.mult(path.normalize(), followRad));
  PVector pathToEdge = PVector.sub(targetEdge, currentEdge);
  float distToTarget = pathToEdge.mag();
  print (distToTarget + "\n");
  //accMag = 0;
  
  if(distToTarget <= targetSlowRadius && curVelMag > 1){
    decelerationMag = (sq(curVelMag)) / (2*(targetSlowRadius));
    curVelMag -= (sq(curVelMag)) / (2*(targetSlowRadius));
  } else if(distToTarget > targetSlowRadius && curVelMag < maxMoveSpeed){
    curVelMag += (sq(maxMoveSpeed) - sq(curVelMag)) / (2*(targetSlowRadius));
  }
  
  if(distToTarget == targetHitRadius){
    curVelMag = 0; 
  } else if(curVelMag < 1){
    curVelMag = 1;
  } else if(curVelMag > maxMoveSpeed){
    curVelMag = maxMoveSpeed; 
  }

  PVector nextPos = currentPos;

  if(pathToEdge.mag() < curVelMag){
    nextPos = PVector.add(currentPos, pathToEdge);
  } else{
    nextPos = PVector.add(currentPos, PVector.mult(pathToEdge.normalize(), curVelMag));
  }

  PVector avgBHForce = new PVector(0, 0);
  for(PVector bh : blackHoles){
    PVector bhPath = PVector.sub(currentPos, bh);
    PVector bhEdge = PVector.add(bh, PVector.mult(bhPath.normalize(), targetRad));
    PVector fEdge = PVector.sub(currentPos, PVector.mult(bhPath.normalize(), followRad));
    PVector pathToBHEdge = PVector.sub(fEdge, bhEdge);
    float bhForce = blackHoleConst/pathToBHEdge.magSq();
    PVector bhOff = PVector.mult(pathToBHEdge.normalize(), bhForce);
    avgBHForce.add(bhOff);
    ellipse(bh.x, bh.y, targetRad*2, targetRad*2);
  }
  
  if(avgBHForce.mag() > 0){
    avgBHForce.div(blackHoles.size());
    nextPos.add(avgBHForce);
  }
  
  nextPos = clipToWindow(nextPos);
  fill(255);
  ellipse(target.x, target.y, targetRad * 2, targetRad * 2);
  ellipse(currentPos.x, currentPos.y, followRad * 2, followRad * 2);
  if (nextPos != currentPos) {
    float hypotenuse = PVector.sub(currentPos, nextPos).mag();
    float adjacent = currentPos.x - nextPos.x;
    float targetAngle = acos(adjacent/hypotenuse);
    if (currentPos.y - nextPos.y  < 0) {
      targetAngle *= -1;
    }

    curAngle = detNextAngle(curAngle, targetAngle);

    float xEnd = followRad * cos(curAngle);
    float yEnd = followRad * sin(curAngle);

    PVector lineEnd = clipToWindow(new PVector(currentPos.x - xEnd, currentPos.y - yEnd));
    stroke(0);
    line(currentPos.x, currentPos.y, lineEnd.x, lineEnd.y);
  } 
  
  currentPos = nextPos;
}

void mouseReleased(){
  blackHoles.add(new PVector(mouseX, mouseY));
}

float detNextAngle(float start, float target) {
  float toRet = start;
  float angleDecel = maxAngleSpeed/2;
  if (start >= 0) {
    if (target > start) {
      if(toRet >= target - angleSlowRadius && curAngleSpeed >= angleDecel){
        curAngleSpeed -= angleDecel;
      } else if(toRet < target - angleSlowRadius){
        curAngleSpeed = maxAngleSpeed; 
      }
      if (toRet <= target - angleHitRadius) { 
        toRet = start + curAngleSpeed;
      }
    } else if (target <= start - PI) {
      toRet = start + curAngleSpeed;
      if (toRet > PI) { 
        toRet = normPItoNPI(toRet);
      }
    } else {
      if(toRet <= target + angleSlowRadius && curAngleSpeed >= angleDecel) {
        curAngleSpeed -= angleDecel;
      } else if(toRet > target - angleSlowRadius){
        curAngleSpeed = maxAngleSpeed; 
      }
      if (toRet >= target + angleHitRadius) { 
        toRet = start - curAngleSpeed;
      }
    }
  } else {
    if (target < start) {
      if(toRet <= target + angleSlowRadius && curAngleSpeed >= angleDecel) {
        curAngleSpeed -= angleDecel;
      } else if(toRet > target - angleSlowRadius){
        curAngleSpeed = maxAngleSpeed; 
      }
      if (toRet >= target + angleHitRadius) { 
        toRet = start - curAngleSpeed;
      }
    } else if (target >= start + PI) {
      toRet = start - curAngleSpeed;
      if (toRet <= -PI) { 
        toRet = normPItoNPI(toRet);
      }
    } else {
      if(toRet >= target - angleSlowRadius && curAngleSpeed >= angleDecel){
        curAngleSpeed -= angleDecel;
      } else if(toRet < target - angleSlowRadius){
        curAngleSpeed = maxAngleSpeed; 
      }
      if (toRet <= target - angleHitRadius) { 
        toRet = start + curAngleSpeed;
      }
    }
  }
  return toRet;
}

float normPItoNPI(float angle) {
  float toRet = angle;
  if (angle > PI) {
    toRet = 2*-PI + angle;
  } else if (angle <= -PI) {
    toRet = 2*PI + angle;
  }
  return toRet;
}

PVector clipToWindow(PVector pos){
 if(pos.x > maxX){ pos.x = maxX; }
 else if(pos.x < 0){ pos.x = 0; }
 if(pos.y > maxY){ pos.y = maxY; }
 else if(pos.y < 0){ pos.y = 0; }
 return pos;
}