import sys
import numpy as np
import zmq
import _pickle as pickle
cimport numpy as np
from cython cimport view

from sklearn.decomposition import IncrementalPCA

isDebug = False


class testML(object):
    def __init__(self):
        self.Enabled = 1
        self.chan_in = 0
        self.ipca = IncrementalPCA(n_components=2, batch_size=18)
        self.spikeSampleBuffer = np.zeros([18,18]) #spike, samples
        self.spikeSampleBufferCounter = 0
        self.f = open('testPoints.csv','a+')
        self.bind_to = "5556"
        self.topic = "10001"
        self.ctx = zmq.Context()
        self.s = self.ctx.socket(zmq.PUB)
        self.s.bind("tcp://*:%s" % self.bind_to)

    def startup(self, sr):
        self.samplingRate = sr
        print (self.samplingRate)
        self.enabled = 1

    def plugin_name(self):
        return "testML"

    def is_ready(self):
        return 1

    def param_config(self):
        #chan_labels = list(range(1,44))
        #return (("toggle", "Enabled", True),
        #        ("int_set", "chan_in", chan_labels),
        #        ("float_range", "threshold", self.thresh_min, self.thresh_max, self.thresh_start))
        return []

    def bufferfunction(self, n_arr):
        #print ("plugin start")
        events = []
        return events    

    def handleEvents(eventType,sourceID,subProcessorIdx,timestamp,sourceIndex):
        print("hi from handle event")

    def handleSpike(self, electrode, sortedID, n_arr):
        #print(self.spikeSampleBufferCounter)
        if electrode == 1 and np.min(n_arr) < -70:
            #print(electrode)
            self.spikeSampleBuffer[self.spikeSampleBufferCounter,:] = n_arr
            self.spikeSampleBufferCounter = self.spikeSampleBufferCounter + 1
            if (self.spikeSampleBufferCounter > 17):
                    self.ipca.partial_fit(self.spikeSampleBuffer[:,:])
                    data = self.ipca.transform(self.spikeSampleBuffer[:,:])
                    self.f.write(formatPCA(data))
                    #print(formatPCA(data))               
                    self.spikeSampleBuffer = np.zeros([18,18]) #spike, samples
                    self.spikeSampleBufferCounter = 0
                    print("presend")
                    self.send("5556",data)
                    print("post send")

    def send(self,bind_to,data):
        print("sending...")
        print(data)
        self.s.send_pyobj(pickle.dumps(data))
        print("sent!")

def formatPCA(data):
    dataStr = ''
    for i in range(0,18):
        dataStr = dataStr + str(data[i,0]) + ',' + str(data[i,1]) + '\n'
    return dataStr


pluginOp = testML()

include "../plugin.pyx"

