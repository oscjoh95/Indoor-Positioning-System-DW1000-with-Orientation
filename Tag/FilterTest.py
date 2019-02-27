"""
Test function for filter classes
"""
import numpy as np
import matplotlib.pyplot as plt
from Kalman import *

#Create the filter
sigmaSensor = 0.3
kalman = KalmanFilter(5, 0, 0, sigmaSensor,0.0000001) #Px, Py, Initial Max Position Error, Sigma Sensor

#Create position values
x=[0]*1000
for i in range(1000):
    x[i] = i/1000*2*np.pi
positionX = np.cos(x)*5
positionY = np.sin(x)*5

#Simulate measurements
measurementX = positionX + np.random.normal(0,sigmaSensor,1000)
measurementY = positionY + np.random.normal(0,sigmaSensor,1000)

#Filtering happens here
filteredX = [0]*1000
filteredY = [0]*1000
for i in range(1000):
    filteredX[i],filteredY[i] = kalman.filter((measurementX[i],measurementY[i]), 1)

#Plot the results
plt.plot(positionX, positionY, measurementX,measurementY,'b.', filteredX,filteredY,'r--', linewidth=0.5, markersize=0.5)
plt.show()