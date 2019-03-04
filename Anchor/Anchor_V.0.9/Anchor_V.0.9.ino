/*
 * Copyright (c) 2015 by Thomas Trojer <thomas@trojer.net>
 * Decawave DW1000 library for arduino.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License. 
 * 
 * This file has been modified by authors:
 * Lucas Wassénius
 * Oscar Johansson
 * 
 * The program handles a DW1000 UWB anchor to communicate with a Raspberry Pi connected tag 
 * and handles to two-way ranging computations.
 * 
 */
#include <SPI.h>
#include <DW1000.h>
#include <EEPROM.h>

#define DATA_LENGTH 17
#define DEVICE_ID 0

//Signal Codes
#define POLL 0
#define POLL_ACK 1
#define RANGE_REPORT 3
#define FINAL 5
#define FINAL_ACK 6

//EEPROM ADDRESSES
#define EEPROM_ANTENNA_DELAY_OFFSET 2
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
uint32_t ANTENNA_DELAY = 16300;//Delay to calibrate antenna. Typ. 16470

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
float      computedMeters;

DW1000Time testTransmitTS;

byte data[DATA_LENGTH];     //Data to Send
byte recData[DATA_LENGTH];  //Received Data

uint32_t lastActivity;        //Last noted activity
uint32_t resetPeriod = 110;  //Watchdog Reset Timer
uint16_t delayTimeUS = 1000;  //Delay to transmit on tsSentFinalAck
uint8_t deviceID = DEVICE_ID;

DW1000Time delayTransmit = DW1000Time(delayTimeUS, DW1000Time::MICROSECONDS);

void setup() {
    Serial.begin(115200);//Baud Rate
    Serial.println(F("Anchor Starting..."));

    deviceID = EEPROM.read(EEPROM_DEVICE_ID);
    Serial.print("Anchor ID: ");Serial.println(deviceID);

    //Read ANTENNA DELAY OFFSET from EEPROM(Uncomment when calibrated AD is stored in EEPROM) 16300 + OFFSET
    ANTENNA_DELAY +=  EEPROM.read(EEPROM_ANTENNA_DELAY_OFFSET); 
    Serial.print("Antenna Delay: ");Serial.println(ANTENNA_DELAY);
    
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

    //Attach Interrupt Handlers
    DW1000.attachSentHandler(handleSent);
    DW1000.attachReceivedHandler(handleReceived);
    delay(1000);

    //Setup the receiver
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

//Transmit Poll Acknoledgement and store transmit timestamp
void transmitPollAck() {
    DW1000.newTransmit();
    DW1000.setDefaults();
    data[0] = POLL_ACK;
    data[16] = deviceID; 
    DW1000.setData(data, DATA_LENGTH);
    DW1000.startTransmit();
    sentMsgId = POLL_ACK;
}

//Transmit Range Report with the computed time of flight
void transmitRangeReport() {
    DW1000.newTransmit();
    DW1000.setDefaults();
    data[0] = RANGE_REPORT;
    data[16] = deviceID;
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


/*
 * Range computation with two-way assymetric ranging
 */
void computeRangeAssymetric() {
       DW1000Time round1 = (tsReceivedPollAck - tsSentPoll).wrap();
       DW1000Time reply1 = (tsSentPollAck - tsReceivedPoll).wrap();
       DW1000Time round2 = (tsReceivedFinal - tsSentPollAck).wrap();
       DW1000Time reply2 = (tsSentFinal - tsReceivedPollAck).wrap();
       
       DW1000Time assymetricTime = ((round1 * round2) - (reply1 * reply2)) / (round1 + round2 + reply1 + reply2);
       computedTof.setTimestamp(assymetricTime);
       computedMeters = computedTof.getAsMeters();
       Serial.print("Range: "); Serial.println(computedMeters);
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
        recDevId = recData[16];
        if((recMsgId == expectedMsgId)){
            if(recMsgId == POLL){                           //Received POLL
                noteActivity();                             //Update Watchdog
                DW1000.getReceiveTimestamp(tsReceivedPoll);
                tsSentPoll.setTimestamp(recData+1);
                Serial.println("Received POLL");
                delay(33*deviceID);                         //Different delays for each anchor to avoid collisions
                transmitPollAck();
            }else if(recMsgId == FINAL && recDevId == deviceID){    //Received FINAL
                DW1000.getReceiveTimestamp(tsReceivedFinal);
                Serial.println("Received FINAL");
                tsReceivedPollAck.setTimestamp(recData+6);
                tsSentFinal.setTimestamp(recData+11);
                computeRangeAssymetric();                   //Compute ToF/Range and store in computedTof/computedMeters
                Serial.println(computedMeters);
                if(abs(computedMeters) < 200){
                    delay(3);                               
                    transmitRangeReport();                  //Transmit Range to Tag
                }
            }
            
        }
    }

    //Sent Package
    if(sentAck){
        sentAck=false;
        if(sentMsgId == POLL_ACK){
            expectedMsgId = FINAL;
            DW1000.getTransmitTimestamp(tsSentPollAck);
            Serial.println("Sent POLL_ACK");
        }
        else if(sentMsgId == RANGE_REPORT){
            resetInactive();  
            Serial.println("Sent RANGE_REPORT");            
        }
    }
}
