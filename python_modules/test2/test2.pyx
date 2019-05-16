# cython: language_level=3
import sys
import numpy as np
cimport numpy as np
from cython cimport view

isDebug = False

class test2(object):
        def __init__(self):
                print('hello from init\n\n')
                """initialize object data"""
                self.Enabled = 1
                self.threshMin = -100
                self.threshMax = 100
        def startup(self, sr):
                """to be run upon startup"""
                #self.samplingRate = sr
                print('start')
        def plugin_name(self):
                """tells OE the name of the program"""
                return "test2"
        def is_ready(self):
                """tells OE everything ran smoothly"""
                return self.Enabled
        def param_config(self):
                """return button, sliders, etc to be present in the editor OE side"""
                thresholdMin = ("float_range", "threshold min", self.threshMin, self.threshMax, 50)
                thresholdMax = ("float_range", "threshold max", self.threshMin, self.threshMax, -50)
                intMin = ("int_set", "int setting", [0,1,2,3,4])
                enable = ("toggle", "enabled", True)
                return [enable, intMin]
        def bufferfunction(self, n_arr):
                """Access to voltage data buffer. Returns events"""
                events = []
                return events
        def handleEvents(eventType,sourceID,subProcessorIdx,timestamp,sourceIndex):
                """handle events passed from OE"""
        def handleSpike(self, electrode, sortedID, n_arr):
                """handle spikes passed from OE"""


pluginOp = test2()

include '../plugin.pyx'
