import java.io.FileReader;
import java.io.FileWriter;
import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.FileNotFoundException;
import java.util.Random;
import java.util.ArrayList;
import java.io.*;

static final int SQUARE_WIDTH = 40;
static final int NUM_COLUMNS = 8;

boolean whiteTurn = false;
// We want to keep these enum values so that flipping ownership is just a sign change
static final int BLACK = 1;
static final int NOBODY = 0;
static final int WHITE = -1;
static final int TIE = 2;

Random rng = new Random();

static final float WIN_ANNOUNCE_X = NUM_COLUMNS / 2 * SQUARE_WIDTH;
static final float WIN_ANNOUNCE_Y = (NUM_COLUMNS + 0.5) * SQUARE_WIDTH;

static final int BACKGROUND_BRIGHTNESS = 128;

static final int MAX_DEPTH = 7;

static final String TABLES_FILE = "tables.txt";

float WIN_VAL = 100;

boolean gameOver = false;

boolean AIOnly = true;

int[][] board;

int[] keyTable;

HashMap<Integer, MMXMove> transTable;

boolean exit = false;

void settings() {
  size(SQUARE_WIDTH * NUM_COLUMNS, SQUARE_WIDTH * (NUM_COLUMNS + 1));
}

void setup() {
  resetBoard();
  if (!readTables()) {
    print("read fail");
    initKeyTable();
    transTable = new HashMap<Integer, MMXMove>();
  }
}


void resetBoard() {
  board = new int[NUM_COLUMNS][NUM_COLUMNS];
  board[NUM_COLUMNS/2-1][NUM_COLUMNS/2-1] = WHITE;
  board[NUM_COLUMNS/2][NUM_COLUMNS/2] = WHITE;
  board[NUM_COLUMNS/2-1][NUM_COLUMNS/2] = BLACK;
  board[NUM_COLUMNS/2][NUM_COLUMNS/2-1] = BLACK;
}

boolean readTables() {
  try {
    FileInputStream f = new FileInputStream(TABLES_FILE);
    ObjectInputStream o = new ObjectInputStream(f);
    keyTable = (int[]) o.readObject();
    transTable = (HashMap<Integer, MMXMove>) o.readObject();
    o.close();
    f.close();
    return (transTable != null && keyTable != null);
  } 
  catch(Exception e) {
    return false;
  }
}

void initKeyTable() {
  //keyTable[tableSize] - hash for white turn
  int tableSize = ((int) sq(NUM_COLUMNS) * 2) + 1;
  keyTable = new int[tableSize];
  Random r = new Random();
  for (int i = 0; i < tableSize - 1; i++) {
    keyTable[i] = r.nextInt();
  }
}

Integer hashBoard(int[][] board, boolean turn) {
  int retVal = turn ? keyTable[keyTable.length - 1] : 0;
  for (int i = 0; i < NUM_COLUMNS; i++) {
    for (int j = 0; j < NUM_COLUMNS; j++) {
      if (board[i][j] == WHITE) {
        retVal ^= keyTable[(i*NUM_COLUMNS) + j];
      } else if (board[i][j] == BLACK) {
        retVal ^= keyTable[((i*NUM_COLUMNS) + j) * 2];
      }
    }
  }
  return retVal;
}

void cleanup() {
  try {
    FileOutputStream f = new FileOutputStream(TABLES_FILE);
    ObjectOutputStream o = new ObjectOutputStream(f);
    o.writeObject(keyTable);
    o.writeObject(transTable);
    o.close();
    f.close();
  } 
  catch(Exception e) {
    e.printStackTrace();
    print("\n" + e.getMessage() + "\n");
  }
  exit();
}

void draw() {
  if (gameOver) { 
    cleanup();
  } else {
    drawGame();
  }
}

