import sys
import numpy as np
cimport numpy as np
from cython cimport view

isDebug = False

class testPrint(object):
        def __init__(self):
                """initialize object data"""
                print('hello world_init\n\n')
                self.Enabled = 1
        def startup(self, sr):
                """to be run upon startup"""
                print('hello world_startup\n\n')
        def plugin_name(self):
                """tells OE the name of the program"""
                print('hello world_name\n\n')
                return "testPrint"
        def is_ready(self):
                """tells OE everything ran smoothly"""
                print('hello world_is_ready\n\n')
                return self.Enabled
        def param_config(self):
                """return button, sliders, etc to be present in the editor OE side"""
                return []
        def bufferfunction(self, n_arr):
                """Access to voltage data buffer. Returns events"""
                print('hello world_buffer\n\n')
                events = []
                return events
        def handleEvents(eventType,sourceID,subProcessorIdx,timestamp,sourceIndex):
                print('hello world_handle_events\n\n')
                """handle events passed from OE"""
        def handleSpike(self, electrode, sortedID, n_arr):
                print('hello world_handle_spike\n\n')
                """handle spikes passed from OE"""


pluginOp = testPrint()

include '../plugin.pyx'
