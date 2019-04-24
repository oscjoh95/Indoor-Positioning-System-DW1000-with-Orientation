//Pin Numbers
#define S1_A        12
#define S2_A        2
#define S1_B        11
#define S2_B        19
#define PWM_A       3
#define DIR_A0      4
#define DIR_A1      5
#define PWM_B       6
#define DIR_B0      7
#define DIR_B1      8

#define LED1        22
#define LED2        24
#define LED3        26
#define BUTTON1     28
#define BUTTON2     30
#define BUTTON3     32
#define RUN_BUTTON  34

//Movement constants
#define BACKWARD  0
#define FORWARD   1
#define SPIN_CW  2
#define SPIN_CCW   3


#define SLOW        100 //~80 % duty cycle  5.76 V
#define MEDIUM      180 //~90 % duty cycle  6.49 V
#define FAST        255 //~100 % duty cycle 7.20 V

//Other Constants
#define ROBOT_WIDTH   19  //In cm
#define TURNING_COEFF 1.955
#define DRIVING_COEFF 1.09

int newReadingA = 0;
int oldReadingA;
int newReadingB = 0;
int oldReadingB;
int QEM[16] = {0,-1,1,0,1,0,0,-1,-1,0,0,1,0,1,-1,0};
int dirA = 0;
int dirB = 0;
double distanceA = 0;
double distanceB = 0;
volatile unsigned long counterA;
volatile unsigned long counterB;
int program  = 1;
boolean runProgram = false;

void setup() {
  //Setup serial communication
  Serial.begin(115200);

  //Setup pin modes
  pinMode(S1_A, INPUT);
  pinMode(S2_A, INPUT);
  pinMode(S1_B, INPUT);
  pinMode(S2_B, INPUT);
  pinMode(PWM_A, OUTPUT);
  pinMode(DIR_A0, OUTPUT);
  pinMode(DIR_A1, OUTPUT);
  pinMode(PWM_B, OUTPUT);
  pinMode(DIR_B0, OUTPUT);
  pinMode(DIR_B1, OUTPUT);

  pinMode(LED1, OUTPUT);
  pinMode(LED2, OUTPUT);
  pinMode(LED3, OUTPUT);
  pinMode(BUTTON1, INPUT_PULLUP);
  pinMode(BUTTON2, INPUT_PULLUP);
  pinMode(BUTTON3, INPUT_PULLUP);
  pinMode(RUN_BUTTON, INPUT_PULLUP);

  digitalWrite(LED1, HIGH);
  digitalWrite(LED2, LOW);
  digitalWrite(LED3, LOW);

  
  //Setup interrupts for counting pulses
  attachInterrupt(digitalPinToInterrupt(S2_A), countPulsesA, RISING);
  attachInterrupt(digitalPinToInterrupt(S2_B), countPulsesB, RISING);
}


void loop() {
  if(digitalRead(BUTTON1) == LOW){
    program = 1;
    digitalWrite(LED1, HIGH);
    digitalWrite(LED2, LOW);
    digitalWrite(LED3, LOW);
    while(digitalRead(BUTTON1) == LOW){  
    }
  }
  else if(digitalRead(BUTTON2) == LOW){
    program = 2;
    digitalWrite(LED1, LOW);
    digitalWrite(LED2, HIGH);
    digitalWrite(LED3, LOW);
    while(digitalRead(BUTTON2) == LOW){
    }
  }
  else if(digitalRead(BUTTON3) == LOW){
    program = 3;
    digitalWrite(LED1, LOW);
    digitalWrite(LED2, LOW);
    digitalWrite(LED3, HIGH);
    while(digitalRead(BUTTON3) == LOW){
    }
  }
  else if(digitalRead(RUN_BUTTON) == LOW){
    while(digitalRead(RUN_BUTTON) == LOW){
    }
    delay(1000);
    switch(program){
      case 1:
        //Program path 1 here
        Serial.println("Running Path 1");
        spin(4*PI, SPIN_CCW);
        break;
      case 2:
        //Program path 2 here
        Serial.println("Running Path 2");
        drive(300, FORWARD);
        break;
      case 3:
        //Program path 3 here
        Serial.println("Running Path 3");
        drive(300, FORWARD);
        delay(50);
        spin(PI/2, SPIN_CW);
        delay(50);
        drive(300, FORWARD);
        delay(50);
        spin(PI/2, SPIN_CW);
        delay(50);
        drive(300, FORWARD);
        break;
      default:
        Serial.println("Error: Invalid program");
    }
  }
  /*
  Example:
  drive(100, FORWARD);
  delay(1000);
  spin(PI/2, SPIN_CCW);
  delay(1000);
  spin(PI/2, SPIN_CW)
  delay(1000);
  drive(100, BACKWARD);
  */
}

