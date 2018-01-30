import java.util.Random;
import java.util.PriorityQueue;
import java.util.Comparator;
import java.util.Map;

int MAX_POINTS = 1000000;
int SPARSITY = 4;  // 1 in X chance of a particular edge existing
int MAPSIZE = 480;

class Pt {
  int name;  // index in graph array
  float x;
  float y;
  
  Pt(int name, float x, float y) {
    this.name = name;
    this.x = x;
    this.y = y;
  }
}

class PtList {
  Pt p;
  PtList next;
  
  PtList(Pt p, PtList next) {
    this.p = p;
    this.next = next;
  }
}

class AStarNode{
  public Pt point;
  public AStarNode parent;
  public float costSoFar;
  public float heuristicCost;
  AStarNode(Pt point, float costSoFar, float heuristicCost){
    this.point = point;
    this.costSoFar = costSoFar;
    this.heuristicCost = heuristicCost;
    this.parent = null;
  }
  
  AStarNode(Pt point, AStarNode parent, float costSoFar, float heuristicCost){
    this.point = point;
    this.costSoFar = costSoFar;
    this.heuristicCost = heuristicCost;
    this.parent = parent;
  }
}

public class AStarNodeComparator implements Comparator<AStarNode>{
  public int compare(AStarNode x, AStarNode y){
    float xVal = x.costSoFar + x.heuristicCost;
    float yVal = y.costSoFar + y.heuristicCost;
    if(xVal < yVal){
      return -1; 
    } else if(xVal > yVal){
      return 1; 
    }
    else{
      return 0; 
    }
  }
  
}


class AStar {
  private AStarNode start;
  private AStarNode goal;
  private PriorityQueue<AStarNode> toLook;
  ArrayList<Pt> seen;
  private final float baseCost = 1.0f;
  private final float diagCost = sqrt(2.0f);
  private HashMap<AStarNode, Float> distances;
  private ArrayList<PtList> path;
  
  AStar(Pt start, Pt goal){
    this.goal = new AStarNode(goal, 0, 0);
    this.start = new AStarNode(start, 0, heuristicHelper(start));
    Comparator<AStarNode> comp = new AStarNodeComparator();
    this.toLook = new PriorityQueue<AStarNode>(1, comp);
    toLook.add(this.start);
    this.distances = new HashMap<AStarNode, Float>();
    this.seen = new ArrayList<Pt>();
    this.path = new ArrayList<PtList>();
    for(int i = 0; i < g.nextOpen; i++){ 
      Pt p = g.pts[i];
      AStarNode toAdd = new AStarNode(p, MAX_FLOAT, MAX_FLOAT);
      if(p.name == start.name){
        this.distances.put(toAdd , 0.0);
      }
      this.distances.put(toAdd, MAX_FLOAT);
    }
    while(toLook.size() > 0){
      AStarNode lowest = toLook.poll(); //<>//
      seen.add(lowest.point);
      if(lowest.point.name == this.goal.point.name){
        while(lowest.parent != null){
          AStarNode parent = lowest.parent; //<>//
          PtList toAdd = new PtList(lowest.point, new PtList(parent.point, null));
          this.path.add(toAdd);
          lowest = parent;
        }
        break;
      }
      if(this.distances.containsKey(lowest) && lowest.costSoFar >= this.distances.get(lowest)){
        continue;
      }
      this.distances.put(lowest, lowest.costSoFar);
      PtList neighbor = g.adjList[lowest.point.name];
      while(neighbor != null){
        if(neighbor.p != null && !seen.contains(neighbor.p)){ //<>//
           AStarNode toAdd = new AStarNode(neighbor.p, lowest, lowest.costSoFar + 1, heuristicHelper(neighbor.p));
           this.toLook.add(toAdd);
        }
        neighbor = neighbor.next;
      }
    }
  }
  
  public ArrayList<PtList> getPath(){
    return this.path;
  }
  
  private float heuristicHelper(Pt point){
    Pt goalPt = this.goal.point;
    float xDist = abs(point.x - goalPt.x);
    float yDist = abs(point.y - goalPt.y);
    return (baseCost * (xDist + yDist) + (diagCost - 2 * baseCost) * min(xDist, yDist));
  }
}

