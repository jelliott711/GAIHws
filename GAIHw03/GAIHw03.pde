import java.util.HashMap;

static final float AGENT_RADIUS = 20;
static final int ARENA_SIZE = 800;
static final int TEAM_SIZE = 5;
// Agent max speed
static final float MAX_SPEED = 5;
static final float MAX_ACCEL = 10;
// Max time to enemy:  max seconds in the future to predict enemy movement for pursue
static final float MAX_TIME_TO_ENEMY = 2;
static final float MAX_ROT_SPEED = ((float) Math.PI)/10;
static final float ALIGN_TARGET_RAD = ((float) Math.PI)/60;
static final float ALIGN_SLOW_RAD = ((float) Math.PI)/15;
static final float BULLET_WIDTH = 3;
static final float BULLET_SPEED = 10;
static final int MAX_HEALTH = 20;

// Return codes for Behavior Tree tasks.
// If you wanted to implement an action that takes several frames,
// you could add a BUSY signal as well as a way to keep track of where
// you are in the tree, picking up again on the next frame.  But this assignment
// doesn't require that.
static final int FAIL = 0;
static final int SUCCESS = 1;

Agent[] redTeam = new Agent[TEAM_SIZE];
Agent[] blueTeam = new Agent[TEAM_SIZE];

class Agent {
  float x;
  float y;
  boolean redTeam;
  float angle;
  Blackboard blackboard;
  Task btree;
  PVector velocity;
  PVector linear_steering;
  float rotational_steering;
  boolean dead;
  boolean firing;
  Bullet bullet;
  int health;

  Agent(float x, float y, boolean redTeam, float angle) {
    this.x = x;
    this.y = y;
    this.redTeam = redTeam;
    this.angle = angle;
    this.blackboard = new Blackboard();
    this.velocity = new PVector(0, 0);
    this.linear_steering = new PVector(0, 0);
    this.rotational_steering = 0;
    this.dead = false;
    this.firing = false;
    this.bullet = new Bullet();
    this.health = MAX_HEALTH;
  }

  void draw() {
    if (dead) {
      return;
    }
    translate(x, y);
    rotate(angle);
    if (redTeam) {
      fill(255*(health+2)/(MAX_HEALTH+2), 0, 0);
    } else {
      fill(0, 0, 255*(health+2)/(MAX_HEALTH+2));
    }
    ellipse(0, 0, AGENT_RADIUS*2, AGENT_RADIUS*2);
    line(0, 0, AGENT_RADIUS, 0);
    rotate(-angle);
    translate(-x, -y);
  }
  
  void setBTree(Task btree) {
    this.btree = btree;
  }

  void act() {
    checkDeath();
    if (dead) {
      return;
    }
    linear_steering = new PVector(0,0);
    rotational_steering = 0;
    btree.execute();
    if (linear_steering.mag() > MAX_ACCEL) {
      linear_steering.setMag(MAX_ACCEL);
    }
    velocity.add(linear_steering);
    if (velocity.mag() > MAX_SPEED) {
      velocity.setMag(MAX_SPEED);
    }
    x += velocity.x;
    y += velocity.y;
    if (Math.abs(rotational_steering) > MAX_ROT_SPEED) {
      rotational_steering = Math.copySign(MAX_ROT_SPEED, rotational_steering);
    }
    angle += rotational_steering;
    if (firing && !bullet.active) {
      PVector firingVector = PVector.fromAngle(angle);
      PVector displacementVector = firingVector.copy().setMag(AGENT_RADIUS+BULLET_WIDTH);
      bullet = new Bullet(x + displacementVector.x, y + displacementVector.y,
                          firingVector);
      bullet.draw();
    } else if (bullet.active) {
      // We'll just do this here
      bullet.update();
      bullet.draw();
    }
  }
  
  // We will be in charge of damaging ourselves in response to enemy collisions & bullets;
  // same for them
  void checkDamage(Agent target) {
    if (target.dead) {
      return;
    }
    if (dist(x, y, target.x, target.y) < AGENT_RADIUS *2) {
      health--;
    }
    if (dist(x, y, target.bullet.x, target.bullet.y) < AGENT_RADIUS + BULLET_WIDTH/2) {
      health--;
      target.bullet.active = false;
    }
    // Death checked later to avoid unfair tiebreaking
    return;
  }
  
  void checkDeath() {
    if (health <= 0) {
      dead = true;
    }
  }
  
}

class Bullet {
  boolean active;
  float x;
  float y;
  PVector velocity;
  
  Bullet() {
    active = false;
    x = 0;
    y = 0;
    velocity = new PVector(0,0);
  }
  
