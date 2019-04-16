"""
Simulations.py
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
#from KalmanAcceleration import *
from math import *
import monotonic
from ParticleFilter import *
import matplotlib.pyplot as plt

#Setup
CS1 = 12
CS2 = 5
IRQ1 = 6
IRQ2 = 26
ANTENNA_DELAY1 = 16368
ANTENNA_DELAY2 = 16368
ANCHOR1 = (0,0)  #Adjust when anchors placed
ANCHOR2 = (10,0) #Adjust when anchors placed
ANCHOR3 = (5,10) #Adjust when anchors placed
FILTER = 1#No Filter=0, Particle Filter=1, Kalman=2
TAG_DISTANCE = 0.4

#Other constants and variables
startupTime = 1.0
DATA_LEN = 17
data = [0] * 5
d1 = [0] * 3
d2 = [0] * 3
dt1 = 0
dt2 = 0
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
i = 0

#Particle Filter
anchors = np.array([[ANCHOR1[0], ANCHOR1[1]],[ANCHOR2[0], ANCHOR2[1]],[ANCHOR3[0], ANCHOR3[1]]])
sigma = 0.15
vstd = 0.9
hstd = 0.6

#Kalman Filter
xInit1 = 1
yInit1 = 1.3
xInit2 = 1
yInit2 = 0.7
initPosError1 = 0
initPosError2 = 0
sigmaSensor = 0.3
covarianceCoeff = 0.001


#Initialize Filters
if (FILTER == 1):
    pf1 = ParticleFilter(500,10,10, anchors, sigma, vstd, hstd)
    pf2 = ParticleFilter(500,10,10, anchors, sigma, vstd, hstd)
elif (FILTER == 2): 
    kalman1 = KalmanFilter(xInit1, yInit1, initPosError1, sigmaSensor, covarianceCoeff)
    kalman2 = KalmanFilter(xInit2, yInit2, initPosError2, sigmaSensor, covarianceCoeff)

def loop():
    global dt1, dt2, i
    
    """
    if (i < 8):
        trueX = 1
        trueY = 1
        orientation = 0
    elif (i < 56):
        trueX = 1 + 3 *(i-8)/48
        trueY = 1
        orientation = 0
    """
    """
    if (i < 48):
        orientation = 3.14/2
        trueX = 1
        trueY = 1 + 3 *i/48
    elif (i < 56):
        orientation = 3.14/2 - 3.14/2 *(i-52)/8
        trueX = 1
        trueY = 4
    elif (i < 104):
        orientation = 0
        trueX = 1 + 3 *(i-52)/48
        trueY = 4
    elif (i < 112):
        orientation = 0 - 3.14/2 *(i-100)/8
        trueX = 4
        trueY = 4
    elif (i < 160):
        orientation = -3.14/2
        trueX = 4
        trueY = 4 - 3 *(i-104)/48
    """
    
    """
    if (i < 8):
        orientation = 0
        trueX = 3
        trueY = 3
    elif (i < 72):
        orientation = 0 + (i-8)/64 *4*3.14
        trueX = 3
        trueY = 3
    """
    
    
    trueX = 3
    trueY = 3
    orientation = 0
    
    
    #Module 1
    trueX1 = trueX + math.cos(orientation)*TAG_DISTANCE/2
    trueY1 = trueY + math.sin(orientation)*TAG_DISTANCE/2
    d1[0] = math.sqrt(trueX1**2+trueY1**2) + np.random.normal(0,0.04)
    d1[1] = math.sqrt((trueX1-ANCHOR2[0])**2 + trueY1**2) + np.random.normal(0,0.04)
    d1[2] = math.sqrt((trueX1-ANCHOR3[0])**2+(trueY1-ANCHOR3[1])**2) + np.random.normal(0,0.04)
    
    #Module 2
    trueX2 = trueX - math.cos(orientation)*TAG_DISTANCE/2
    trueY2 = trueY - math.sin(orientation)*TAG_DISTANCE/2
    d2[0] = math.sqrt(trueX2**2+trueY2**2) + np.random.normal(0,0.04)
    d2[1] = math.sqrt((trueX2-ANCHOR2[0])**2 + trueY2**2) + np.random.normal(0,0.04)
    d2[2] = math.sqrt((trueX2-ANCHOR3[0])**2+(trueY2-ANCHOR3[1])**2) + np.random.normal(0,0.04)

    i = i+1
    print(i)
    #Particle Filter
    if (FILTER == 1):
        #Filter module 1
        pf1.predict(0.25)
        measurement1 = pf1.update(d1)
        posFiltered1 = pf1.estimate()
        pf1.resample()
        
        #Filter module 2
        pf2.predict(0.25)
        measurement2 = pf2.update(d2)
        posFiltered2 = pf2.estimate()
        pf2.resample()

    #Kalman Filter
    if (FILTER == 2):
        #Filter module 1
        measurement1 = calculatePosition((d1[0], d1[1], d1[2]))
        posFiltered1 = kalman1.filter((measurement1[0],measurement1[1]), 0.25)
        dt1 = millis()
        
        #Filter module 2
        measurement2 = calculatePosition((d2[0], d2[1], d2[2]))
        posFiltered2 = kalman2.filter((measurement2[0],measurement2[1]), 0.25)
        dt2 = millis()
        
    #Orientation Calculations
    orientation = np.arctan2(posFiltered1[1] - posFiltered2[1], posFiltered1[0] - posFiltered2[0])
    print(orientation)
    
    error = trueX - (posFiltered1[0] + posFiltered2[0])/2
    #print(error)
    
    #plt.plot(posFiltered1[0],posFiltered1[1],'gx',posFiltered2[0],posFiltered2[1],'gx')
    #plt.pause(0.1)
    
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
    
    if (i == 400):
        saveData()
        exit()
    
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
    
    return Px,Py

def millis():
    """
    This function returns the value (in milliseconds) of a clock which never goes backwards.
    """
    return int(round(monotonic.monotonic() * C.MILLISECONDS))
   
def saveData():
    global measX1, measY1, measX2, measY2, filtX1, filtY1, filtX2, filtY2, times
    
    for i in range(len(times)-1):
        times[(len(times)-1)-i] -= times[0]
    times[0] = 0.0
    
    data = np.vstack((measX1,measY1,measX2,measY2,filtX1,filtY1,filtX2,filtY2,times))
    data = data.T
    np.savetxt('test',data,delimiter=' ',fmt='%.4f', comments='')#, header='MeasX0 MeasY0 MeasX1 MeasY1 FiltX0 FiltY0 FiltX1 FiltY1 Time')
    print('Saved data to test.txt')
        
def main():
    try:
        while 1:
            dt1 = millis()
            loop()
    except KeyboardInterrupt:
        saveData()
if __name__ == '__main__':
    main()

