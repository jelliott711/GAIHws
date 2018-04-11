import java.util.Random;
import java.util.*;

//Flat prob Wins/Deaths out of 500 trials: 308 wins to 192 deaths
//Dynamic prob Wins/Deaths out of 500 trials: 390 wins to 110 deaths

int FROG_WIDTH = 40;
int GAME_WIDTH_IN_SQUARES = 12;
int GAME_WIDTH = FROG_WIDTH * GAME_WIDTH_IN_SQUARES;
int GAME_HEIGHT_IN_SQUARES = 4;
int GAME_HEIGHT = FROG_WIDTH * GAME_HEIGHT_IN_SQUARES;
float TRUCK_WIDTH = 1.3*FROG_WIDTH;
float TRUCK_SPEED = 0.7;

int START_FROG_X = 5;
int START_FROG_Y = GAME_HEIGHT_IN_SQUARES-1;

int frog_x = START_FROG_X;
int frog_y = START_FROG_Y;

int TRUCK_ROWS = GAME_HEIGHT_IN_SQUARES-2;
int TRUCKS_PER_ROW = 2;  // Making this a little easier than initally planned

float[][] truck_x = {{0, 100, 300}, 
  {25, 225, 325}};

Random rng = new Random();

// Constants for frog moves, indexing into policy

int STAY = 0;
int MOVE_LEFT = 1;
int MOVE_RIGHT = 2;
int MOVE_UP = 3;
int MOVE_DOWN = 4;
int POSSIBLE_MOVES = 5;

int frame = 0;
int deaths = 0;
int wins = 0;
// Only allow action every this many frames
int FROG_FRAMES = 6;

// Barrier or not in each of 8 spaces around frog
int ENVIRONMENTS = 256;

HashMap<String, ArrayList<Node>> QMap = new HashMap<String, ArrayList<Node>>();

float learnRate = 0.2;
float discount = 0.3;


boolean dead_frog = false;
boolean winner_frog = false;

//toggle this to switch between Q picking methods
boolean pickFlatProb = false;

Node prevNode;

public class Node implements Comparable {
  public int action;
  public float value;

  public Node(int action) {
    this.action = action;
    this.value = 1.0;
  }

  @Override
    public boolean equals(Object o) {
    return (o == this || ((o instanceof Node) && (this.action == ((Node)o).action)));
  }

  @Override
    public int compareTo(Object other) {
    float diff = (this.value - ((Node)other).value);
    if (diff > 0) {
      return 1;
    } else if (diff < 0) {
      return -1;
    } else {
      return 0;
    }
  }
}

void settings() {
  size(GAME_WIDTH, GAME_HEIGHT);
}

void draw() {
  if (wins + deaths < 500) {
    frame++;
    int frame_mod = FROG_FRAMES;
    float truck_speed = TRUCK_SPEED;
    if (keyPressed && key == 'f') {
      frame_mod = FROG_FRAMES/3;
      truck_speed = TRUCK_SPEED * 3;
    }
    background(255);
    update_trucks(truck_speed);
    draw_trucks();
    boolean[][] environment = get_nearby_squares();
    int best_move = decide_move(environment);

    if (frame % frame_mod == 0) {
      move_frog(best_move);
    }
    dead_frog = check_death();
    if (dead_frog) {
      deaths++;
    }
    fill(240, 0, 0);
    text(deaths, FROG_WIDTH/2, FROG_WIDTH/2);
    draw_frog(dead_frog);
    winner_frog = (!dead_frog && frog_y == 0);
    if (winner_frog) {
      wins++;
    }
    text(wins, FROG_WIDTH*(GAME_WIDTH_IN_SQUARES-1), FROG_WIDTH/2);
    if (dead_frog || winner_frog) {
      frog_x = START_FROG_X;
      frog_y = START_FROG_Y;
    }
  }
}

void draw_frog(boolean dead_frog) {
  if (dead_frog) {
    fill(240, 0, 0);
  } else {
    fill(0, 240, 0);
  }
  // Legs
  line(frog_x * FROG_WIDTH, frog_y * FROG_WIDTH, (frog_x + 1)*FROG_WIDTH, (frog_y + 1)*FROG_WIDTH);
  line(frog_x * FROG_WIDTH, (frog_y + 1) * FROG_WIDTH, (frog_x + 1)*FROG_WIDTH, frog_y * FROG_WIDTH);
  // body
  float frog_true_x = FROG_WIDTH * ((float)frog_x + 0.5);
  float frog_true_y = FROG_WIDTH * ((float)frog_y + 0.5);
  ellipse(frog_true_x, frog_true_y, FROG_WIDTH, FROG_WIDTH);
}

void update_trucks(float truck_speed) {
  for (int i = 0; i < TRUCK_ROWS; i++) {
    for (int j = 0; j < TRUCKS_PER_ROW; j++) {
      if (i % 2 == 0) {
        truck_x[i][j] += truck_speed;
        if (truck_x[i][j] >= GAME_WIDTH) {
          truck_x[i][j] = 0 - TRUCK_WIDTH;
        }
      } else {
        truck_x[i][j] -= truck_speed;
        if (truck_x[i][j] <= -TRUCK_WIDTH) {
          truck_x[i][j] = GAME_WIDTH;
        }
      }
    }
  }
}