  Bullet(float x, float y, PVector direction) {
    active = true;
    this.x = x;
    this.y = y;
    this.velocity = direction.setMag(BULLET_SPEED);
  }
  
  void draw() {
    if (!active) {
      return;
    }
    fill(0,0,0);
    ellipse(x,y, BULLET_WIDTH, BULLET_WIDTH);
  }
  
  void update() {
    if (!active) {
      return;
    }
    x += velocity.x;
    y += velocity.y;
    if (x < 0 || y < 0 || x > ARENA_SIZE || y > ARENA_SIZE) {
      // offscreen
      active = false;
    }
    // We handle collisions elsewhere
  }
  
}

void settings() {
  size(ARENA_SIZE, ARENA_SIZE);
}

void setup() {

  for (int i = 0; i < TEAM_SIZE; i++) {
    redTeam[i] = new Agent((float)ARENA_SIZE/4, (float)ARENA_SIZE/8 + 100*i, true, (float)PI);
    redTeam[i].blackboard.put("Friends", redTeam);
    redTeam[i].blackboard.put("Enemies", blueTeam);
    redTeam[i].blackboard.put("Agent", redTeam[i]);
    redTeam[i].setBTree(new RedDecisionTree(redTeam[i].blackboard));
    blueTeam[i] = new Agent((float)3*ARENA_SIZE/4, (float)ARENA_SIZE/8 + 100*i, false, 0);
    blueTeam[i].blackboard.put("Enemies", redTeam);
    blueTeam[i].blackboard.put("Friends", blueTeam);
    blueTeam[i].blackboard.put("Agent", blueTeam[i]);
    blueTeam[i].setBTree(new BlueDecisionTree(blueTeam[i].blackboard));
  }
}

void draw() {
  background(128,128,128);
  for (int i = 0; i < TEAM_SIZE; i++) {
    redTeam[i].act();
    blueTeam[i].act(); //<>//
  }
  for (int i = 0; i < TEAM_SIZE; i++) {
    for (int j = 0; j < TEAM_SIZE; j++) {
      redTeam[i].checkDamage(blueTeam[j]);
      blueTeam[i].checkDamage(redTeam[j]);
    }
    redTeam[i].draw();
    blueTeam[i].draw();
  }
}

abstract class Task {
  abstract int execute();  // returns FAIL = 0, SUCCESS = 1
  Blackboard blackboard;
  // You can implement an abstract clone() here, or you may not find it necessary
}

class Blackboard {
  HashMap<String, Object> lookup;

  Blackboard() {
    lookup = new HashMap<String, Object>();
  }

  public Object get(String key) {
    return lookup.get(key);
  }

  public void put(String key, Object val) {
    lookup.put(key, val);
  }
}

class Flee extends Task {
  Flee(Blackboard bb) {
    this.blackboard = bb;
  }

  int execute() {
    Agent agent = (Agent) blackboard.get("Agent");
    Agent[] enemies = (Agent[]) blackboard.get("Enemies");
    
    PVector steering = new PVector(0, 0);
    for (int i = 0; i < enemies.length; i++) {
      // Want a vector that points from the enemy - then don't have to flip it
      PVector displacement = new PVector(agent.x - enemies[i].x, agent.y - enemies[i].y);
      steering.add(displacement);
    }
    if (steering.mag() > MAX_ACCEL) {
      steering.setMag(MAX_ACCEL);
    }
    agent.linear_steering.add(steering);

    return SUCCESS;
  }
}

class Mark extends Task {
  Mark(Blackboard bb) {
    this.blackboard = bb;
  }
  
  int execute(){
    Agent agent = (Agent) blackboard.get("Agent");
    Agent[] enemies = (Agent[]) blackboard.get("Enemies");
    if(enemies == null || enemies.length == 0){
      return FAIL; 
    }
    float dist = MAX_FLOAT;
    Agent closest = null;
    for(Agent a : enemies){
      if(dist(a.x, a.y, agent.x, agent.y) < dist && !a.dead){
        closest = a;
        dist = dist(a.x, a.y, agent.x, agent.y);
      }
    }
    if(closest == null){ return FAIL; }
    agent.blackboard.put("Mark", closest);
    return SUCCESS; 
  }
}

class Pursue extends Task {
  Pursue(Blackboard bb) {
    this.blackboard = bb;
  }
  int execute(){
    Agent agent = (Agent) blackboard.get("Agent");
    Agent mark = (Agent) blackboard.get("Mark");
    if(mark == null){
      return FAIL;
    }
    PVector displacement = new PVector(mark.x - agent.x, mark.y - agent.y);
    if (displacement.mag() > MAX_ACCEL) {
      displacement.setMag(MAX_ACCEL);
    }
    agent.linear_steering.add(displacement);

    return SUCCESS; 
  }
}

