"""
FilterTest.py
Test function for filter classes
"""
import numpy as np
import matplotlib.pyplot as plt
from Kalman import *
LENGTH = 10
#Choice of filters
KALMAN = 1

#Create the filter
##Kalman
if KALMAN == 1:
    initialGuess = (5.0,0.0)
    initialMaxError = 0.0
    sigmaSensor = 0.32
    phi = 0.00003
    kalman = KalmanFilter(initialGuess[0], initialGuess[1], initialMaxError, sigmaSensor, phi) #Px, Py, Initial Max Position Error, Sigma Sensor

#Create position values in a circle
x=[0.0]*LENGTH
for i in range(LENGTH):
    x[i] = i/LENGTH*2*np.pi
positionX = np.linspace(5.0,0.0,10.0)#np.cos(x)*5
positionY = positionX*0#np.sin(x)*5

#Simulate measurements by adding noise
measurementX = positionX + np.random.normal(0,sigmaSensor,LENGTH)
measurementY = positionY + np.random.normal(0,sigmaSensor,LENGTH)

#Filtering happens here
kalmanX = [0.0]*LENGTH
kalmanY = [0.0]*LENGTH
for i in range(LENGTH):
    if KALMAN == 1:
        kalmanX[i],kalmanY[i] = kalman.filter((measurementX[i],measurementY[i]), 1.0)

#Plot the results
plt.plot(positionX, positionY, measurementX,measurementY,'b.', linewidth=1, markersize=0.5)
plt.plot(kalmanX,kalmanY,'r--', linewidth=1)
plt.show()