
void setup() {
  size(600, 600);
  frameRate(30);
}
int i = 10;
void draw() {
  background(0);
  triangle(400 - i, 100, 400 - i, 50, 450 - i, 75);
  rect(500, 50, 50, 50);
  i += 10;
}