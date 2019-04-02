//Pin Numbers
#define S1_A 12
#define S2_A 18
#define S1_B 11
#define S2_B 19
#define PWM_A  3
#define DIR_A0 4
#define DIR_A1 5
#define PWM_B  6
#define DIR_B0 7
#define DIR_B1 8

//Movement constants
#define FORWARD   0
#define BACKWARD  1
#define SPIN_CW   2
#define SPIN_CCW  3

//Other Sonstants
#define SPEED
#define TURNING_SPEED         //TODO: Add reasonable numbers here

int newReadingA = 0;
int oldReadingA;
int newReadingB = 0;
int oldReadingB;
int QEM[16] = {0,-1,1,0,1,0,0,-1,-1,0,0,1,0,1,-1,0};
int dirA = 0;
int dirB = 0;
double distanceA = 0;
double distanceB = 0;
unsigned long counterA;
unsigned long counterB;

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

  //Setup interrupts for counting pulses
  attachInterrupt(digitalPinToInterrupt(S2_A), countPulsesA, RISING);
  attachInterrupt(digitalPinToInterrupt(S2_B), countPulsesB, RISING);
}


void loop() {
  //Program path here
}

//Moves the robot forward a given distance
void moveForward(double distance){
  if(distance > 0){
    counterA = 0;
    motorsOn(FORWARD, SPEED); //Turn on motors
    while(getPositionA() < distance){
      //Do nothing until distance has been travelled
    }
    motorsOff(); //Turn off motors
  }else{
    Serial.println("Error: The distance to move forward has to be larger than zero");  
    return;
  }
}

//Moves the robot backward a given distance
void moveBackward(double distance){
  if(distance > 0){
    counterA = 0;
    motorsOn(BACKWARD, SPEED); //Turn on motors
    while(getPositionA() < distance){
      //Do nothing until distance has been travelled
    }
    motorsOff(); //Turn off motors
  }else{
    Serial.println("Error: The distance to move backward has to be larger than zero");  
    return;
  }  
}

//TODO: Add code to turn a set amount of degrees

//Function to start the motors to go in a given direction with speed pwmSpeed
void motorsOn(int movement, int pwmSpeed){
  switch(movement){
    case FORWARD:
      digitalWrite(DIR_A0, HIGH);
      digitalWrite(DIR_A1, LOW);
      digitalWrite(DIR_B0, LOW);
      digitalWrite(DIR_B1, HIGH);
  
      analogWrite(PWM_A, pwmSpeed);
      analogWrite(PWM_B, pwmSpeed);
      break;
    case BACKWARD:
      digitalWrite(DIR_A0, LOW);
      digitalWrite(DIR_A1, HIGH);
      digitalWrite(DIR_B0, HIGH);
      digitalWrite(DIR_B1, LOW);
  
      analogWrite(PWM_A, pwmSpeed);
      analogWrite(PWM_B, pwmSpeed);
      break;
    case SPIN_CW:
      digitalWrite(DIR_A0, LOW);
      digitalWrite(DIR_A1, HIGH);
      digitalWrite(DIR_B0, LOW);
      digitalWrite(DIR_B1, HIGH);
  
      analogWrite(PWM_A, pwmSpeed);
      analogWrite(PWM_B, pwmSpeed);
      break;
    case SPIN_CCW:
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

//Function to break the motors for 10 ms and then stop
void motorsOff(){
  //Break
  analogWrite(PWM_A, LOW);
  analogWrite(PWM_B, LOW);
  delay(10);
  
  //Turn off
  digitalWrite(DIR_A0, LOW);
  digitalWrite(DIR_A1, LOW);
  digitalWrite(DIR_B0, LOW);
  digitalWrite(DIR_B1, LOW);
  
  analogWrite(PWM_A, HIGH);
  analogWrite(PWM_B, HIGH);
}

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

//Position
double getPositionA(){
  return counterA * 6.3*PI*3.0/250.0;//Circumference of wheel is 6.3*pi cm and 3/250 pulses per wheel rotation
}
double getPositionB(){
  return counterB * 6.3*PI*3.0/250.0;//Circumference of wheel is 6.3*pi cm and 3/250 pulses per wheel rotation
}

//Interrupt functions
void countPulsesA(){
  counterA++;
}
void countPulsesB(){
  counterB++;
}
