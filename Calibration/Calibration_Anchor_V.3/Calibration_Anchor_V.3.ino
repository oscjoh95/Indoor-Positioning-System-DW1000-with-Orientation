
#include <SPI.h>
#include <DW1000.h>
#include <EEPROM.h>

//Number of measurements used
#define CALI_LENGTH_MEAN 300 // Mean
#define CALI_LENGTH_STD 300  // Standard Deviation

#define DATA_LENGTH 17
#define DEVICE_ID 255

#define POLL 0      //Message types
#define POLL_ACK 1
#define RANGE_REPORT 3
#define FINAL 5
#define FINAL_ACK 6

#define EEPROM_ANTENNA_DELAY_OFFSET 2 //EEPROM adress for Antenna delay offset
#define EEPROM_DEVICE_ID 1

// connection pins
const uint8_t PIN_RST = 9; // reset pin
const uint8_t PIN_IRQ = 2; // irq pin
const uint8_t PIN_SS = SS; // spi select pin

volatile byte expectedMsgId = POLL;
volatile byte recMsgId;   //Received message ID
volatile byte recDevId;   //Received Device ID
volatile byte sentMsgId;  //Sent Message ID

//Calibration of antenna
uint32_t ANTENNA_DELAY = 16450;//Delay to calibrate antenna. Typ. 16470

//Received Interrupts
volatile boolean sentAck = false;
volatile boolean recAck = false;

// Timestamps for range calculations
DW1000Time tsSentPoll;
DW1000Time tsReceivedPoll;
DW1000Time tsSentPollAck;
DW1000Time tsReceivedPollAck;
DW1000Time tsSentFinal;
DW1000Time tsReceivedFinal;

DW1000Time computedTof; // Time of Flight to be computed


byte data[DATA_LENGTH];     //Data to Send
byte recData[DATA_LENGTH];  //Received Data

//byte calibrationMeasurements[CALI_LENGTH*2];     //Range Measurements to Calibrate

uint32_t lastActivity;        //Last noted activity
uint32_t resetPeriod = 1000;  //Watchdog Reset Timer
uint16_t delayTimeUS = 3000;  //Delay to transmit on tsSentFinalAck

uint16_t calibrationCounter = 0;  //Counter
uint16_t newAntennaDelay = 0;
uint8_t deviceID = DEVICE_ID;

float averageRange = 0;
float rangeInM = 0;
float sum = 0;
float stdRange = 0;

DW1000Time delayTransmit = DW1000Time(delayTimeUS, DW1000Time::MICROSECONDS);

void setup() {
    Serial.begin(115200);//Baud Rate
    Serial.println(F("Anchor Starting..."));
    
    deviceID = EEPROM.read(EEPROM_DEVICE_ID);
    Serial.print("Anchor ID: ");Serial.println(deviceID);
    /*
    if(deviceID == 0){
        newAntennaDelay = 213;
        EEPROM.write(EEPROM_ANTENNA_DELAY_OFFSET,(uint8_t)newAntennaDelay);
    } else if(deviceID == 1){
        newAntennaDelay = 126;
        EEPROM.write(EEPROM_ANTENNA_DELAY_OFFSET,(uint8_t)newAntennaDelay);
    } else if(deviceID == 2){
        newAntennaDelay = 68;
        EEPROM.write(EEPROM_ANTENNA_DELAY_OFFSET,(uint8_t)newAntennaDelay);
    }
    //Use calibrated ANTENNA DELAY values
    
    ANTENNA_DELAY += EEPROM.read(EEPROM_ANTENNA_DELAY_OFFSET);
    */
    Serial.println(ANTENNA_DELAY);
    

    //Setup Output Pins Arduino Pro Mini
    DW1000.begin(PIN_IRQ, PIN_RST);
    DW1000.select(PIN_SS);

    //Setup DW1000 Chip
    DW1000.newConfiguration();
    DW1000.setDefaults();
    DW1000.setDeviceAddress(2);
    DW1000.setNetworkId(10);
    DW1000.enableMode(DW1000.MODE_SHORTDATA_FAST_ACCURACY);
    DW1000.commitConfiguration();    
    DW1000.setAntennaDelay(ANTENNA_DELAY);
    char msg[128];
    DW1000.getPrintableDeviceIdentifier(msg);
    Serial.print("Device ID: "); Serial.println(msg);
    DW1000.getPrintableExtendedUniqueIdentifier(msg);
    Serial.print("Unique ID: "); Serial.println(msg);
    DW1000.getPrintableNetworkIdAndShortAddress(msg);
    Serial.print("Network ID & Device Address: "); Serial.println(msg);
    DW1000.getPrintableDeviceMode(msg);
    Serial.print("Device mode: "); Serial.println(msg);
    
    calibrationCounter = 0; 
    averageRange = 0;
    
    //Attach Interrupt Handlers
    DW1000.attachSentHandler(handleSent);
    DW1000.attachReceivedHandler(handleReceived);
    delay(1000);
    receiver();
    Serial.println(F("Anchor Initialized: Waiting for poll..."));
    noteActivity();
}

