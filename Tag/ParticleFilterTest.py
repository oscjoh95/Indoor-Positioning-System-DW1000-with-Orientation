"""
ParticleFilterTest.py
Oscar Johansson, Lucas Wassénius
This is the test file for the particle filter. It contains code for
creating values of the true poosition, simulate measurements of these and filter them.
There's also code to measure the mean error of the measurements and the filtered values
and some plotting functions. 
"""
from ParticleFilter import *
import numpy as np
import time
from scipy import stats
import math
import warnings
warnings.filterwarnings("ignore",".*GUI is implemented.*")

truePos = (5,5)
anchors = np.array([[0, 0],[10, 0],[5, 10]])
sigma = 0.09

pf = ParticleFilter(1000,10,10, anchors, sigma)

plt.xlim(0,10)
plt.ylim(0,10)
temp = 0
temp2 = 0

steps = 60
i = 0
while 1:
    if i < steps:
        i += 1
        truePos = (5 +abs(i-5)/5,5 +(i-5)/5)
        #truePos = (math.cos(i/steps*2*np.pi)*5,math.sin(i/steps*2*np.pi)*5)
                
    #Fake measurements
    z = np.linalg.norm(anchors - truePos, axis=1) + np.random.normal(0,sigma, 3)
    
    pf.predict(0.5)
    z2 = pf.update(z)
    x = pf.estimate()
    pf.resample()
    
    if (i < steps) & (i>0):
        temp += math.sqrt((truePos[0] - x[0])**2 + (truePos[0] - x[0])**2)
        temp2 += math.sqrt((truePos[0] - z2[0])**2 + (truePos[0] - z2[0])**2)
    if i == steps-1:
        temp /= steps
        temp2 /= steps
        print(temp)
        print(temp2)  
    
    plt.plot(truePos[0],truePos[1],'ms')
    plt.plot(x[0], x[1],'rx')
    plt.pause(0.01)
    plt.clf()
    plt.xlim(0,10)
    plt.ylim(0,10)
    