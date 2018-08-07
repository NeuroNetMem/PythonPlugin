import sys
import numpy as np
cimport numpy as np
from cython cimport view

from sklearn.decomposition import IncrementalPCA

isDebug = False


class testML(object):
    def __init__(self):
        self.Enabled = 1
        self.chan_in = 0
        self.thresh_min = -2
        self.thresh_max = 2
        self.thresh_start = 0
        self.threshold = self.thresh_start
        self.arduino = None
        self.ipca = IncrementalPCA(n_components=2, batch_size=1)


        self.triggered = 0


    def startup(self, sr):
        self.samplingRate = sr
        print (self.samplingRate)
        print ("Arduino: ", self.arduino)
        self.enabled = 1

    def plugin_name(self):
        return "testML"

    def is_ready(self):
        return 1

    def param_config(self):
        chan_labels = list(range(1,44))

        return (("toggle", "Enabled", True),
                ("int_set", "chan_in", chan_labels),
                ("float_range", "threshold", self.thresh_min, self.thresh_max, self.thresh_start))


    def bufferfunction(self, n_arr):
        #print ("plugin start")
        events = []
        cdef int chan_in
        cdef int chan_out
        chan_in = self.chan_in
        cdef int n_samples = n_arr.shape[1]

        if np.any(n_arr[chan_in-1,:] > self.threshold):
            if not self.triggered:
                #print ('triggered')
                events.append({'type': 3, 'sampleNum': 10, 'eventId': 1})
                self.triggered = 1
                #n_arr[chan_in-2,:] = 1 * np.ones((1,n_samples))
        elif self.triggered:
            self.triggered = 0
            events.append({'type': 3, 'sampleNum': 10, 'eventId': 5})
            #n_arr[chan_in-2,:] = np.zeros((1,n_samples))
        else:
            pass
            # n_arr[chan_in-2,:] = np.zeros((1,n_samples))
        
        return events    

    def handleEvents(eventType,sourceID,subProcessorIdx,timestamp,sourceIndex):
        print("hi from handle event")
	 
    def handleSpike(self,sortedID, n_arr):
        self.ipca.partial_fit(n_arr.reshape(1,-1))
        X_ipca = self.transform(n_arr.reshape(1,-1))
        print(X_ipca)

pluginOp = testML()

include "../plugin.pyx"