void receiver() {
    DW1000.newReceive();
    DW1000.setDefaults();
    DW1000.receivePermanently(true); //After Transmit enter RX_Mode
    DW1000.startReceive();
}

void transmitPollAck() {
    DW1000.newTransmit();
    DW1000.setDefaults();
    data[0] = POLL_ACK;
    data[17] = DEVICE_ID;
    //DW1000Time randomDelayTransmit = DW1000Time(random(3000,7000), DW1000Time::MICROSECONDS);
    //tsSentPollAck = DW1000.setDelay(randomDelayTransmit);
    DW1000.setData(data, DATA_LENGTH);
    DW1000.startTransmit();
    sentMsgId = POLL_ACK;
}

void transmitRangeReport() {
    DW1000.newTransmit();
    DW1000.setDefaults();
    data[0] = RANGE_REPORT;
    data[17] = DEVICE_ID;
    DW1000.setDelay(delayTransmit);
    computedTof.getTimestamp(data + 1);
    DW1000.setData(data, DATA_LENGTH);
    DW1000.startTransmit();
    sentMsgId = RANGE_REPORT;
}

//Handles sent interrupts
void handleSent() {
    sentAck = true;
}

//Handles receive interrupts
void handleReceived() {
    recAck=true;
}

//Update Watchdog Timer
void noteActivity() {
    lastActivity = millis();
}
 
// Reset to Original State
void resetInactive() {
    expectedMsgId = POLL;
    receiver();
    noteActivity();  
}

void computeRangeAssymetric() {
       DW1000Time round1 = (tsReceivedPollAck - tsSentPoll).wrap();
       DW1000Time reply1 = (tsSentPollAck - tsReceivedPoll).wrap();
       DW1000Time round2 = (tsReceivedFinal - tsSentPollAck).wrap();
       DW1000Time reply2 = (tsSentFinal - tsReceivedPollAck).wrap();
       
       DW1000Time assymetricTime = ((round1 * round2) - (reply1 * reply2)) / (round1 + round2 + reply1 + reply2);
       computedTof.setTimestamp(assymetricTime);
       Serial.print("Range: "); Serial.println(computedTof.getAsMeters());
}

void loop() { 
    // Watchdog Timer if nothing is received
    if (!sentAck && !recAck) { 
        // check if inactive
        if (millis() - lastActivity > resetPeriod) {
            resetInactive();
        }
    return;
    }

    //Received Package
    if(recAck){
        recAck=false;
        DW1000.getData(recData, DATA_LENGTH);
        recMsgId = recData[0];
        recDevId = recData[16];
        if((recMsgId == expectedMsgId)){
            if(recMsgId == POLL){     //Received POLL
                DW1000.getReceiveTimestamp(tsReceivedPoll);
                tsSentPoll.setTimestamp(recData+1);
                transmitPollAck();
            }else if(recMsgId == FINAL){                    //Received FINAL
                Serial.print("RX power is [dBm] ... "); Serial.println(DW1000.getReceivePower());
                DW1000.getReceiveTimestamp(tsReceivedFinal); //Fetch timestamps
                tsReceivedPollAck.setTimestamp(recData+6);
                tsSentFinal.setTimestamp(recData+11);
                computeRangeAssymetric();
                rangeInM = computedTof.getAsMeters(); //Convert Timestamp to Range

                //Calculate Mean
                if(calibrationCounter<=(CALI_LENGTH_MEAN)){
                    if(calibrationCounter==CALI_LENGTH_MEAN){
                        averageRange = sum/CALI_LENGTH_MEAN;                        
                    }
                    else{
                      sum += rangeInM;
                    }
                }

                //Calculate a STD using averageRange as Mean
                else if(calibrationCounter > (CALI_LENGTH_MEAN) && calibrationCounter <= (CALI_LENGTH_MEAN+CALI_LENGTH_STD)){
                    if(calibrationCounter == (CALI_LENGTH_MEAN+CALI_LENGTH_STD)){
                        stdRange = sqrt(stdRange/CALI_LENGTH_STD);
                    }
                    else{
                        stdRange += pow(rangeInM-averageRange,2);
                    }
                }
                calibrationCounter++;
                Serial.print("Measurements: "); Serial.println(calibrationCounter);
                Serial.print("Avg. Range in M: "); Serial.println(averageRange);
                Serial.print("STD Range in M: "); Serial.println(stdRange);
                transmitRangeReport(); //Not necessary
                
                
            }
            noteActivity();           //Update Watchdog
        }
    }

    //Sent Package
    if(sentAck){
        sentAck=false;
        if(sentMsgId == POLL_ACK){
            expectedMsgId = FINAL;
            DW1000.getTransmitTimestamp(tsSentPollAck);
        }
        else if(sentMsgId == RANGE_REPORT){
            expectedMsgId = POLL;  //Go back to original state 
            DW1000.setAntennaDelay(ANTENNA_DELAY);      
        }
    }
}