class Aim extends Task {
  Aim(Blackboard bb) {
    this.blackboard = bb;
  }
  
  int execute(){
    Agent agent = (Agent) blackboard.get("Agent");
    Agent mark = (Agent) blackboard.get("Mark");
    if(mark == null || mark.dead){
      return FAIL;
    }
    //Align code based on Professor Gold's Assignment 1 Steering Solution
    PVector direction = new PVector(mark.x - agent.x, mark.y - agent.y);
    float angle = direction.heading();

    float difference = boundDiff(angle - agent.angle);
    
    float rotationSize = abs(difference);
    if (rotationSize < ALIGN_TARGET_RAD) {
      return FAIL;
    }
    
    agent.angle += (difference / rotationSize) * (rotationSize > ALIGN_SLOW_RAD ? MAX_ROT_SPEED : MAX_ROT_SPEED * rotationSize / ALIGN_SLOW_RAD);
    
    return SUCCESS; 
  }
}

class Shoot extends Task {
  Shoot(Blackboard bb) {
    this.blackboard = bb;
  }
  
  int execute(){
    Agent agent = (Agent) blackboard.get("Agent");
    Agent mark = (Agent) blackboard.get("Mark");
    Bullet myBullet = agent.bullet;
    if(myBullet.active || agent.firing || mark == null || mark.dead){
      return FAIL;
    }
    agent.firing = true;
    return SUCCESS; 
  }
}

class Help extends Task {
  Help(Blackboard bb) {
    this.blackboard = bb;
  }
  
  int execute(){
    Agent agent = (Agent) blackboard.get("Agent");
    Agent[] friends = (Agent[]) blackboard.get("Friends");
    float dist = MAX_FLOAT;
    Agent closest = null;
    for(Agent a : friends){
      if(dist(a.x, a.y, agent.x, agent.y) < dist && !a.dead){
        Agent mark = (Agent) a.blackboard.get("Mark");
        if(mark != null && !mark.dead){
          closest = a;
          dist = dist(a.x, a.y, agent.x, agent.y);
        }
      }
    }
    if(closest == null || dist == MAX_FLOAT){ return FAIL; }
    agent.blackboard.put("Mark", closest.blackboard.get("Mark"));
    return SUCCESS; 
  }
}

class RedDecisionTree extends Task {
  Task[] executeList;
  RedDecisionTree(Blackboard bb) {
    this.blackboard = bb;
    this.executeList = new Task[]{new Shoot(bb), new Aim(bb), new Mark(bb) };
  }
  
  int execute(){
    Agent agent = (Agent) blackboard.get("Agent");
    agent.firing = false;
    int i = 1;
    if(inLineOfSight(this.blackboard)){
      i = 0;
    }
    for(; i < executeList.length; i++){
      if(executeList[i].execute() == SUCCESS){ return SUCCESS; }
    }
    return FAIL; 
  }
}

class BlueDecisionTree extends Task {
  Task[] markList;
  Task[] executeList;
  BlueDecisionTree(Blackboard bb) {
    this.blackboard = bb;
    this.markList = new Task[]{new Help(bb), new Mark(bb)};
    this.executeList = new Task[]{new Shoot(bb), new Aim(bb), new Pursue(bb)};
  }
  
  int execute(){
    Agent agent = (Agent) blackboard.get("Agent");
    Agent mark = (Agent) blackboard.get("Mark");
    agent.firing = false;
    if(mark == null || mark.dead){
      for(int i = 0; i < markList.length; i++){
        if(markList[i].execute() == SUCCESS){ return SUCCESS; } 
      }
      return FAIL;
    } else {
      int i = 1;
      if(inLineOfSight(this.blackboard)){
        i = 0;
      }
      for(; i < executeList.length; i++){
        if(executeList[i].execute() == SUCCESS){ return SUCCESS; }
      }
      return FAIL;
    }
  }
}


float boundDiff(float difference){
   while (difference < -PI) {
     difference += 2*PI;
   }
   while (difference >= PI) {
     difference -= 2*PI;
   }
   return difference;
}

boolean inLineOfSight(Blackboard blackboard){
  Agent agent = (Agent) blackboard.get("Agent");
  Agent mark = (Agent) blackboard.get("Mark");
  if(mark != null && !mark.dead){  
    PVector direction = new PVector(mark.x - agent.x, mark.y - agent.y);
    float angle = direction.heading();
    float difference = boundDiff(angle - agent.angle);
  
    float rotationSize = abs(difference);
    if(rotationSize < ALIGN_TARGET_RAD && !mark.dead){
      return true;
    }
  }
  return false;
}