void drawGame() {
  background(BACKGROUND_BRIGHTNESS);
  if (gameOver) return;
  drawBoardLines();
  ArrayList<Move> legalMoves = generateLegalMoves(board, true);
  while (whiteTurn && legalMoves.isEmpty()) {
    ArrayList<Move> blackLegalMoves = generateLegalMoves(board, false);
    if (!blackLegalMoves.isEmpty()) {
      AIPlay(board, false, blackLegalMoves);
    } else {
      checkGameOver(board);

      return;
    }
    legalMoves = generateLegalMoves(board, true);
  }
  if (AIOnly) {
    ArrayList<Move> turnLegalMoves = generateLegalMoves(board, whiteTurn);
    if (!legalMoves.isEmpty()) {
      drawBoardPieces();
      fill(255);
      text("thinking...", WIN_ANNOUNCE_X, WIN_ANNOUNCE_Y);
      AIPlay(board, whiteTurn, turnLegalMoves);
    }
    whiteTurn = !whiteTurn;
  } else {
    if (!whiteTurn) {
      ArrayList<Move> blackLegalMoves = generateLegalMoves(board, false);
      if (!blackLegalMoves.isEmpty()) {
        AIPlay(board, false, blackLegalMoves);
      }
      whiteTurn = true;
    }
    if (mousePressed) {
      int col = mouseX / SQUARE_WIDTH;  // intentional truncation
      int row = mouseY / SQUARE_WIDTH;

      if (whiteTurn) {
        if (legalMoves.contains(new Move(row, col))) {
          board[row][col] = WHITE;
          capture(board, row, col, true);
          whiteTurn = false;
          drawBoardPieces();
          fill(255);
          text("thinking...", WIN_ANNOUNCE_X, WIN_ANNOUNCE_Y);
          whiteTurn = false;
        }
      }
    }
  }
  drawBoardPieces();
}


// findWinner assumes the game is over
int findWinner(int[][] board) {
  int whiteCount = 0;
  int blackCount = 0;
  for (int row = 0; row < NUM_COLUMNS; row++) {
    for (int col = 0; col < NUM_COLUMNS; col++) {
      if (board[row][col] == WHITE) whiteCount++;
      if (board[row][col] == BLACK) blackCount++;
    }
  }
  gameOver = true;
  if (whiteCount > blackCount) {
    return WHITE;
  } else if (whiteCount < blackCount) {
    return BLACK;
  } else {
    return TIE;
  }
}

// declareWinner:  just for displaying winner text
void declareWinner(int winner) {
  textSize(28);
  textAlign(CENTER);
  fill(255);
  if (winner == WHITE) {
    text("Winner:  WHITE", WIN_ANNOUNCE_X, WIN_ANNOUNCE_Y);
  } else if (winner == BLACK) {
    text("Winner:  BLACK", WIN_ANNOUNCE_X, WIN_ANNOUNCE_Y);
  } else if (winner == TIE) {
    text("Winner:  TIE", WIN_ANNOUNCE_X, WIN_ANNOUNCE_Y);
  }
}

// drawBoardLines and drawBoardPieces draw the game
void drawBoardLines() {
  for (int i = 1; i <= NUM_COLUMNS; i++) {
    line(i*SQUARE_WIDTH, 0, i*SQUARE_WIDTH, SQUARE_WIDTH * NUM_COLUMNS);
    line(0, i*SQUARE_WIDTH, SQUARE_WIDTH * NUM_COLUMNS, i*SQUARE_WIDTH);
  }
}

void drawBoardPieces() {
  for (int row = 0; row < NUM_COLUMNS; row++) {
    for (int col= 0; col < NUM_COLUMNS; col++) {
      if (board[row][col] == WHITE) {
        fill(255, 255, 255);
      } else if (board[row][col] == BLACK) {
        fill(0, 0, 0);
      }
      if (board[row][col] != NOBODY) {
        ellipse(col*SQUARE_WIDTH + SQUARE_WIDTH/2, row*SQUARE_WIDTH + SQUARE_WIDTH/2, 
          SQUARE_WIDTH-2, SQUARE_WIDTH-2);
      }
    }
  }
}

class Move {
  int row;
  int col;

  Move(int r, int c) {
    row = r;
    col = c;
  }

  public boolean equals(Object o) {
    if (o == this) {
      return true;
    }

    if (!(o instanceof Move)) {
      return false;
    }
    Move m = (Move) o;
    return (m.row == row && m.col == col);
  }
}

