
#include <SPI.h>
#include <DW1000.h>


#define DATA_LENGTH 17
#define DEVICE_ID 1

#define POLL 0
#define POLL_ACK 1
#define FINAL 5
#define FINAL_ACK 6

// connection pins
const uint8_t PIN_RST = 9; // reset pin
const uint8_t PIN_IRQ = 2; // irq pin
const uint8_t PIN_SS = SS; // spi select pin

volatile byte expectedMsgId = POLL;
volatile byte recMsgId;
volatile byte sentMsgId;

//Calibration of antenna
const uint32_t ANTENNA_DELAY = 16470;//16470

//Received Interrupts
volatile boolean sentAck = false;
volatile boolean recAck = false;

// Timestamps
DW1000Time tsPollAckSent;
DW1000Time tsFinalReceived;
DW1000Time tsFinalAckSent;



byte data[DATA_LENGTH];     //Data to Send
byte recData[DATA_LENGTH];  //Received Data

uint32_t lastActivity;        //Last noted activity
uint32_t resetPeriod = 1000;   //Watchdog Reset Timer
uint16_t delayTimeUS = 7000;  //Delay to transmit on tsFinalAckSent

void setup() {
    Serial.begin(115200);//Baud Rate
    Serial.println(F("Anchor Starting..."));

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
    transmitFinalAck();
    noteActivity();
    Serial.println(F("Anchor Initialized"));
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
    DW1000.setDelay(DW1000Time(delayTimeUS, DW1000Time::MICROSECONDS));
    DW1000.setData(data, DATA_LENGTH);
    DW1000.startTransmit();
    sentMsgId = POLL_ACK;
}

void transmitFinalAck() {
    DW1000.newTransmit();
    DW1000.setDefaults();
    data[0] = FINAL_ACK;
    data[17] = DEVICE_ID;
    DW1000Time delayFinalAck = DW1000Time(delayTimeUS, DW1000Time::MICROSECONDS);
    tsFinalAckSent = DW1000.setDelay(delayFinalAck);
    tsPollAckSent.getTimestamp(data + 1);
    tsFinalReceived.getTimestamp(data + 6);
    tsFinalAckSent.getTimestamp(data + 11);
    DW1000.setData(data, DATA_LENGTH);
    DW1000.startTransmit();
    sentMsgId = FINAL_ACK;
}

//Handles sent interrupts
void handleSent() {
    sentAck = true;
}

//Handles receive interrupts
void handleReceived() {
    DW1000.getData(recData, DATA_LENGTH);
    recMsgId = recData[0];
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
        if(recMsgId == expectedMsgId){
            if(recMsgId == POLL){     //Received POLL
                Serial.println("Received POLL");
                transmitPollAck();
            }else{                    //Received FINAL
                DW1000.getReceiveTimestamp(tsFinalReceived);
                Serial.println("Received FINAL");
                transmitFinalAck();
            }
            noteActivity();           //Update Watchdog
        }
    }

    //Sent Package
    if(sentAck){
        sentAck=false;
        if(sentMsgId == POLL_ACK){
            DW1000.getTransmitTimestamp(tsPollAckSent);
            expectedMsgId = FINAL;
            Serial.println("Sent POLL_ACK");
            receiver();
        }else{
            DW1000.getTransmitTimestamp(tsPollAckSent);
            expectedMsgId = POLL;      
            Serial.println("Sent FINAL_ACK");
        }
    }
}
