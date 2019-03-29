
#include <SPI.h>
#include <DW1000.h>
#include <EEPROM.h>

#define DATA_LENGTH 17
#define DEVICE_ID 255

#define EEPROM_ANTENNA_DELAY_OFFSET 2
#define EEPROM_DEVICE_ID 1

#define POLL 0
#define POLL_ACK 1
#define RANGE_REPORT 3
#define FINAL 5
#define FINAL_ACK 6

// connection pins
const uint8_t PIN_RST = 9; // reset pin
const uint8_t PIN_IRQ = 2; // irq pin
const uint8_t PIN_SS = SS; // spi select pin

volatile byte expectedMsgId = POLL_ACK;
volatile byte recMsgId;   //Received message ID
volatile byte recDevId;   //Received Device ID
volatile byte sentMsgId;  //Sent Message ID


uint32_t ANTENNA_DELAY = 16300;//Standard Antenna Delay - Adjusted in setup through EEPROM
uint8_t deviceID = DEVICE_ID;

//Received Interrupts
volatile boolean sentAck = false;
volatile boolean recAck = false;

// Timestamps for range calculations
DW1000Time tsSentPoll;
DW1000Time tsReceivedPollAck;
DW1000Time tsSentFinal;

byte data[DATA_LENGTH];     //Data to Send
byte recData[DATA_LENGTH];  //Received Data

uint32_t lastActivity;        //Last noted activity
uint32_t resetPeriod = 100;  //Watchdog Reset Timer
uint16_t delayTimeUS = 3000;  //Delay to transmit on tsSentFinalAck

DW1000Time delayTransmit = DW1000Time(delayTimeUS, DW1000Time::MICROSECONDS);

void setup() {
    Serial.begin(115200);//Baud Rate
    Serial.println(F("Tag Starting..."));

    //Setup Output Pins Arduino Pro Mini
    DW1000.begin(PIN_IRQ, PIN_RST);
    DW1000.select(PIN_SS);

    //Set ANTENNA_DELAY from calibrated values
    ANTENNA_DELAY += EEPROM.read(EEPROM_ANTENNA_DELAY_OFFSET);
    Serial.println(ANTENNA_DELAY);
    
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

    //Attach Interrupt Handlers
    DW1000.attachSentHandler(handleSent);
    DW1000.attachReceivedHandler(handleReceived);
    delay(500);
    receiver();
    Serial.println(F("Tag Initialized: Polling..."));
    noteActivity();
    transmitPoll();
}    

void receiver() {
    DW1000.newReceive();
    DW1000.setDefaults();
    DW1000.receivePermanently(true); //After Transmit enter RX_Mode
    DW1000.startReceive();
}

void transmitPoll() {
    DW1000.newTransmit();
    DW1000.setDefaults();
    data[0] = POLL;
    data[16] = DEVICE_ID;
    tsSentPoll = DW1000.setDelay(delayTransmit);
    tsSentPoll.getTimestamp(data + 1);
    DW1000.setData(data, DATA_LENGTH);
    DW1000.startTransmit();
    sentMsgId = POLL;
}

void transmitFinal() {
    DW1000.newTransmit();
    DW1000.setDefaults();
    data[0] = FINAL;
    data[16] = DEVICE_ID;
    tsSentFinal = DW1000.setDelay(delayTransmit);
    tsReceivedPollAck.getTimestamp(data + 6);
    tsSentFinal.getTimestamp(data + 11);
    DW1000.setData(data, DATA_LENGTH);
    DW1000.startTransmit();
    sentMsgId = FINAL;
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
    expectedMsgId = POLL_ACK;
    receiver();
    noteActivity(); 
    transmitPoll();
}


void loop() { 
    // Watchdog Timer if nothing is received
    if (!sentAck && !recAck) { 
        // check if inactive
        if (millis() - lastActivity > resetPeriod) {
            resetInactive();
            //Serial.println("Reset");
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
            noteActivity();
            if(recMsgId == POLL_ACK){                     //Received POLL_ACK
                DW1000.getReceiveTimestamp(tsReceivedPollAck);
                Serial.println("Received POLL_ACK");
                transmitFinal();
            }else if(recMsgId == RANGE_REPORT){           //Received RANGE_REPORT
                //Serial.println("Received RANGE_REPORT");
                expectedMsgId = 255;
            }
            noteActivity();           //Update Watchdog
        }
    }

    //Sent Package
    if(sentAck){
        sentAck=false;
        if(sentMsgId == POLL){
            expectedMsgId = POLL_ACK;
            //Serial.println("Sent POLL");
        }
        else if(sentMsgId == FINAL){
            expectedMsgId = RANGE_REPORT;      
            //Serial.println("Sent FINAL");            
        }
    }
}