// Generate the list of legal moves for white or black depending on whiteTurn
ArrayList<Move> generateLegalMoves(int[][] board, boolean whiteTurn) {
  ArrayList<Move> legalMoves = new ArrayList<Move>();
  for (int row = 0; row < NUM_COLUMNS; row++) {
    for (int col = 0; col < NUM_COLUMNS; col++) {
      if (board[row][col] != NOBODY) {
        continue;  // can't play in occupied space
      }
      // Starting from the upper left ...short-circuit eval makes this not terrible
      if (capturesInDir(board, row, -1, col, -1, whiteTurn) ||
        capturesInDir(board, row, -1, col, 0, whiteTurn) ||    // up
        capturesInDir(board, row, -1, col, +1, whiteTurn) ||   // up-right
        capturesInDir(board, row, 0, col, +1, whiteTurn) ||    // right
        capturesInDir(board, row, +1, col, +1, whiteTurn) ||   // down-right
        capturesInDir(board, row, +1, col, 0, whiteTurn) ||    // down
        capturesInDir(board, row, +1, col, -1, whiteTurn) ||   // down-left
        capturesInDir(board, row, 0, col, -1, whiteTurn)) {    // left
        legalMoves.add(new Move(row, col));
      }
    }
  }
  return legalMoves;
}

// Check whether a capture will happen in a particular direction
// row_delta and col_delta are the direction of movement of the scan for capture
boolean capturesInDir(int[][] board, int row, int row_delta, int col, int col_delta, boolean whiteTurn) {
  // Nothing to capture if we're headed off the board
  if ((row+row_delta < 0) || (row + row_delta >= NUM_COLUMNS)) {
    return false;
  }
  if ((col+col_delta < 0) || (col + col_delta >= NUM_COLUMNS)) {
    return false;
  }
  // Nothing to capture if the neighbor in the right direction isn't of the opposite color
  int enemyColor = (whiteTurn ? BLACK : WHITE);
  if (board[row+row_delta][col+col_delta] != enemyColor) {
    return false;
  }
  // Scan for a friendly piece that could capture -- hitting end of the board
  // or an empty space results in no capture
  int friendlyColor = (whiteTurn ? WHITE : BLACK);
  int scanRow = row + 2*row_delta;
  int scanCol = col + 2*col_delta;
  while ((scanRow >= 0) && (scanRow < NUM_COLUMNS) &&
    (scanCol >= 0) && (scanCol < NUM_COLUMNS) && (board[scanRow][scanCol] != NOBODY)) {
    if (board[scanRow][scanCol] == friendlyColor) {
      return true;
    }
    scanRow += row_delta;
    scanCol += col_delta;
  }
  return false;
}

// capture:  flip the pieces that should be flipped by a play at (row,col) by
// white (whiteTurn == true) or black (whiteTurn == false)
// destructively modifies the board it's given
void capture(int[][] board, int row, int col, boolean whiteTurn) {
  for (int row_delta = -1; row_delta <= 1; row_delta++) {
    for (int col_delta = -1; col_delta <= 1; col_delta++) {
      if ((row_delta == 0) && (col_delta == 0)) {
        // the only combination that isn't a real direction
        continue;
      }
      if (capturesInDir(board, row, row_delta, col, col_delta, whiteTurn)) {
        // All our logic for this being valid just happened -- start flipping
        int flipRow = row + row_delta;
        int flipCol = col + col_delta;
        int enemyColor = (whiteTurn ? BLACK : WHITE);
        // No need to check for board bounds - capturesInDir tells us there's a friendly piece
        while (board[flipRow][flipCol] == enemyColor) {
          // Take advantage of enum values and flip the owner
          board[flipRow][flipCol] = -board[flipRow][flipCol];
          flipRow += row_delta;
          flipCol += col_delta;
        }
      }
    }
  }
}

// Current evaluation function is just a straight white-black count
float evaluationFunction(int[][] board) {
  float value = 0;
  for (int r = 0; r < NUM_COLUMNS; r++) {
    for (int c = 0; c < NUM_COLUMNS; c++) {
      if ((r == 0 && c == 0) || (r == NUM_COLUMNS - 1 && c == 0) || (r == 0 && c == NUM_COLUMNS - 1) || (r == NUM_COLUMNS - 1 && c == NUM_COLUMNS - 1)) {
        value += board[r][c] * 2;
      } else {
        value += board[r][c];
      }
    }
  }
  return value;
}

