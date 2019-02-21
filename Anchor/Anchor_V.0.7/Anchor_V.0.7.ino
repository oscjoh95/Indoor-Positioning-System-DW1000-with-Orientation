
#include <SPI.h>
#include <DW1000.h>
#include <EEPROM.h>

#define DATA_LENGTH 17
#define DEVICE_ID 0

#define POLL 0
#define POLL_ACK 1
#define RANGE_REPORT 3
#define FINAL 5
#define FINAL_ACK 6

// connection pins
const uint8_t PIN_RST = 9; // reset pin
const uint8_t PIN_IRQ = 2; // irq pin
const uint8_t PIN_SS = SS; // spi select pin

volatile byte expectedMsgId = POLL;
volatile byte recMsgId;   //Received message ID
volatile byte recDevId;   //Received Device ID
volatile byte sentMsgId;  //Sent Message ID

//Calibration of antenna
const uint32_t ANTENNA_DELAY = 16470;//Delay to calibrate antenna. Typ. 16470

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

DW1000Time computedTof;


byte data[DATA_LENGTH];     //Data to Send
byte recData[DATA_LENGTH];  //Received Data

uint32_t lastActivity;        //Last noted activity
uint32_t resetPeriod = 1000;  //Watchdog Reset Timer
uint16_t delayTimeUS = 7000;  //Delay to transmit on tsSentFinalAck
uint8_t deviceID = DEVICE_ID;

DW1000Time delayTransmit = DW1000Time(delayTimeUS, DW1000Time::MICROSECONDS);

void setup() {
    Serial.begin(115200);//Baud Rate
    Serial.println(F("Anchor Starting..."));

    //EEPROM.write(1,2); //Store Device ID in EEPROM: Comment after Device ID is stored
    deviceID = EEPROM.read(1);
    Serial.print("Anchor ID: ");Serial.println(deviceID);
    
    //Setup Output Pins Arduino Pro Mini
    DW1000.begin(PIN_IRQ, PIN_RST);
    DW1000.select(PIN_SS);

    //Setup DW1000 Chip
    DW1000.newConfiguration();
    DW1000.setDefaults();
    DW1000.setDeviceAddress(2);
    DW1000.setNetworkId(10);
    DW1000.enableMode(DW1000.MODE_LONGDATA_RANGE_ACCURACY);
    DW1000.setAntennaDelay(ANTENNA_DELAY);
    DW1000.commitConfiguration();
    char msg[128];
    DW1000.getPrintableDeviceIdentifier(msg);
    Serial.print("Device ID: "); Serial.println(msg);
    DW1000.getPrintableExtendedUniqueIdentifier(msg);
    Serial.print("Unique ID: "); Serial.println(msg);
    DW1000.getPrintableNetworkIdAndShortAddress(msg);
    Serial.print("Network ID & Device Address: "); Serial.println(msg);
    DW1000.getPrintableDeviceMode(msg);
    Serial.print("Device mode: "); Serial.println(msg);

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
    data[17] = deviceID;
    DW1000Time randomDelayTransmit = DW1000Time(random(3000,7000), DW1000Time::MICROSECONDS);
    tsSentPollAck = DW1000.setDelay(randomDelayTransmit);
    DW1000.setData(data, DATA_LENGTH);
    DW1000.startTransmit();
    sentMsgId = POLL_ACK;
}

void transmitRangeReport() {
    DW1000.newTransmit();
    DW1000.setDefaults();
    data[0] = RANGE_REPORT;
    data[17] = deviceID;
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
            Serial.println("Reset");
        }
    return;
    }

    //Received Package
    if(recAck){
        recAck=false;
        DW1000.getData(recData, DATA_LENGTH);
        recMsgId = recData[0];
        recDevId = recData[17];
        if((recMsgId == expectedMsgId)){
            if(recMsgId == POLL){     //Received POLL
                DW1000.getReceiveTimestamp(tsReceivedPoll);
                tsSentPoll.setTimestamp(recData+1);
                Serial.println("Received POLL");
                transmitPollAck();
            }else if(recMsgId == FINAL){                    //Received FINAL
                DW1000.getReceiveTimestamp(tsReceivedFinal);
                Serial.println("Received FINAL");
                tsReceivedPollAck.setTimestamp(recData+6);
                tsSentFinal.setTimestamp(recData+11);
                computeRangeAssymetric();
                transmitRangeReport();
            }
            noteActivity();           //Update Watchdog
        }
    }

    //Sent Package
    if(sentAck){
        sentAck=false;
        if(sentMsgId == POLL_ACK){
            expectedMsgId = FINAL;
            Serial.println("Sent POLL_ACK");
        }
        else if(sentMsgId == RANGE_REPORT){
            expectedMsgId = POLL;      
            Serial.println("Sent RANGE_REPORT");            
        }
    }
}
