import numpy as np

class KalmanFilter():
    def __init__(self, xInit, yInit, initPosError, sigmaSensor):
        #Prediction Space
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
                           [0,0,0,1]])
        
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
        
        #Update
    
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
                           [0,dt,0,1]])