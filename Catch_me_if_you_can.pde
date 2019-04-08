import de.voidplus.leapmotion.*;    //import from library
import processing.serial.*;

LeapMotion leap;    //declaring the object

String myString = null;
Serial myPort;

int NUM_OF_VALUES = 3;   /** YOU MUST CHANGE THIS ACCORDING TO YOUR PROJECT **/
int[] sensorValues;  /** this array stores values from Arduino **/

int worldSize = 400; 

//the center of the palm 
float handX;  
float handY;
float handZ;

//handGrab
float hGrab;

float sphX;   
float sphY;
float sphZ;
float sphRad;
color sphColor;

//velocity of the sphere
float velX;    
float velY;
float velZ;

int previousSensorValues;    

void setup () {
  size (600, 600, P3D);  //3D space
  background (255);

  setupSerial();

  leap = new LeapMotion(this);    //initializing the object

  sphX = 0;                       //x, y, z of the center of the circle
  sphY = 0;
  sphZ = 0;
  sphRad = 30;                    //radius of the sphere
  sphColor = color(255, 0, 0);    //color of the sphere
  sphereDetail(30);               //detail of the sphere

  //velocity at random with the range of -3 and 3
  velX=random (-3, 3);
  velY=random (-3, 3);
  velZ=random (-3, 3);
}

// update!
// check the value!
// and then display

void draw () {
  background (255);

  updateSerial();        //serial communication
  printArray(sensorValues);


  leapMotionUpdate();    //call methods of the object

  //center the hand
  float posX = map(handX, 0, width, -200, 200);
  float posY = map(handY, 0, height, -200, 200);
  float posZ = map(handZ, 80, 20, -150, 150);

  //println (hGrab);  //shows the value of 1.0 when I grab the circle

  float distance = dist(sphX, sphY, sphZ, posX, posY, posZ); //distance between sphere and hand
  //println(distance);
  if (distance < sphRad) {
    sphColor = color(0, 255, 0);   // if distance is smaller than radius then the circle turns green
    if (hGrab > 0.8) {  //open hand = 0, closed hand = 1
      sphColor = color(255, 255, 0);  //if you grab the button, then its gonna turn yellow
      sphX = posX;  //position of sphere = position of hand
      sphY = posY;
      sphZ = posZ;
    }
  } else {
    sphColor = color(0, 0, 255);  //color it blue
  }

  //sphere increases velocity on X, Y, and Z
  sphX= sphX+velX;
  sphY= sphY+velY;
  sphZ= sphZ+velZ;

  //X - cannot move outside of side walls
  float area = sphRad + 1;
  if (sphX > (worldSize/2)-area) {
    sphX = worldSize/2-area;
    velX = -velX;
  } else if (sphX<(-worldSize/2)+area) {
    sphX = -worldSize/2+area;
    velX = velX*-1;
  }
  
  //Y - cannot move outside of the ceiling and floor
  if (sphY > (worldSize/2)-area) {
    sphY = worldSize/2-area;
    velY = -velY;
  } else if (sphY<(-worldSize/2)+area) {
    sphY = -worldSize/2+area;
    velY=velY*-1;
  }
  
  //Z - cannot move outside the back and front
  if (sphZ > (worldSize/2)-area) {
    sphZ = worldSize/2-area;
    velZ = -velZ;
  } else if (sphZ<(-worldSize/2)+area) {
    sphZ = -worldSize/2+area;
    velZ = velZ*-1;
  }

  //speed slowly slowing down
  velX *= 0.99;
  velY *= 0.99;
  velZ *= 0.99;

  //translate the world to the middle of the space
  translate(width/2, height/2);   

  // to rotate on x-axis and y-axis
  float rotAngleY = map(sensorValues[0], 261, 762, -PI/4, PI/4);
  float rotAngleX = map(sensorValues[1], 259, 763, PI/4, -PI/4);
  
  //instead of joytick, use mouseX and mouseY to look at the space
  //float rotAngleY = map(mouseX, 0, width, -PI/4, PI/4);
  //float rotAngleX = map(mouseY, 0, height, PI/4, -PI/4);

  //since the values are constantly changing, to prevent the world from moving around by itself
  if (sensorValues[1]>=763) {
    rotAngleX = map (sensorValues[1], 259, 763, 0, 0);
  }
  if ((sensorValues[0]>506)||(sensorValues[0]<499)) {
    rotateY(rotAngleY);
  }
  if ((sensorValues[1]>511)||(sensorValues[1]<499)) {
    rotateX(rotAngleX);
  }

  //world
  noFill();
  noStroke();
  drawBox(0, 0, 0, 400, 400, 400);    

  //side walls
  fill(50);
  noStroke();
  drawBox(200, 0, 0, 2, 400, 400);
  drawBox(-200, 0, 0, 2, 400, 400);

  //background
  fill(155);
  noStroke();
  drawBox(0, 0, -200, 400, 400, 2);  

  //ceiling and floor
  fill(220);
  drawBox(0, 200, 0, 400, 2, 400);
  drawBox(0, -200, 0, 400, 2, 400);

  //sphere that follows the position of hand
  noStroke();    
  fill(0);
  drawSphere (posX, posY, posZ, 10);

  //draw the sphere
  stroke(sphColor);
  noFill();
  drawSphere (sphX, sphY, sphZ, 30);
}

//function to draw multiple spheres
void drawSphere (float x, float y, float z, int size) {
  pushMatrix ();
  translate (x, y, z);
  sphere(size);
  popMatrix();
}

//function to draw multiple boxes
void drawBox(float x, float y, float z, float w, float h, float d) {
  pushMatrix();
  translate(x, y, z); // this way you can change the position of the box
  box(w, h, d); // you can only change the size of the box (w,h,d)
  popMatrix();
}

//if a key on the keyboard is pressed, then the sphere will randomly change velocity
void keyPressed() {
  velX=random (-15, 15);
  velY=random (-15, 15);
  velZ=random (-15, 15);
}

//serial communication
void setupSerial() {
  printArray(Serial.list());
  myPort = new Serial(this, Serial.list()[ 2 ], 9600);
  // WARNING!
  // You will definitely get an error here.
  // Change the PORT_INDEX to 0 and try running it again.
  // And then, check the list of the ports,
  // find the port "/dev/cu.usbmodem----" or "/dev/tty.usbmodem----" 
  // and replace PORT_INDEX above with the index number of the port.

  myPort.clear();
  // Throw out the first reading,
  // in case we started reading in the middle of a string from the sender.
  myString = myPort.readStringUntil( 10 );  // 10 = '\n'  Linefeed in ASCII
  myString = null;

  sensorValues = new int[NUM_OF_VALUES];
}

void updateSerial() {
  while (myPort.available() > 0) {
    myString = myPort.readStringUntil( 10 ); // 10 = '\n'  Linefeed in ASCII
    if (myString != null) {
      String[] serialInArray = split(trim(myString), ",");
      if (serialInArray.length == NUM_OF_VALUES) {
        for (int i=0; i<serialInArray.length; i++) {
          sensorValues[i] = int(serialInArray[i]);
        }
      }
    }
  }
  if (sensorValues[2] == 1) {    //whenever the value=1, the sphere will change velocity
    velX=random (-15, 15);
    velY=random (-15, 15);
    velZ=random (-15, 15);
    sensorValues[2] = previousSensorValues;
  }
  if (previousSensorValues == 1) {    //when the previous value=1, the next value has to equal to 0
    sensorValues[2] = 0;
  }
}