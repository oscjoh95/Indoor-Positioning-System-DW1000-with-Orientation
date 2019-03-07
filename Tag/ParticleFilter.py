"""
ParticleFilter.py
Oscar Johansson, Lucas Wassenius
This class contains the functions needed for a particle filter for a positioning system.

"""
import numpy as np
from numpy.random import uniform
import matplotlib.pyplot as plt
import math
import scipy as sp
import random as r
from scipy import stats

class ParticleFilter():
    
    def __init__(self, N, xDim, yDim, anchors, sigma):
        
        #Tuning parameters
        self.velocitystd = 0.13 # 0.15
        self.headingstd = 0.29 # 0.27
        self.measImp = sigma*1.5
        self.N = N
        self.xDim = xDim
        self.yDim = yDim
        
        self.anchors = anchors
        
        #Spread particles evenly
        self.weights = np.empty(self.N)
        self.weights.fill(1.0/self.N)
        
        self.particles = np.empty((self.N,4))
        self.particles[:,0] = uniform(0, xDim, size=self.N) #X
        self.particles[:,1] = uniform(0, yDim, size=self.N) #Y
        self.particles[:,2] = uniform(-0.5, 0.5, size=self.N) #Speed
        self.particles[:,3] = uniform(0, 2*np.pi, size=self.N) #Heading
        

        
    def predict(self, dt):
        """
        Predicts the position, speed and heading of the particles
        """
        self.particles[:,3] += np.random.normal(0, self.headingstd, self.N)
        self.particles[:,2] += np.random.normal(0, self.velocitystd, self.N)
        self.particles[:,1] += self.particles[:,2]*np.sin(self.particles[:,3])
        self.particles[:,0] += self.particles[:,2]*np.cos(self.particles[:,3])
        
    def update(self, z):
        """
        This function updates the weights of the particles depending on their
        distance from the measured value z.
        """
        x = (z[0]**2 - z[1]**2 + self.anchors[1][0]**2)/(2*self.anchors[1][0])
        y = (z[0]**2 - z[2]**2 + self.anchors[2][0]**2 + self.anchors[2][1]**2 - 2*self.anchors[2][0]*x)/(2*self.anchors[2][1])
        
        dist = np.linalg.norm(self.particles[:,0:2] - (x,y), axis = 1)
        
        self.weights *= sp.stats.norm(0, self.measImp).pdf(dist)
        self.weights /= sum(self.weights)
        
        maxIndex = np.argmax(self.weights)
        
        #plt.plot(self.particles[:,0],self.particles[:,1], 'b.', markersize = 0.5)
        #plt.plot(x,y,'gx')
        
        return x,y
    
    def estimate(self):
        """
        Calculates the estimateed value of the position based on the particle
        positions and their weights
        """
        estposx = 0
        estposy = 0
        estposx = sum(self.weights*self.particles[:,0])
        estposy = sum(self.weights*self.particles[:,1])
        
        return(estposx,estposy)
        
    def resample(self):
        """
        Resamples the particles to avoid particle degeneracy
        """
        cumulativeSum = np.cumsum(self.weights)
        cumulativeSum[-1] = 1.0
        
        randoms = [0]*self.N
        for i in range(self.N):
            randoms[i] = r.random()
        indexes = np.searchsorted(cumulativeSum, randoms)
        self.particles = self.particles[indexes]
        self.weights = self.weights[indexes]
        self.weights /= sum(self.weights)
        