//Moves the robot a given distance in cm backwards or forwards
void drive(double distance, int moveDirection){
  if(distance > 0){
    counterA = 0;
    distance = distance*DRIVING_COEFF;
    motorsOn(moveDirection, SLOW); //Turn on motors
    while(getPositionA() < distance){
      //Do nothing until distance has been travelled
    }
    motorsOff(); //Turn off motors
  }else{
    Serial.println("Error: The distance to move has to be larger than zero");  
    return;
  }
}

//Spins the robot a given amount of radians clockwise or counterclockwise
void spin(double theta, int spinDirection){
  if(theta > 0){
    double endDistance = radiansToDistance(theta);
    counterA = 0;
    motorsOn(spinDirection, SLOW); //Turn on motors
    while(getPositionA() < endDistance){
      //Do nothing until spin has finished
    }
    motorsOff();
  }else{
    Serial.println("Error: Radians to spin has to be larger than zero");
    return;
  }
}

//Function to start the motors to go in a given direction with speed pwmSpeed
void motorsOn(int movement, int pwmSpeed){
  switch(movement){
    case BACKWARD:
      digitalWrite(DIR_A0, HIGH);
      digitalWrite(DIR_A1, LOW);
      digitalWrite(DIR_B0, LOW);
      digitalWrite(DIR_B1, HIGH);
  
      analogWrite(PWM_A, pwmSpeed);
      analogWrite(PWM_B, pwmSpeed);
      break;
    case FORWARD:
      digitalWrite(DIR_A0, LOW);
      digitalWrite(DIR_A1, HIGH);
      digitalWrite(DIR_B0, HIGH);
      digitalWrite(DIR_B1, LOW);
  
      analogWrite(PWM_A, pwmSpeed);
      analogWrite(PWM_B, pwmSpeed);
      break;
    case SPIN_CCW:
      digitalWrite(DIR_A0, LOW);
      digitalWrite(DIR_A1, HIGH);
      digitalWrite(DIR_B0, LOW);
      digitalWrite(DIR_B1, HIGH);
  
      analogWrite(PWM_A, pwmSpeed);
      analogWrite(PWM_B, pwmSpeed);
      break;
    case SPIN_CW:
      digitalWrite(DIR_A0, HIGH);
      digitalWrite(DIR_A1, LOW);
      digitalWrite(DIR_B0, HIGH);
      digitalWrite(DIR_B1, LOW);
  
      analogWrite(PWM_A, pwmSpeed);
      analogWrite(PWM_B, pwmSpeed);
      break;
    default:
      Serial.println("Error: Invalid movement supplied when turning on motors");
  }
}

//Function to break for 10 ms and then stop
void motorsOff(){
  //Break
  analogWrite(PWM_A, LOW);
  analogWrite(PWM_B, LOW);
  delay(100);
   
  //Turn off
  digitalWrite(DIR_A0, LOW);
  digitalWrite(DIR_A1, LOW);
  digitalWrite(DIR_B0, LOW);
  digitalWrite(DIR_B1, LOW);
  
  analogWrite(PWM_A, HIGH);
  analogWrite(PWM_B, HIGH);
}

/*Unused as of now
//Direction
int getDirectionA(){
  oldReadingA = newReadingA;
  newReadingA = digitalRead(S1_A) * 2 + digitalRead (S2_A);
  if(QEM[oldReadingA*4 + newReadingA] != 0){
    dirA = QEM[oldReadingA*4 + newReadingA];
  }
}
int getDirectionB(){
  oldReadingB = newReadingB;
  newReadingB = digitalRead(S1_B) * 2 + digitalRead (S2_B);
  if(QEM[oldReadingB*4 + newReadingB] != 0){
    dirB = QEM[oldReadingB*4 + newReadingB];
  }
}
*/

//Position
double getPositionA(){
  return counterA * 6.3*PI*3.0/250.0;//Circumference of wheel is 6.3*pi cm and 3/250 pulses per wheel rotation
}
double getPositionB(){
  return counterB * 6.3*PI*3.0/250.0;//Circumference of wheel is 6.3*pi cm and 3/250 pulses per wheel rotation
}

//Convert spin in radians to distance 
double radiansToDistance(double rotation){
  return rotation/2*ROBOT_WIDTH*TURNING_COEFF;
}

//Interrupt functions
void countPulsesA(){
  counterA++;
}
void countPulsesB(){
  counterB++;
}
