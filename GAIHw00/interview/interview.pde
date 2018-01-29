import java.util.Map;

int tbX = 10;
int tbY = 560;
int tbW = 1180;
int tbH = 190;

int optH = 50;
int textSpacer = 5;

String endOpts1 = "\"Nooooo!!!!\" The Bridgekeeper screams as he is launched into the abyss!\nYou succeeded in safely crossing the bridge.";
Float endOptsF1 = -1.0f;
String endOpts2 = "The Bridgekeeper cackles gleefully as you are hurled into the chasm!\nYou Failed.";
Float endOptsF2 = 0.0f;
HashMap<Float, String> endOpts = new HashMap<Float, String>();
BinaryMoodDialogueFrame endFrame;

String thirdOpts1 = "\"You've done well so far traveller. Only one before you has reached the third question, he was formidable.\"\n" + 
                    "\"But ... I don't think you'll be able to answer my final question. Even he couldn't.\"\n" + 
                    "\"What do I have in my pocket?\"";
Float thirdOptsF1 = -1.0f;
String thirdOpts2 = "\"You are DOOOOOOOOOOOMMMED! Now...\"\n" + 
                    "\"For the Final Question!\"\n\"What do I have in my pocket?\"";
Float thirdOptsF2 = 0.0f;
HashMap<Float, String> thirdOpts = new HashMap<Float, String>();
BinaryMoodDialogueFrame thirdQuestion;

String secondOpts1 = "The Bridgekeeper inhales sharply. \"You had one lucky guess but luck won't save you again.\"\n" + 
                     "\"Now for your second test.\"\n" + 
                     "\"How many marbles are in this jar?\"";
Float secondOptsF1 = -1.0f;
String secondOpts2 = "\"HAHA wrong answer foolish mortal! you are going to FAIL!\"\n\"Second Question!\"\n" + 
                     "\"How many marbles are in this jar?\"";
Float secondOptsF2 = 0.0f;
HashMap<Float, String> secondOpts = new HashMap<Float, String>();
BinaryMoodDialogueFrame secondQuestion;

String firstOpts1 = "\"Greetings traveller. If you wish to cross this bridge you must answer me these questions 3\"\n" +
                    "\"First Question!\"\n" + 
                    "\"What should never go on Pizza?\"";
Float firstOptsF1 = -1.0f;
HashMap<Float, String> firstOpts = new HashMap<Float, String>();
BinaryMoodDialogueFrame firstQuestion;

BinaryMoodDialogueTree dialogue;

int rspStartY = 690;
int rspEndY = 790;

PImage bridge;

void setup() {
  size(1200, 800);
  textSize(18);
  bridge = loadImage("bridge.jpg");
  endOpts.put(endOptsF1, endOpts1);
  endOpts.put(endOptsF2, endOpts2);
  Response[] empty = new Response[0];
  endFrame = new BinaryMoodDialogueFrame(endOpts, empty);
  
  thirdOpts.put(thirdOptsF1, thirdOpts1);
  thirdOpts.put(endOptsF2, thirdOpts2);
  Response thirdResponse1 = new Response(endFrame, -0.33, "Your Precious");
  Response thirdResponse2 = new Response(endFrame, 0.33, "Nothing");
  Response[] thirdResponses = { thirdResponse1, thirdResponse2 };
  thirdQuestion = new BinaryMoodDialogueFrame(thirdOpts, thirdResponses);
  
  secondOpts.put(secondOptsF1, secondOpts1);
  secondOpts.put(secondOptsF2, secondOpts2);
  Response secondResponse1 = new Response(thirdQuestion, -0.33, "What Jar?");
  Response secondResponse2 = new Response(thirdQuestion, 0.33, "42");
  Response[] secondResponses = { secondResponse1, secondResponse2 };
  secondQuestion = new BinaryMoodDialogueFrame(secondOpts, secondResponses);
  
  firstOpts.put(firstOptsF1, firstOpts1);
  Response firstResponse1 = new Response(secondQuestion, -0.33, "Fruits that aren't tomatoes");
  Response firstResponse2 = new Response(secondQuestion, 0.33, "Anything Green");
  Response[] firstResponses = { firstResponse1, firstResponse2 };
  firstQuestion = new BinaryMoodDialogueFrame(firstOpts, firstResponses);
  
  dialogue = new BinaryMoodDialogueTree(firstQuestion);
}

