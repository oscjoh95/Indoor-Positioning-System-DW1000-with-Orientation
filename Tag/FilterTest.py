import numpy as np
import matplotlib.pyplot as plt
from Kalman import *

sigmaSensor = 0.3
kalman = KalmanFilter(5, 0, 0, sigmaSensor) #Px, Py, Initial Max Position Error, Sigma Sensor

x=[0]*1000
for i in range(1000):
    x[i] = i/1000*2*np.pi
positionX = np.cos(x)*5
positionY = np.sin(x)*5

measurementX = positionX + np.random.normal(0,sigmaSensor,1000)
measurementY = positionY + np.random.normal(0,sigmaSensor,1000)

#Filtering happens here

plt.plot(positionX, positionY, measurementX,measurementY,'b.',linewidth=0.5, markersize=0.5)
plt.show()