// checkGameOver returns the winner, or NOBODY if the game's not over
// --recall the game ends when there are no legal moves for either side
void checkGameOver(int[][] board) {
  ArrayList<Move> whiteLegalMoves = generateLegalMoves(board, true);
  if (!whiteLegalMoves.isEmpty()) {
    return;
  }
  ArrayList<Move> blackLegalMoves = generateLegalMoves(board, false);
  if (!blackLegalMoves.isEmpty()) {
    return;
  }
  // No legal moves, so the game is over
  drawBoardPieces();
  declareWinner(findWinner(board));
}

//wrapper class for a Move and it's minimax value
//Used to determine corresponding move for best minimax value
static class MMXMove implements java.io.Serializable {
  int row;
  int col;
  float value;
  MMXMove() {
    this.row = -1;
    this.col = -1;
    this.value = 0;
  }

  MMXMove(int row, int col, float value) {
    this.row = row;
    this.col = col;
    this.value = value;
  }

  MMXMove(float value) {
    this.row = -1;
    this.col = -1;
    this.value = value;
  }
}

// AIPlay both selects a move and implements it.
// It's given a list of legal moves because we've typically already done that
// work to check whether we should skip the turn because of no legal moves.
// You should implement this so that either white or black's move is selected;
// it's not any more complicated since you need to minimax regardless
void AIPlay(int[][] board, boolean whiteTurn, ArrayList<Move> legalMoves) {

  MMXMove bestMove = minimax(board, MIN_FLOAT, MAX_FLOAT, 0, whiteTurn, MAX_DEPTH);

  if (bestMove != null && bestMove.row != -1 && bestMove.col != -1) {
    board[bestMove.row][bestMove.col] = (whiteTurn ? WHITE : BLACK);
    capture(board, bestMove.row, bestMove.col, whiteTurn);
  } else {
    checkGameOver(board);   // We'll just end up doing this until the end of time
  }
  return;
}


int[][] fakeMove(int[][] board, Move m, boolean white) {
  int[][] boardCpy = new int[NUM_COLUMNS][NUM_COLUMNS];
  for (int i = 0; i < NUM_COLUMNS; i++) {
    arrayCopy(board[i], boardCpy[i]);
  }
  boardCpy[m.row][m.col] = (white ? WHITE : BLACK);
  capture(boardCpy, m.row, m.col, white);
  return boardCpy;
}

//Based on minimax pseudocode in the Lecture Slides
MMXMove minimax(int[][] board, float alpha, float beta, int currentDepth, boolean white, int maxDepth) {
  ArrayList<Move> legalMoves = generateLegalMoves(board, white);
  Integer hash = hashBoard(board, white);
  if (transTable.containsKey(hash)) {
    return transTable.get(hash);
  }
  if (currentDepth >= maxDepth || legalMoves.isEmpty()) {
    return new MMXMove(evaluationFunction(board));
  }

  MMXMove best = !white ? new MMXMove(MIN_FLOAT) : new MMXMove(MAX_FLOAT);
  for (Move m : legalMoves) {
    int[][] boardCpy = fakeMove(board, m, white);
    MMXMove tmp = minimax(boardCpy, alpha, beta, currentDepth + 1, !white, maxDepth);
    if (!white && tmp.value >= best.value) {//MAX
      best = new MMXMove(m.row, m.col, tmp.value);
      alpha = max(best.value, alpha);
      if (best.value >= abs(beta)) { 
        break;
      }
    } else if (white && tmp.value <= best.value) {//MIN
      best = new MMXMove(m.row, m.col, tmp.value);
      beta = min(best.value, beta);
      if (abs(best.value) <= alpha) { 
        break;
      }
    }
  }
  if (!transTable.containsKey(hash) || abs(transTable.get(hash).value) < abs(best.value)) {
    transTable.put(hash, best);
  }
  return best;
}