"""
Kalman.py
Oscar Johansson, Lucas Wassénius
This is the class for the Kalman filter. It is supplied with an initial guess of the position, the maximum error of this position,
the standard deviation of the sensor measurements and a coefficient for the system noise covariance matrix. New measurements
is continouosly fed to the filter function and the filtered values are returned.
"""

import numpy as np

class KalmanFilter():
    def __init__(self, xInit, yInit, initPosError, sigmaSensor,coeff):
        #Prediction Space
        self.phi = coeff
        self.x = np.array([[xInit],
                      [yInit],
                      [0],
                      [0]])
        self.F = np.array([[1,0,0,0],
                           [0,1,0,0],
                           [0,0,1,0],
                           [0,0,0,1]])
        self.P = np.array([[(initPosError/3)**2,0,0,0],
                           [0,(initPosError/3)**2,0,0],
                           [0,0,0,0],
                           [0,0,0,0]])
        self.Q = np.array([[0,0,0,0],
                           [0,0,0,0],
                           [0,0,1,0],
                           [0,0,0,1]])*self.phi
        
        #Measurement Space
        self.z = np.array([[0],
                          [0]])
        self.H = np.array([[1,0,0,0],
                           [0,1,0,0]])
        self.R = np.array([[sigmaSensor**2, 0],
                           [0, sigmaSensor**2]])
        
        
    def filter(self, newMeasurement, dt):
        """
        This function performs the filter algorithm for a new measurement with timestep dt
        """
        #Adjust the matrices for the timestep of the measurement
        self.adjustMatrices(dt)
        
        #Save the measurement in the observe matrix
        Px,Py = newMeasurement
        self.z = np.array([[Px],
                          [Py]])
        
        #Prediction
        self.x = self.F.dot(self.x)
        self.P = self.F.dot(self.P).dot(self.F.T) + self.Q
        
        #Update
        y = self.z - self.H.dot(self.x)
        S = self.R + self.H.dot(self.P).dot(self.H.T)
        K = self.P.dot(self.H.T).dot(np.linalg.inv(S))
        self.x = self.x + K.dot(y)
        self.P = (np.identity(4) - K.dot(self.H)).dot(self.P).dot((np.identity(4) - K.dot(self.H)).T) + K.dot(self.R).dot(K.T)
        
        return (self.x[0].item(0),self.x[1].item(0))
    
    def adjustMatrices(self, dt):
        """
        This function adjust the values in the state transition matrix and covariance matrix for the
        current timestep
        """
        self.F = np.array([[1,0,dt,0],
                           [0,1,0,dt],
                           [0,0,1,0],
                           [0,0,0,1]])
        self.Q = np.array([[dt**2,0,dt,0],
                           [0,dt**2,0,dt],
                           [dt,0,1,0],
                           [0,dt,0,1]])*self.phi