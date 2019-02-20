#Imports


class KalmanFilter():
    def __init__(self, identifier):
        #Variables and Constants
        self.identifier = identifier
        
        
    def filter(self, newMeasurement):
        """
        This function estimates the real position from a new measurement of the position
        """
        x,y = newMeasurement
        position = x+1, y+1
        return position