void draw_trucks() {
  fill(120, 0, 0);
  for (int i = 0; i < TRUCK_ROWS; i++) {
    for (int j = 0; j < TRUCKS_PER_ROW; j++) {
      float truck_y = (i+1)*FROG_WIDTH;
      rect(truck_x[i][j], truck_y, TRUCK_WIDTH, FROG_WIDTH);
    }
  }
}

void move_frog(int best_move) {
  if (best_move == MOVE_LEFT) {
    frog_x--;
  } else if (best_move == MOVE_RIGHT) {
    frog_x++;
  } else if (best_move == MOVE_UP) {
    frog_y--;
  } else if (best_move == MOVE_DOWN) {
    frog_y++;
  }
}

boolean check_death() {
  // Die if we wander off the playing field
  if (frog_x < 0 || frog_x >= GAME_WIDTH_IN_SQUARES || frog_y < 0 || frog_y >= GAME_HEIGHT_IN_SQUARES) {
    return true;
  }
  for (int i = 0; i < TRUCK_ROWS; i++) {
    for (int j = 0; j < TRUCKS_PER_ROW; j++) {
      if (truck_in_square(i, j, frog_x, frog_y)) {
        return true;
      }
    }
  }
  return false;
}

// square_x and square_y are in FROG_WIDTH boxes
boolean truck_in_square(int truck_row, int truck, int square_x, int square_y) {
  if ((truck_row + 1) != square_y) {
    return false;
  }
  float truck_min_x = truck_x[truck_row][truck];
  float truck_max_x = truck_min_x + TRUCK_WIDTH;
  float square_min_x = square_x * FROG_WIDTH;
  float square_max_x = (square_x + 1) * FROG_WIDTH;
  if (square_max_x >= truck_min_x && square_min_x <= truck_max_x) {
    return true;
  }
  return false;
}

String boardToString(boolean[][] environment) {
  String s = "";
  for (int i = 0; i < 3; i ++) {
    for (int j = 0; j < 3; j++) {
      s += (environment[i][j]) ? "1" : "0" ;
    }
  }
  return s;
}

int decide_move(boolean[][] environment) {
  ArrayList<Node> options = new ArrayList<Node>();
  String bString = boardToString(environment);
  if (QMap.containsKey(bString)) {
    options = QMap.get(bString);
  } else {
    for (int i = 0; i < POSSIBLE_MOVES; i++) {
      options.add(new Node(i));
    }
    QMap.put(bString, options);
  }
  Collections.sort(options);
  Node selected = pickFlatProb ? selectFlatProb(options) : selectDynProb(options);
  if (prevNode != null) {
    float reward = 0;
    if (dead_frog) { 
      reward = -1;
    } else if (winner_frog) { 
      reward = 50;
    }
    //Q(a,s) = (1 - a) * Q(a,s) + a * (r + y * maxQ(a',s'))
    //where Q(a,s) == prevNode.value
    //a == learnRate
    //r == reward
    //y == discount
    //maxQ(a',s') = options.get(options.size() - 1).value ; this is because the node list is sorted by Q value
    float val = ((1 - learnRate) * prevNode.value) + (learnRate * (reward + discount * selected.value));
    prevNode.value = val;
    //print(prevNode.action + "-----" + prevNode.value + "\n");
  }
  prevNode = selected;
  //print(selected.action + "-----" + selected.value + "\n");
  return selected.action;
}

Node bestNode(ArrayList<Node> options) {
  Node best = options.get(0);
  for (Node n : options) {
    if (n.value > best.value) {
      best = n;
    }
  }
  return best;
}

Node selectFlatProb(ArrayList<Node> options) {
  float i = rng.nextFloat();
  float thresh = 0.2;
  return (i <= thresh) ? options.get(rng.nextInt(options.size())) : bestNode(options);
}

Node selectDynProb(ArrayList<Node> options) {
  float i = rng.nextFloat();
  float thresh = 0.8/(wins + 1);
  return (i <= thresh) ? options.get(rng.nextInt(options.size())) : bestNode(options);
}

// booleans are true if squares are occupied
boolean[][] get_nearby_squares() {
  boolean[][] environment = new boolean[3][3];
  for (int i = 0; i < 3; i++) {
    for (int j = 0; j < 3; j++) {
      environment[i][j] = false;
      int square_x = frog_x + j - 1;
      int square_y = frog_y + i - 1;
      if (square_x < 0 || square_y < 0 || square_x >= GAME_WIDTH_IN_SQUARES || square_y >= GAME_HEIGHT_IN_SQUARES) {
        environment[i][j] = true;  // treat off-board spaces as occupied;
      } else {
        if (square_y-1 >= 0 && square_y-1 < TRUCK_ROWS) {
          for (int k = 0; k < TRUCKS_PER_ROW; k++) { // only check in same row
            if (truck_in_square(square_y-1, k, square_x, square_y)) {
              environment[i][j] = true;
            }
          }
        }
      }
    }
  }
  return environment;
}