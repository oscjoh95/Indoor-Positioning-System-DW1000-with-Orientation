"""
Main file for the tags that are controlled by a raspberry pi. It alternates sampling between the two
tags to keep the distances up to date.
Anchors should be placed in the plane z=0, either in the ceiling or on floor level
"""
import DW1000Constants as C
from DW1000TagClass import *
import time
import RPi.GPIO as GPIO
from Kalman import *
from math import *
import monotonic

CS1 = 12
CS2 = 5
IRQ1 = 6
IRQ2 = 26
ANTENNA_DELAY1 = 16317
ANTENNA_DELAY2 = 16317
startupTime = 1.5
DATA_LEN = 17
data = [0] * 5
d1 = [0] * 3
d2 = [0] * 3
ANCHOR1 = (0,0)  #Adjust when anchors placed
ANCHOR2 = (10,0) #Adjust when anchors placed
ANCHOR3 = (5,10) #Adjust when anchors placed
ANCHOR_LEVEL = 0 #Floor = 0, Ceiling = 1
SAMPLING_TIME = 500 # Approx. divided by 50 to get ms
samplingStartTime = 0
FILTER_CHOICE = 0 #Kalman = 0

"""
#Debugging
x = 7
y = 5
z = -3
d1[0] = sqrt(x*x + y*y + z*z)
x2 = 10 - x
d1[1] = sqrt(x2*x2 + y*y + z*z)
if(x > 5):
    x3 = x - 5
else:
    x3 = 5 - x
y3 = 10 - y
d1[2] = sqrt(x3*x3 + y3*y3 + z*z)
#End Debugging
"""
module1 = DW1000Tag("module1", CS1, IRQ1, ANTENNA_DELAY1, "82:17:5B:D5:A9:9A:E2:1A", DATA_LEN)
module1.idle()
print("\n")
time.sleep(startupTime)

module2 = DW1000Tag("module2", CS2, IRQ2, ANTENNA_DELAY2, "82:17:5B:D5:A9:9A:E2:1B", DATA_LEN)
module2.idle()
print("\n")
time.sleep(startupTime)

kalman1 = KalmanFilter("Module1 filter")
kalman2 = KalmanFilter("Module2 filter")
def loop():
    
    #Module 1
    print("-----Module 1-----")
    range = None
    anchorID = None
    samplingStartTime = millis()
    while((millis() - samplingStartTime) < SAMPLING_TIME):
        range = module1.loop()
        anchorID = module1.getCurrentAnchorID()
        if(range != None):
           d1[anchorID] = range
           print(anchorID)
           range = None
           anchorID = None
    module1.idle()
    print(d1)
    time.sleep(1) #Remove later

    #Module 2
    print("-----Module 2-----")
    range = None
    anchorID = None
    samplingStartTime = millis()
    while((millis() - samplingStartTime) < SAMPLING_TIME):
        range = module2.loop()
        anchorID = module2.getCurrentAnchorID()
        if(range != None):
            d2[anchorID] = range
            range = None
            anchorID = None
    module2.idle()
    print(d2)
    time.sleep(1) #Remove later
    
    #Calculate position measurements
    print("-----Position Calculations-----")
    pos1 = calculatePosition(d1)
    pos2 = calculatePosition(d2)
    print(pos1)
    print(pos2)
    
    #Filtering
    #if(FILTER_CHOICE == 0): #Kalman
        #posFiltered1 = kalman1.filter(pos1)
        #posFiltered2 = kalman2.filter(pos2)
        #print(posFiltered1)
        #print(posFiltered2)
    
def calculatePosition(values):
    """
    Calculates the position as x- and y-coordinates from distance measurements
    """
    delta2x, delta2y = ANCHOR2
    delta3x, delta3y = ANCHOR3
    d1,d2,d3 = values
    
    #Calculate coordinates
    Px = (d1*d1 - d2*d2 + delta2x*delta2x)/(2*delta2x)
    Py = (d1*d1 - d3*d3 + delta3x*delta3x + delta3y*delta3y - 2*delta3x*Px)/(2*delta3y)
    if((d1*d1 - Px*Px - Py*Py) > 0):
        Pz = sqrt(d1*d1 - Px*Px - Py*Py)
    else:
        Pz = 0
        
    #Negative z if anchors are placed in the ceiling
    if(ANCHOR_LEVEL == 1):
        Pz = -Pz
        
    position = Px,Py,Pz
    return position

def millis():
    """
    This function returns the value (in milliseconds) of a clock which never goes backwards.
    """
    return int(round(monotonic.monotonic() * C.MILLISECONDS))
    
def main():
    try:
        while 1:
            loop()
    except KeyboardInterrupt:
        print('Interrupted by user')
if __name__ == '__main__':
    main()
