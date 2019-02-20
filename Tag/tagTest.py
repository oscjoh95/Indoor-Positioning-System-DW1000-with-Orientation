"""
Main file for the tags that are controlled by a raspberry pi. It alternates sampling between the two
tags to keep the distances up to date.
"""
import DW1000Constants as C
from DW1000TagClass import *
import time
import RPi.GPIO as GPIO
from Kalman import *

CS1 = 12
CS2 = 5
IRQ1 = 6
IRQ2 = 26
ANTENNA_DELAY1 = 16317
ANTENNA_DELAY2 = 16317
startupTime = 1
DATA_LEN = 17
data = [0] * 5
d1 = [0] * 3
d2 = [0] * 3
anchorID = 0

time.sleep(startupTime)

#module1 = DWM1000_ranging("module1", "82:17:5B:D5:A9:9A:E2:1A", CS1, IRQ1, ANTENNA_DELAY1)
module1 = DW1000Tag("module1", CS1, IRQ1, ANTENNA_DELAY1, "82:17:5B:D5:A9:9A:E2:1A", DATA_LEN)
module1.idle()
print("\n")

time.sleep(startupTime)

#module2 = DWM1000_ranging("module2", "82:17:5B:D5:A9:9A:E2:1B", CS2, IRQ2, ANTENNA_DELAY2)
module2 = DW1000Tag("module2", CS2, IRQ2, ANTENNA_DELAY2, "82:17:5B:D5:A9:9A:E2:1B", DATA_LEN)
module2.idle()
time.sleep(startupTime)

kalman1 = KalmanFilter("Module1 filter")
kalman2 = KalmanFilter("Module2 filter")
def loop():
    global d11, d12, d13, d21, d22, d23, anchorID
    
    #Module 1
    print("-----Module 1-----")
    range = None
    anchorID = None
    i = 0
    while((i < 20000)):#& (i < 5000)):
        i += 1
        range = module1.loop()
        anchorID = module1.getCurrentAnchorID()
        if(range != None):
           d1[anchorID] = range
           range = None
           anchorID = None
    module1.idle()
    print(d1)
    print("\n")
    time.sleep(1) #Remove later

    #Module 2
    print("-----Module 2-----")
    range = None
    i = 0
    while((i < 20000)):# & (i < 5000)):
        i += 1
        range = module2.loop()
        anchorID = module2.getCurrentAnchorID()
        if(range != None):
            d2[anchorID] = range
            range = None
            anchorID = None
    module2.idle()
    print(d2)
    print("\n")
    time.sleep(1) #Remove later
    
    #Calculate position measurements
    pos1 = 1,7
    pos2 = 4,5
    
    #Kalman filter stuff using calculated measurements
    pos1 = kalman1.filter(pos1)
    pos2 = kalman2.filter(pos2)
    print(pos1)
    print(pos2)
    
def main():
    try:
        while 1:
            loop()
    except KeyboardInterrupt:
        print('Interrupted by user')
if __name__ == '__main__':
    main()