class Graph {
  Pt[] pts;
  PtList[] adjList;  // Look up by "name" (index) of point
  ArrayList<Pt> circlePts;
  ArrayList<PtList> circlePath;
  int nextOpen;  // index of next point in array
  
  Graph() {
    pts = new Pt[MAX_POINTS];
    adjList = new PtList[MAX_POINTS];
    circlePts = new ArrayList<Pt>();
    circlePath = new ArrayList<PtList>();
    nextOpen = 0;
  }
  
  void addPt(float x, float y) {
    Pt newPt = new Pt(nextOpen, x, y);
    pts[nextOpen++] = newPt;
  }
  
  void addCircle(Pt point){
    if(circlePts.size() == 0){
      circlePts.add(point);
    } else if(circlePts.size() == 1){
      circlePts.add(point);
      buildPathBetweenCircles();
    } else {
     circlePts.clear();
     circlePath.clear();
     circlePts.add(point);
    }
  }
  
  Pt getClosestPoint(int x, int y){
    int sclX = round(x/10) * 10;
    int sclY = round(y/10) * 10;
    Pt toRet = null;
    for(Pt p : pts){
      if(p.x == sclX && p.y == sclY){
        toRet = p;
        break;
      }
    }
    return toRet;
  }
 
  
  void buildPathBetweenCircles(){
    Pt start = this.circlePts.get(0);
    Pt goal = this.circlePts.get(1);
    AStar pathBuilder = new AStar(start, goal);
    this.circlePath = pathBuilder.getPath();
  }
  
  // assume edges are undirected
  void addEdge(int name1, int name2) {
    // Push onto existing list
    PtList newEntry = new PtList(pts[name2], adjList[name1]);
    adjList[name1] = newEntry;
    // And for the other direction, because undirected
    PtList newEntry2 = new PtList(pts[name1], adjList[name2]);
    adjList[name2] = newEntry2;
  }
  
  void draw() {
    stroke(255,0,0);
    for (int i = 0; i < nextOpen; i++) {
      point(pts[i].x, pts[i].y);
    }
    // We will draw each edge twice because it's undirected
    // and that is fine
    stroke(0,0,0);
    for (int i = 0; i < nextOpen; i++) {
      PtList edge = adjList[i];
      while(edge != null) {
        line(pts[i].x, pts[i].y, edge.p.x, edge.p.y);
        edge = edge.next;
      }
    }
    stroke(0, 255, 0);
    for(PtList edge : circlePath){
      if(edge != null && edge.next != null){
        line(edge.p.x, edge.p.y, edge.next.p.x, edge.next.p.y);
      }
    }
    fill(255);
    noStroke();
    for(Pt p : circlePts){
      ellipse(p.x, p.y, 10, 10);
    }
  }
    
}

Graph g;

void settings() {
  size(MAPSIZE, MAPSIZE);
}

void setup() {
  Random prng = new Random(1337);  // deterministic so we can all work with same graph
  g = new Graph();
  for (int i = 0; i < MAPSIZE/10; i++) {
    for (int j = 0; j < MAPSIZE/10; j++) {
      int ptNum = g.nextOpen;
      g.addPt(j*10,i*10);
      // Each of the following maybe's is deterministic for ease of grading
      // Maybe add edge up
      if (i > 0 && prng.nextInt(SPARSITY) == 0) {
        g.addEdge(ptNum, ptNum - MAPSIZE/10);
      }
      // Maybe add edge left
      if (j > 0 && prng.nextInt(SPARSITY) == 0) {
        g.addEdge(ptNum, ptNum - 1);
      }
      
      // Maybe add edge up and left
      if (i > 0 && j > 0 && prng.nextInt(SPARSITY) == 0) {
        g.addEdge(ptNum, ptNum - MAPSIZE/10 - 1);
      }
      // Maybe add edge up and right
      if (i > 0 && j < MAPSIZE/10 - 1 && prng.nextInt(SPARSITY) == 0) {
        g.addEdge(ptNum, ptNum - MAPSIZE/10 + 1);
      }
    }
  }
}

void mouseReleased(){
  Pt pnt = g.getClosestPoint(mouseX, mouseY);
  if(pnt != null){
    g.addCircle(pnt); 
  }
}

void draw() {
  background(150,150,150);
  stroke(0,0,0);
  g.draw();
}