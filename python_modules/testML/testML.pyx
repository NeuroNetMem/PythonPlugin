import sys
import numpy as np
cimport numpy as np
from cython cimport view
import zmq
import _pickle as pickle
from sklearn.decomposition import IncrementalPCA

isDebug = False

class testML(object):
        def __init__(self):
                """initialize object data"""
                self.Enabled = 1
                self.chan_in = 0
                self.ipca = IncrementalPCA(n_components=2, batch_size=18)
                self.spikeSampleBuffer = np.zeros([2,18]) #spike, samples
                self.electrodeBuffer = np.zeros([2,1])
                self.thresh = -70
                self.spikeSampleBufferCounter = 0
                self.f = open('testPoints.csv','a+')
                self.bind_to = "5556"
                self.topic = "10001"
                self.ctx = zmq.Context()
                self.s = self.ctx.socket(zmq.PUB)
                self.s.bind("tcp://*:%s" % self.bind_to)
                self.enabled = 1;
        def startup(self, sr):
                """to be run upon startup"""
                self.samplingRate = sr
        def plugin_name(self):
                """tells OE the name of the program"""
                return "testML"
        def is_ready(self):
                """tells OE everything ran smoothly"""
                return self.Enabled
        def param_config(self):
                """return button, sliders, etc to be present in the editor OE side"""
                return []
        def bufferfunction(self, n_arr):
                """Access to voltage data buffer. Returns events""" 
                events = []
                return events
        def handleEvents(eventType,sourceID,subProcessorIdx,timestamp,sourceIndex):
                """handle events passed from OE"""
        def handleSpike(self, electrode, sortedID, n_arr):
                """handle spikes passed from OE"""
                if np.min(n_arr) < self.thresh:
                    #print(electrode)
                    self.spikeSampleBuffer[self.spikeSampleBufferCounter,:] = n_arr
                    self.electrodeBuffer[self.spikeSampleBufferCounter] = electrode
                    self.spikeSampleBufferCounter = self.spikeSampleBufferCounter + 1
                    if (self.spikeSampleBufferCounter > 1):
                        self.ipca.partial_fit(self.spikeSampleBuffer[:,:])
                        print(self.ipca.get_covariance())
                        data = np.zeros([2,4])
                        data[:,0:4] = self.ipca.transform(self.spikeSampleBuffer[:,:])
                        data[0,1] = self.electrodeBuffer[0]
                        data[0,2] = self.electrodeBuffer[1]
                        #self.f.write(formatPCA(data))
                        self.spikeSampleBuffer = np.zeros([2,18]) #spike, samples
                        self.electrodeBuffer = np.zeros([2,1])
                        self.spikeSampleBufferCounter = 0
                        self.send("5556",data)
        def send(self,bind_to,data):
            #print("sending...")
            print(data)
            self.s.send_pyobj(pickle.dumps(data))
            #print("sent!")

def formatPCA(data):
    dataStr = ''
    for i in range(0,2):
        dataStr = dataStr + str(data[i,0]) + ',' + str(data[i,1]) + '\n'
    return dataStr

pluginOp = testML()

include '../plugin.pyx'



