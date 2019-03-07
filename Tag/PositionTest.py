"""
PositionTest.py
Test file for positioning of one tag. It includes real time plotting and possibility
to save measurement and filtered values to a text file.
"""
import DW1000Constants as C
from DW1000TagClass import *
import time
import RPi.GPIO as GPIO
from Kalman import *
from ParticleFilter import *
from math import *
import monotonic
import numpy as np
import warnings
import matplotlib.pyplot as plt
warnings.filterwarnings("ignore",".*GUI is implemented.*")

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
ANCHOR_LEVEL = 0 #Floor = 0, Ceiling = 1
SAMPLING_TIME = 500#In ms
samplingStartTime = 0

#Setup constants
ANCHOR1 = (0.0,0.0)  #Adjust when anchors placed
ANCHOR2 = (2.4,0.0) #Adjust when anchors placed
ANCHOR3 = (0.96,4.79) #Adjust when anchors placed
truePos = (0.96,0.50)

#Filter
FILTER = 0 # 0=Kalman, 1=PF

#Kalman
initX = 5.0
initY = 2.0
initMaxError = 2
sigmaSensor = 0.4
phi = 0.001

#PF
N = 1000
xDim = 10
yDim = 10
anchors = np.array([[0, 0],[10, 0],[5, 10]])
sigma = 0.09

#Anchor arrays
anchorX = np.array([ANCHOR1[0], ANCHOR2[0], ANCHOR3[0]])
anchorY = np.array([ANCHOR1[1], ANCHOR2[1], ANCHOR3[1]])

#Initialize module
module1 = DW1000Tag("module1", CS1, IRQ1, ANTENNA_DELAY1, "82:17:5B:D5:A9:9A:E2:1A", DATA_LEN)
print("\n")
time.sleep(startupTime)

#Initialize filter
if FILTER == 0:
    kalman1 = KalmanFilter(initX,initY,initMaxError,sigmaSensor,phi)
if FILTER == 1:
    pf = ParticleFilter(N, xDim, yDim, anchors, sigma)
    
#Figure
posX = []
posY = []
line1 = []
line4 = []

#Arrays for saving values to text file 
filX = []
filY = []
measX = []
measY = []

def loop():
    global samplingStartTime, posX, posY, filX, filY, measX, measY
    
    #Module 1
    print("-----Module 1-----")
    distance = None
    anchorID = None
    samplingStartTime = millis()
    while((millis() - samplingStartTime) < SAMPLING_TIME):
        distance = module1.loop()
        anchorID = module1.getCurrentAnchorID()
        if(distance != None):
           d1[anchorID] = distance
           distance = None
           anchorID = None
         
    #Filtering     
    if FILTER == 1:
        dt = (millis() - samplingStartTime)/1000
        pf.predict(dt)
        measurement = pf.update(d1)
        position = pf.estimate()
        pf.resample()
        
    #Calculate position from measurements
    if FILTER == 0:
        print("-----Position Calculations-----")
        measurement = calculatePosition(d1)


    #Filtering
    if FILTER == 0:
        dt = (millis() - samplingStartTime)/1000
        position = kalman1.filter((measurement[0],measurement[1]),dt)
    
    #Save measurement and filtered values 
    posX.append(position[0])
    posY.append(position[1])
    filX.append(position[0])
    filY.append(position[1])
    measX.append(measurement[0])
    measY.append(measurement[1])
    posX = posX[-10:]
    posY = posY[-10:]
    
    #Plotting
    plotPosition(posX,posY, measurement[0], measurement[1])
    
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
    
    position = Px,Py
    #position = 0+np.random.normal(0,sigmaSensor),0+np.random.normal(0,sigmaSensor)
    return position

def plotPosition(posX,posY, measX, measY):
    """
    Function that takes the measurement and filter values and feed them  to the
    function that updates the plot
    """
    global line1, line4
    line1,line4 = live_plotter(posX,posY,measX,measY,line1,line4)
    
def millis():
    """
    This function returns the value (in milliseconds) of a clock which never goes backwards.
    """
    return int(round(monotonic.monotonic() * C.MILLISECONDS))

def live_plotter(x_vec,y1_data, measX,measY,line1,line4,identifier='',pause_time=0.01):
    """
    This function updates the plot with new values 
    """
    global anchorX, anchorY, truePos
    if line1==[]:
        #Initialize the figure on first call
        plt.ion()
        fig = plt.figure()
        ax = fig.add_subplot(111)
        plt.xlim(-1,5)
        plt.ylim(-1,5)
        #Create a variables for the lines so we can update them later
        line1, = ax.plot(x_vec,y1_data,'go',markersize=2)
        line2, = ax.plot(anchorX,anchorY, 'ro', markersize=2)
        line3, = ax.plot(truePos[0], truePos[1], 'rx', markersize=2)
        line4, = ax.plot(measX,measY,'bo',markersize=2)
        plt.show()
    
    #After the figure, axis, and line are created, we only need to update the data
    line1.set_data(x_vec,y1_data)
    line4.set_data(measX,measY)
    # this pauses the data so the figure/axis can catch up
    plt.pause(pause_time)
    # return line so we can update it again in the next iteration
    return line1, line4

def main():
    global filX, filY, measX, measY, truePos
    try:
        samplingStartTime = millis()
        while 1:
            loop()
    except KeyboardInterrupt:
        #Save measured and filtered data to a text file on ctrl+c
        data1 = np.vstack((measX,measY))
        data2 = np.hstack((filX,filY))
        data1 = data1.T
        print(data1)
        print(data2)
        data = np.hstack((data1,data2))
        print(data)
        np.savetxt('test',data,delimiter=' ',fmt='%.4f', header=('%.4f %.4f %.4f %.4f' % (truePos[0], truePos[1], 0.0,0.0)), comments='')
        print('Interrupted by user')
if __name__ == '__main__':
    main()

