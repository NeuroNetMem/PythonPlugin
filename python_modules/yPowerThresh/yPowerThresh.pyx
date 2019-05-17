import sys
import numpy as np
cimport numpy as np
from cython cimport view
from scipy.signal import butter, lfilter, hilbert
import pandas as pd

isDebug = False

class yPowerThresh(object):
        def __init__(self):
                """initialize object data"""
                self.Enabled = 1
                self.mean = 0
                self.count = 0
                self.std = 0
                self.thresh = 0

                self.activeChan = 1

                # Wait 100 milliseconds between peaks(remove long lasting peaks counting mulitple times)
                self.waitTime = 100
                self.curWait = 101

        def startup(self, sr):
                """to be run upon startup"""
                self.fs = sr
                self.prelimLen = 1 * 10
                self.peaks = np.zeros(3)
                # Keep track of how long we've been creating our threshold
                self.threshTime = 0
        def plugin_name(self):
                """tells OE the name of the program"""
                return "yPowerThresh"
        def is_ready(self):
                """tells OE everything ran smoothly"""
                return self.Enabled
        def param_config(self):
                """return button, sliders, etc to be present in the editor OE side"""
                chanLabels = range(1, 33)
                #channel = {"int_set", "Active Channel", chanLabels}
                #self.activeChan = 0 # Create dropdown from activeChans?
                return [("int_set", "activeChan", chanLabels)]
        def bufferfunction(self, n_arr):
                """Access to voltage data buffer. Returns events"""
                events = []
                chanIn = self.activeChan - 1

                if self.threshTime < self.prelimLen:
                  self.threshTime += len(n_arr[chanIn]) / self.fs
                  if self.curWait > self.waitTime:
                    wave = pd.DataFrame(n_arr[chanIn][:])
                    # wave = band(n_arr[self.activeChan][:], 80, 200, self.fs)
                    # hilbertData = hilbert(wave)
                    # hilbertDF = pd.DataFrame(hilbertData)
                    # hilbertDF = hilbertDF.abs()
                    # hilbertDF = hilbertDF.pow(2)
                    max = wave.max()
                    if max[0] > self.peaks[-1]:
                      for i in range(len(self.peaks)):
                        if max[0] >= self.peaks[i]:
                          self.peaks = np.concatenate((self.peaks[:i], [max[0]], self.peaks[i:]))
                          self.peaks = self.peaks[:-1].copy()
                          self.curWait = 0
                          break

                    #self.mean = self.mean * (self.count - 1) / self.count + hilbertDF.mean() / self.count
                    #self.std = self.std * (self.count - 1) / self.count + hilbertDF.std() / self.count
                    #self.count += 1
                  else:
                    self.curWait += len(n_arr[chanIn]) / self.fs * 1000
                else:
                  for i in range(len(n_arr[chanIn])):
                    n_arr[chanIn][i] = self.peaks[-1]

                return events
        def handleEvents(eventType,sourceID,subProcessorIdx,timestamp,sourceIndex):
                """handle events passed from OE"""
        def handleSpike(self, electrode, sortedID, n_arr):
                """handle spikes passed from OE"""

pluginOp = yPowerThresh()

include '../plugin.pyx'