void checkButton(int mx, int my, int buttonY, Response response) {
  response.isLit = false;
  response.fillColor = 0;
  if ((mx >= tbX && mx <= (tbX + tbW)) && (my > buttonY && my <= buttonY + optH)) { 
     response.isLit = true;
     response.fillColor = 15;
  }
}

void checkMousePos(int mx, int my, int numRsps, Response[] responses) {
  for(int i = 0; i < numRsps; i++){
    checkButton(mx, my, (rspStartY + (optH * i)), responses[i]);
  }
}

void draw() {
  Response[] responses = dialogue.getCurResponses();
  int numRsps = responses.length;
  checkMousePos(mouseX, mouseY, numRsps, responses);
  background(bridge);
  
  //NPC Dialogue Box
  fill(0);
  rect(tbX, tbY, tbW, tbH, PI);
  //Response  Box
  for(int i = 0; i < numRsps; i++) {
    fill(responses[i].fillColor);
    rect(tbX, (rspStartY + (50 * i)), tbW, optH, PI);
  }

  //NPC Dialogue text
  fill(255);
  text(dialogue.getText(), tbX + textSpacer, tbY + textSpacer, tbW - (2 * textSpacer), tbH - (2 * textSpacer));
  
  for(int i = 0; i < numRsps; i++) {
    text(responses[i].text, tbX + textSpacer, (rspStartY + (50 * i)) + textSpacer, tbW - (2* textSpacer), optH - (2 * textSpacer));
  }
}

void mouseReleased() {
  Response[] responses = dialogue.getCurResponses();
  for(Response r : responses){
    if(r.isLit){
       dialogue.nextFrame(r);
       break;
    }
  }
}

class BinaryMoodDialogueTree {
  private float mood;
  private BinaryMoodDialogueFrame curFrame;
  private BinaryMoodDialogueFrame startFrame;
  //private String[] curResponseList;
  private String curDispTxt;
  BinaryMoodDialogueTree(BinaryMoodDialogueFrame firstFrame) {
    mood = 0.0f;
    startFrame = firstFrame;
    curFrame = startFrame;
    //listResponseText();
    detDisplayText();
  }
 
  
  private void detDisplayText(){
    Float[] tmp = curFrame.getTextOptions().keySet().toArray(new Float[curFrame.getTextOptions().keySet().size()]);
    float curHighestThresh = -1.0f;
    for(Float f : tmp){
      if(f >= curHighestThresh && mood >= f) { curHighestThresh = f; }
    }
    curDispTxt = curFrame.getTextOptions().get(curHighestThresh);
  }
  
  public void nextFrame(Response r){
    mood += r.impact;
    curFrame = r.next;
    detDisplayText();
  }
  
  public void responseHover(String rspTxt){
    Response[] responses = getCurResponses();
    for(Response r : responses){
      r.isLit = false;
      r.fillColor = 0;
      if(r.text.equals(rspTxt)){
        r.isLit = true;
        r.fillColor = 15;
      }
    }
  }
  
  public Response[] getCurResponses(){
    return curFrame.getResponses(); 
  }

  public String getText(){
    return curDispTxt; 
  }

  public Response[] getCurResponse() {
    return curFrame.getResponses();
  }

  public float getMood() {
    return mood;
  }
  
  
}

public class BinaryMoodDialogueFrame {
  //Map of all possible NPC dialogue options for this frame
  //Maps Mood threshold to corresponding
  private HashMap<Float, String> textOptions;
  //Map of player's possible responses to their  next frame and the impact on NPC mood.
  private Response[] responses;

  private boolean endFrame;

  public BinaryMoodDialogueFrame() {
    textOptions = new HashMap<Float, String>();
    responses = new Response[0];
    endFrame = true;
  }

  public BinaryMoodDialogueFrame(HashMap<Float, String> txtOpts, Response[] rspMap) {
    textOptions = txtOpts;
    responses = rspMap;
    endFrame = !(textOptions.size() > 0 && responses.length > 0);
  }

  public Response[] getResponses() {
    return responses;
  }

  public HashMap<Float, String> getTextOptions() {
    return textOptions;
  }

  public boolean isEndFrame() {
    return endFrame;
  }
}

public class Response {
  public final BinaryMoodDialogueFrame next;
  public final float impact;
  public final String text;
  public boolean isLit = false;
  public int fillColor = 0;
  public Response(BinaryMoodDialogueFrame next, float impact, String text){
    this.next = next;
    this.impact = impact;
    this.text = text;
  }
}