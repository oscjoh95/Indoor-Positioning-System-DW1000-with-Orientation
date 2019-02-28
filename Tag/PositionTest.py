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
import numpy as np
import matplotlib.pyplot as plt

CS1 = 12
CS2 = 5
IRQ1 = 6
IRQ2 = 26
ANTENNA_DELAY1 = 16435#3
ANTENNA_DELAY2 = 16402#4
startupTime = 1.5
DATA_LEN = 17
data = [0] * 5
d1 = [0] * 3
d2 = [0] * 3
ANCHOR1 = (0.0,0.0)  #Adjust when anchors placed
ANCHOR2 = (2.4,0.0) #Adjust when anchors placed
ANCHOR3 = (0.96,4.79) #Adjust when anchors placed
ANCHOR_LEVEL = 0 #Floor = 0, Ceiling = 1
SAMPLING_TIME = 500#In ms
samplingStartTime = 0
FILTER_CHOICE = 0 #Kalman = 0

#Debug
test = [0]*1000
truePos = (0,0)

#Anchor arrays
anchorX = np.array([ANCHOR1[0], ANCHOR2[0], ANCHOR3[0]])
anchorY = np.array([ANCHOR1[1], ANCHOR2[1], ANCHOR3[1]])

#Initialize module
module1 = DW1000Tag("module1", CS1, IRQ1, ANTENNA_DELAY1, "82:17:5B:D5:A9:9A:E2:1A", DATA_LEN)
print("\n")
time.sleep(startupTime)

#Initialize filter
initX = 5.0
initY = 2.0
kalman1 = KalmanFilter(initX,initY,0,0.4,0.00000001)

#Figure
posX = []
posY = []
line1 = []
line4 = []

def loop():
    global samplingStartTime, posX, posY, measX, measY
    
    #Module 1
    print("-----Module 1-----")
    distance = None
    anchorID = None
    while((millis() - samplingStartTime) < SAMPLING_TIME):
        distance = module1.loop()
        anchorID = module1.getCurrentAnchorID()
        if(distance != None):
           d1[anchorID] = distance
           distance = None
           anchorID = None
           
    #Calculate position from measurements
    print("-----Position Calculations-----")
    measurement = calculatePosition(d1)

    #Filtering
    dt = (millis() - samplingStartTime)/1000
    print(dt)
    #Filter here
    position = kalman1.filter((measurement[0],measurement[1]),dt)
    
    posX.append(position[0])
    posY.append(position[1])
    posX = posX[-10:]
    posY = posY[-10:]
    
    #Plotting
    plotPosition(posX,posY, measurement[0], measurement[1])
    samplingStartTime = millis()
    
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
    
    #position = Px,Py
    position = 0+np.random.normal(0,0.4),0+np.random.normal(0,0.4)
    return position

def plotPosition(posX,posY, measX, measY):
    global line1, line4
    line1,line4 = live_plotter(posX,posY,measX,measY,line1,line4)
    #plt.plot(anchorX,anchorY,'ro',position[0],position[1],'bo', truePos[0],truePos[1],'rx' , markersize=2)
def millis():
    """
    This function returns the value (in milliseconds) of a clock which never goes backwards.
    """
    return int(round(monotonic.monotonic() * C.MILLISECONDS))

def live_plotter(x_vec,y1_data, measX,measY,line1,line4,identifier='',pause_time=0.1):
    global anchorX, anchorY, truePos
    if line1==[]:
        # this is the call to matplotlib that allows dynamic plotting
        plt.ion()
        fig = plt.figure()
        ax = fig.add_subplot(111)
        plt.xlim(-1,5)
        plt.ylim(-1,5)
        # create a variable for the line so we can later update it
        line1, = ax.plot(x_vec,y1_data,'go',markersize=2)
        line2, = ax.plot(anchorX,anchorY, 'ro', markersize=2)
        line3, = ax.plot(truePos[0], truePos[1], 'rx', markersize=2)
        line4, = ax.plot(measX,measY,'bo',markersize=2)
        #update plot label/title
        plt.title('Title: {}'.format(identifier))
        plt.show()
    
    # after the figure, axis, and line are created, we only need to update the y-data
    line1.set_data(x_vec,y1_data)
    line4.set_data(measX,measY)
    # this pauses the data so the figure/axis can catch up - the amount of pause can be altered above
    plt.pause(pause_time)
    
    # return line so we can update it again in the next iteration
    return line1, line4

def main():
    global posX, posY, truePos
    try:
        samplingStartTime = millis()
        while 1:
            loop()
    except KeyboardInterrupt:
        data = np.concatenate((posX,posY),axis=1)
        np.savetxt('test',data,delimiter=' ',fmt='%.4f', header=('%.4f %.4f' % truePos), comments='')
        print('Interrupted by user')
if __name__ == '__main__':
    main()

