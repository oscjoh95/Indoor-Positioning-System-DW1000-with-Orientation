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
ANTENNA_DELAY1 = 16368
ANTENNA_DELAY2 = 16368
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
SAMPLING_TIME = 239 #In ms
samplingStartTime = 0
measX1 = []
measY1 = []
measX2 = []
measY2 = []
filtX1 = []
filtY1 = []
filtX2 = []
filtY2 = []
times = []


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
    #module1.receiver()
    samplingStartTime = millis()
    while((d1[0] == None) | (d1[1] == None) | (d1[2] == None)): #(millis() - samplingStartTime) < SAMPLING_TIME) & 
        range = module1.loop()
        anchorID = module1.getCurrentAnchorID()
        if(range != None):
            print("module1")
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
    while((d2[0] == None) | (d2[1] == None) | (d2[2] == None)): #(millis() - samplingStartTime) < SAMPLING_TIME) & 
        range = module2.loop()
        anchorID = module2.getCurrentAnchorID()
        if(range != None):
            print("module2")
            d2[anchorID] = range
            range = None
            anchorID = None
    print(millis() - samplingStartTime)
    module2.idle()
    
    #Filter module 1
    if ((d1[0] != None) & (d1[1] != None) & (d1[2] != None)):
        #print(millis() - dt1)
        pf1.predict(millis() - dt1)
        dt1 = millis()
        measurement1 = pf1.update(d1)
        posFiltered1 = pf1.estimate()
        pf1.resample()
        
    #Filter module 2
    if ((d2[0] != None) & (d2[1] != None) & (d2[2] != None)):
        pf2.predict(millis() - dt2)
        dt2 = millis()
        measurement2 = pf2.update(d2)
        posFiltered2 = pf2.estimate()
        pf2.resample()
    
    #Orientation Calculations
    orientation = np.arctan2(posFiltered1[1] - posFiltered2[1], posFiltered1[0] - posFiltered2[0])
    print(orientation)
    
    #Save measurements and filtered positions
    measX1.append(measurement1[0])
    measY1.append(measurement1[1])
    measX2.append(measurement2[0])
    measY2.append(measurement2[1])
    filtX1.append(posFiltered1[0])
    filtY1.append(posFiltered1[1])
    filtX2.append(posFiltered2[0])
    filtY2.append(posFiltered2[1])
    times.append(int(round(time.time() * 1000)))
    
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
    global measX1, measY1, measX2, measY2, filtX1, filtY1, filtX2, filtY2, times
    try:
        while 1:
            dt1 = millis()
            loop()
    except KeyboardInterrupt:
        #Save measured and filtered data to a text file on ctrl+c
        for i in range(len(times)-1):
            times[(len(times)-1)-i] -= times[0]
        times[0] = 0.0
        
        data = np.vstack((measX1,measY1,measX2,measY2,filtX1,filtY1,filtX2,filtY2,times))
        data = data.T
        np.savetxt('test',data,delimiter=' ',fmt='%.4f', comments='', header='MeasX0 MeasY0 MeasX1 MeasY1 FiltX0 FiltY0 FiltX1 FiltY1 Time')
        print('Saved data to test.txt')
if __name__ == '__main__':
    main()
