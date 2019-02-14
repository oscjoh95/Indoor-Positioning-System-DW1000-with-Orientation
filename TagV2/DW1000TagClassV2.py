"""
This file contains the class for the positioning tags. 
"""
import DW1000
import monotonic
import DW1000Constants as C

class DW1000Tag():
    def __init__(self, moduleName, irq, ss, antennaDelay, uniqueID, dataLen):
        """
        Initialize the module and print a status message
        """
        self.PIN_IRQ = irq
        self.PIN_SS = ss
        self.name = moduleName
        self.expectedMsgID = C.POLL_ACK
        self.lastActivity = 0
        self.sentAck = False
        self.receivedAck = False
        self.protocolFailed = False
        self.DATA_LEN = dataLen
        self.data = [0] * self.DATA_LEN
        self.tsReceivedPoll = 0
		self.tsSentPollAck = 0
        self.tsReceivedFinal = 0
        self.computedTime = 0
        self.REPLY_DELAY_TIME_US = 7000
        self.distance = 0
        
        DW1000.begin(self.PIN_IRQ)
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
        self.expectedMsgID = C.POLL
        self.receiver()
        self.noteActivity()
        print("Reset")

    def transmitPollAck(self):
        """
        Function that tries to transmit a poll to the anchors
        """
        DW1000.newTransmit()
        self.data[0] = C.POLL_ACK
        DW1000.setDelay(self.REPLY_DELAY_TIME_US, C.MICROSECONDS)   #Probably not necessary
        DW1000.setData(self.data, self.DATA_LEN)
        DW1000.startTransmit()
        print("Poll Ack sent")
       
    def transmitFinalAck(self):
        """
        Function to transmit the FINAL message
        """
        DW1000.newTransmit()
        self.data[0] = C.FINAL_ACK
        DW1000.setDelay(self.REPLY_DELAY_TIME_US, C.MICROSECONDS)   #Probably not necessary
		DW1000.setTimestamp(self.data, self.tsReceivedPoll, 1)
		DW1000.getTimestamp(self.data, self.tsSentPollAck, 6)
		DW1000.getTimestamp(self.data, self.tsReceivedFinal, 11)
        DW1000.setData(self.data, self.DATA_LEN)
        DW1000.startTransmit()
        print("Final Ack Sent")

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
            self.sentAck = False
            self.msgID = self.data[0]
            if(self.msgID == C.POLL_ACK):
                self.tsSentPollAck = DW1000.getTransmitTimestamp()
                self.noteActivity()

        #On received message
        if(self.receivedAck):
            self.receivedAck = False
            self.data = DW1000.getData(self.DATA_LEN)
            msgID = data[0]
            if(msgID != expectedMsgID):
                print("WrongMsgID")
                self.protocolFailed = True
            elif(self.msgID == C.POLL):
                self.protocolFailed = False
                self.tsReceivedPoll = DW1000.getReceiveTimestamp()
                self.expectedMsgID = C.FINAL
                self.transmitPollAck()
                self.noteActivity()
                print("Received Poll")
            elif(self.msgID == C.FINAL):
                self.tsReceivedFinal = DW1000.getReceiveTimestamp()
                self.expectedMsgID = C.RANGE_REPORT
				self.transmitFinalAck()
                self.noteActivity
                print("Received Final")
			elif(self.msgID == C.RANGE_REPORT):
                self.computeTimesAssymetric = DW1000.getTimestamp(self.data, 1)
				self.distance = (self.computeTimesAssymetric % C.TIME_OVERFLOW) * C.DISTANCE_OF_RADIO
				print("Distance: %.2f m" %(self.distance))
				return self.distance
