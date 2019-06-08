# cython: language_level=3
import sys
import numpy as np
cimport numpy as np
from cython cimport view

isDebug = False

class test2(object):
        def __init__(self):
                """initialize object data"""
                self.Enabled = 1
                self.samplingRate = 0.
                self.chan_enabled = []

        def startup(self, nchans, srate, states):
                """to be run upon startup"""
                self.update_settings(nchans, srate)
                for chan in range(nchans):
                        if not states[chan]:
                                self.channel_changed(chan, False)

        def plugin_name(self):
                """tells OE the name of the program"""
                return "test2"

        def is_ready(self):
                """tells OE everything ran smoothly"""
                return self.Enabled

        def param_config(self):
                """return button, sliders, etc to be present in the editor OE side"""
                return []

        def update_settings(self, nchans, srate):
                """handle changing number of channels and sample rates"""
                self.samplingRate = srate

                old_nchans = len(self.chan_enabled)
                if old_nchans > nchans:
                        del self.chan_enabled[nchans:]

                elif len(self.chan_enabled) < nchans:
                        self.chan_enabled.extend([True] * (nchans - old_nchans))

        def channel_changed(self, chan, state):
                """do something when channels are turned on or off in PARAMS tab"""
                self.chan_enabled[chan] = state

        def bufferfunction(self, n_arr):
                """Access to voltage data buffer. Returns events""" 
                events = []
                return events

        def handleEvents(self, eventType,sourceID,subProcessorIdx,timestamp,sourceIndex):
                """handle events passed from OE"""

        def handleSpike(self, electrode, sortedID, n_arr):
                """handle spikes passed from OE"""


pluginOp = test2()

include '../plugin.pyx'



