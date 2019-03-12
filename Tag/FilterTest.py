"""
FilterTest.py
Test function for filter classes
"""
import numpy as np
import matplotlib.pyplot as plt
from Kalman import *
from ParticleFilter import *
LENGTH = 10
#Choice of filters
KALMAN = 0
PF = 1
sigmaSensor = 0.32

#Create the filter
##Kalman
if KALMAN == 1:
    initialGuess = (0.0,0.0)
    initialMaxError = 0.0
    phi = 0.00001
    kalman = KalmanFilter(initialGuess[0], initialGuess[1], initialMaxError, sigmaSensor, phi) #Px, Py, Initial Max Position Error, Sigma Sensor

#Create position values 
x=[0.0]*LENGTH
positionX = [0.0]*LENGTH
for i in range(LENGTH):
    positionX[i] = (i/2)**2/10 + 2#i/LENGTH*2*np.pi
#positionX = x#np.cos(x)*5
positionY = [2.0]*LENGTH#positionX*0#np.sin(x)*5

#Simulate measurements by adding noise
measurementX = positionX + np.random.normal(0,sigmaSensor,LENGTH)
measurementY = positionY + np.random.normal(0,sigmaSensor,LENGTH)
    
##PF
if PF == 1:
    anchors = np.array([[0, 0],[10, 0],[5, 10]])
    sigma = 0.3
    vstd = 0.15
    hstd = 0.25
    pf = ParticleFilter(1000,4,4, anchors, sigma, vstd, hstd)
    

#Filtering happens here
filteredX = [0.0]*LENGTH
filteredY = [0.0]*LENGTH
for i in range(LENGTH):
    if KALMAN == 1:
        filteredX[i],filteredY[i] = kalman.filter((measurementX[i],measurementY[i]), 3.0)
    
    if PF == 1:
        pf.predict(3.0)
        z2 = pf.updateTest(measurementX[i],measurementY[i])
        filteredX[i],filteredY[i] = pf.estimate()
        pf.resample()

#Plot the results
plt.plot(positionX, positionY,'ms', measurementX,measurementY,'bo', linewidth=1, markersize=3.0)
plt.plot(filteredX,filteredY,'rx', linewidth=1)
plt.show()