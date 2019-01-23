import sys
import numpy as np
cimport numpy as np
from cython cimport view

isDebug = False

class test(object):
        def __init__(self):
                """initialize object data"""
                self.Enabled = 1
                self.thresh = -60
        def startup(self, sr):
                """to be run upon startup"""
        def plugin_name(self):
                """tells OE the name of the program"""
                return "test"
        def is_ready(self):
                """tells OE everything ran smoothly"""
                return self.Enabled
        def param_config(self):
                """return button, sliders, etc to be present in the editor OE side"""
        def bufferfunction(self, n_arr):
                """Access to voltage data buffer. Returns events""" 
                events = []
                min = np.min(n_arr[12][:])
                if min < self.thresh:
                    events.append({'type': 3, 'sampleNum': 10, 'eventId': 1})
                    print(events)
                return events
        def handleEvents(eventType,sourceID,subProcessorIdx,timestamp,sourceIndex):
                """handle events passed from OE"""
        def handleSpike(self, electrode, sortedID, n_arr):
                """handle spikes passed from OE"""


pluginOp = test()

include '../plugin.pyx'



