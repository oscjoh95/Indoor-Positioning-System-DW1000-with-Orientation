"""
tagTest.py
Oscar Johansson, Lucas Wassénius
Main file for the tags that are controlled by a raspberry pi. It alternates sampling between the two
tags to keep the distances up to date.
Anchors should be placed in the plane z=0, either in the ceiling or on floor level
"""
import DW1000Constants as C
from DW1000TagClass import *
import time
import RPi.GPIO as GPIO
from Kalman import *
from KalmanAcceleration import *
from math import *
import monotonic
from ParticleFilter import *

CS1 = 12
CS2 = 5
IRQ1 = 6
IRQ2 = 26
ANTENNA_DELAY1 = 16317
ANTENNA_DELAY2 = 16317
startupTime = 1.0
DATA_LEN = 17
data = [0] * 5
d1 = [0] * 3
d2 = [0] * 3
dt1 = 0
dt2 = 0
ANCHOR1 = (0,0)  #Adjust when anchors placed
ANCHOR2 = (10,0) #Adjust when anchors placed
ANCHOR3 = (5,10) #Adjust when anchors placed
ANCHOR_LEVEL = 0 #Floor = 0, Ceiling = 1
SAMPLING_TIME = 250 #In ms
samplingStartTime = 0

#Particle Filter
anchors = np.array([[0, 0],[10, 0],[5, 10]])
sigma = 0.9
vstd = 0.1
hstd = 0.2
pf1 = ParticleFilter(500,10,10, anchors, sigma, vstd, hstd)
pf2 = ParticleFilter(500,10,10, anchors, sigma, vstd, hstd)

module1 = DW1000Tag("module1", CS1, IRQ1, ANTENNA_DELAY1, "82:17:5B:D5:A9:9A:E2:1A", DATA_LEN)
module1.idle()
print("\n")
time.sleep(startupTime)

module2 = DW1000Tag("module2", CS2, IRQ2, ANTENNA_DELAY2, "82:17:5B:D5:A9:9A:E2:1B", DATA_LEN)
module2.idle()
print("\n")
time.sleep(startupTime)
 
def loop():
    global dt1, dt2
    
    #Module 1
    range = None
    anchorID = None
    d1[0] = None
    d1[1] = None
    d1[2] = None 
    samplingStartTime = millis()
    while((millis() - samplingStartTime) < SAMPLING_TIME) & ((d1[0] == None) | (d1[1] == None) | (d1[2] == None)):
        range = module1.loop()
        anchorID = module1.getCurrentAnchorID()
        if(range != None):
           #print(anchorID)
           d1[anchorID] = range
           range = None
           anchorID = None
    module1.idle()

    #Module 2
    range = None
    anchorID = None
    d2[0] = None
    d2[1] = None
    d2[2] = None
    samplingStartTime = millis()
    while((millis() - samplingStartTime) < SAMPLING_TIME) & ((d2[0] == None) | (d2[1] == None) | (d2[2] == None)):
        range = module2.loop()
        anchorID = module2.getCurrentAnchorID()
        if(range != None):
            d2[anchorID] = range
            range = None
            anchorID = None
    module2.idle()
    
    #Filter module 1
    if ((d1[0] != None) & (d1[1] != None) & (d1[2] != None)):
        print(millis() - dt1)
        pf1.predict(millis() - dt1)
        dt1 = millis()
        pf1.update(d1)
        posFiltered1 = pf1.estimate()
        pf1.resample()
        
    #Filter module 2
    if ((d2[0] != None) & (d2[1] != None) & (d2[2] != None)):
        pf2.predict(millis() - dt2)
        dt2 = millis()
        pf2.update(d2)
        posFiltered2 = pf2.estimate()
        pf2.resample()
    
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
            dt1 = millis()
            loop()
    except KeyboardInterrupt:
        print('Interrupted by user')
if __name__ == '__main__':
    main()
