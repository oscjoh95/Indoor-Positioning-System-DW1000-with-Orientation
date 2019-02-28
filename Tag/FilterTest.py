"""
FilterTest.py
Test function for filter classes
"""
import numpy as np
import matplotlib.pyplot as plt
from Kalman import *

#Choice of filters
KALMAN = 1

#Create the filter
##Kalman
if KALMAN == 1:
    initialGuess = (5,0)
    initialMaxError = 0
    sigmaSensor = 0.3
    phi = 0.0000001
    kalman = KalmanFilter(initialGuess[0], initialGuess[1], initialMaxError, sigmaSensor, phi) #Px, Py, Initial Max Position Error, Sigma Sensor

#Create position values in a circle
x=[0]*1000
for i in range(1000):
    x[i] = i/1000*2*np.pi
positionX = np.cos(x)*5
positionY = np.sin(x)*5

#Simulate measurements by adding noise
measurementX = positionX + np.random.normal(0,sigmaSensor,1000)
measurementY = positionY + np.random.normal(0,sigmaSensor,1000)

#Filtering happens here
kalmanX = [0]*1000
kalmanY = [0]*1000
for i in range(1000):
    if KALMAN == 1:
        kalmanX[i],kalmanY[i] = kalman.filter((measurementX[i],measurementY[i]), 1)

#Plot the results
plt.plot(positionX, positionY, measurementX,measurementY,'b.', linewidth=1, markersize=0.5)
plt.plot(kalmanX,kalmanY,'r--', linewidth=1)
plt.show()