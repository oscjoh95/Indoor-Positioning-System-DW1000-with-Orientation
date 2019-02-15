"""
This file contains the class for the positioning tags. 
"""
import DW1000
import monotonic
import DW1000Constants as C

class DW1000Tag():
    def __init__(self, moduleName, ss, irq, antennaDelay, uniqueID, dataLen, bus):
        """
        Initialize the module and print a status message
        """
        self.PIN_IRQ = irq
        self.PIN_SS = ss
        self.DEFAULT_ANCHOR_ID = 0
        self.name = moduleName
        self.expectedMsgID = C.POLL_ACK
        self.lastActivity = 0
        self.sentAck = False
        self.receivedAck = False
        self.protocolFailed = False
        self.DATA_LEN = dataLen
        self.data = [0] * self.DATA_LEN
        self.tsSentPollAck = 0
        self.tsReceivedPollAck = 0
        self.tsSentFinal = 0
        self.tsReceivedFinal = 0
        self.tsSentFinalAck = 0
        self.tsReceivedFinalAck = 0
        self.computedTime = 0
        self.REPLY_DELAY_TIME_US = 7000
        self.distance = 0
        self.currentAnchorID = self.DEFAULT_ANCHOR_ID
        
        DW1000.begin(self.PIN_IRQ, bus)
        DW1000.setup(self.PIN_SS)
        print("DW1000 %s initialized" %self.name)
        print("############### ANCHOR ##############")
        DW1000.generalConfiguration(uniqueID, C.MODE_LONGDATA_RANGE_ACCURACY)
        DW1000.registerCallback("handleSent", self.handleSent)
        DW1000.registerCallback("handleReceived", self.handleReceived)
        DW1000.setAntennaDelay(antennaDelay)
        
        self.receiver()
        self.noteActivity()
        
    def millis(self):
        """
        This function returns the value (in milliseconds) of a clock which never goes backwards. It detects the inactivity of the chip and
        is used to avoid having the chip stuck in an undesirable state.
        """
        return int(round(monotonic.monotonic() * C.MILLISECONDS))    
    
    def noteActivity(self):
        """
        Updates the last time the device was active
        """
        self.lastActivity = self.millis()
    
    def handleSent(self):
        """
        Callback for message sent. Sets the sentAck variable true to take action in the loop
        """
        self.sentAck = True
        
    def handleReceived(self):
        """
        Callback for message received. Sets the receivedAck variable true to take action in the loop
        """        
        self.receivedAck = True
    
    def receiver(self):
        """
        This function prepares the module to receive messages
        """
        DW1000.newReceive()
        DW1000.receivePermanently()
        DW1000.startReceive()

    def resetInactive(self):
        """
        Resets the module and transmits a new poll
        """
        self.expectedMsgID = C.POLL_ACK
        self.receiver()
        self.noteActivity()
        self.currentAnchorID = self.DEFAULT_ANCHOR_ID
        print("Reset")
        self.transmitPoll()

    def transmitPoll(self):
        """
        Function that tries to transmit a poll to the anchors
        """
        DW1000.newTransmit()
        self.data[0] = C.POLL
        ts = DW1000.setDelay(self.REPLY_DELAY_TIME_US, C.MICROSECONDS)   #Probably not necessary
        DW1000.setTimeStamp(self.data, ts, 1)
        DW1000.setData(self.data, self.DATA_LEN)
        DW1000.startTransmit()
        print("Poll sent")
       
    def transmitFinal(self):
        """
        Function to transmit the FINAL message
        """
        DW1000.newTransmit()
        self.data[0] = C.FINAL
        ts = DW1000.setDelay(self.REPLY_DELAY_TIME_US, C.MICROSECONDS)   #Probably not necessary
        DW1000.setTimeStamp(self.data, ts, 11)
        DW1000.setData(self.data, self.DATA_LEN)
        DW1000.startTransmit()
        print("Final Sent")
    
    def computeTimesAssymetric(self):
        """
        Computes the assymetric time from the aquired timestamps
        """
        self.round1 = DW1000.wrapTimestamp(self.tsReceivedFinal - self.tsSentPollAck)
        self.reply1 = DW1000.wrapTimestamp(self.tsSentFinal - self.tsReceivedPollAck)
        self.round2 = DW1000.wrapTimestamp(self.tsReceivedFinalAck - self.tsSentFinal)
        self.reply2 = DW1000.wrapTimestamp(self.tsSentFinalAck - self.tsReceivedFinal)
        self.computedTime = ((self.round1 * self.round2) - (self.reply1 * self.reply2)) / (self.round1 + self.round2 + self.reply1 + self.reply2)
        
    def loop(self):
        """
        The main loop of the class that handles the watchdog timer and interrupts from sent and received packets
        """
        #Watchdog check
        if(self.sentAck == False and self.receivedAck == False):
            if((self.millis() - self.lastActivity > C.RESET_PERIOD)):
                self.resetInactive()
            return
        
        #On sent message
        if(self.sentAck):
            print("sent something")
            self.sentAck = False
            self.msgID = self.data[0]
            if(self.msgID == C.FINAL):
                self.noteActivity()
        
        #On received message
        if(self.receivedAck):
            self.receivedAck = False
            self.data = DW1000.getData(self.DATA_LEN)
            self.msgID = self.data[0]
            self.anchorID = self.data[16]
            if((self.msgID != self.expectedMsgID)): #& (self.anchorID == self.currentAnchorID)):
                print("WrongMsgID")
                print(self.msgID)
                self.protocolFailed = True
            elif((self.msgID == C.POLL_ACK)): #& (self.anchorID == self.DEFAULT_ANCHOR_ID)):
                print("Received Poll Ack")
                self.protocolFailed = False
                DW1000.setTimeStamp(self.data, DW1000.getReceiveTimestamp(), 6)
                self.expectedMsgID = C.RANGE_REPORT
                print(self.data)
                self.transmitFinal()
                self.noteActivity()
            elif((self.msgID == C.RANGE_REPORT)): #& (self.anchorID == self.currentAnchorID)):
                self.expectedMsgID = C.POLL_ACK
                self.noteActivity()
                print("Received Range Report")
                if(self.protocolFailed == False):
                    #self.computeTimesAssymetric()
                    self.computedTime = DW1000.getTimeStamp(self.data,1)
                    self.distance = (self.computedTime % C.TIME_OVERFLOW) * C.DISTANCE_OF_RADIO
                    print("Distance: %.2f m" %(self.distance))
                    self.currentAnchorID = self.DEFAULT_ANCHOR_ID
                    return self.distance
                else:
                    self.resetInactive()