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

                self.activeChan = 0
                self.peaks = np.zeros(12)

                # Wait 100 milliseconds between peaks(remove long lasting peaks counting mulitple times)
                self.waitTime = 100
                self.curWait = 101

                # Keep track of how long we've been creating our threshold
                self.threshTime = 0
        def startup(self, sr):
                """to be run upon startup"""
                self.fs = sr
                self.prelimLen = 3 * 60 * sr

        def plugin_name(self):
                """tells OE the name of the program"""
                return "yPowerThresh"
        def is_ready(self):
                """tells OE everything ran smoothly"""
                return self.Enabled
        def param_config(self):
                """return button, sliders, etc to be present in the editor OE side"""
                self.activeChan = 0 # Create dropdown from activeChans?
                return []
        def bufferfunction(self, n_arr):
                """Access to voltage data buffer. Returns events"""
                events = []

                if self.threshTime < self.prelimLen:
                  if self.curWait > self.waitTime:
                    wave = band(n_arr[self.activeChan][:], 80, 200, self.fs)
                    hilbertData = hilbert(wave)
                    hilbertDF = pd.DataFrame(hilbertData)
                    hilbertDF = hilbertDF.abs()
                    hilbertDF = hilbertDF.pow(2)
                    max = hilbertDF.max()

                    if max > self.peaks[-1]:
                      for i in range(len(self.peaks)):
                        if max >= self.peaks[i]:
                          np.concatenate(self.peaks[:i], [max], self.peaks[i:])
                          self.peaks = self.peaks[:-1].copy()
                          self.curWait = 0


                    #self.mean = self.mean * (self.count - 1) / self.count + hilbertDF.mean() / self.count
                    #self.std = self.std * (self.count - 1) / self.count + hilbertDF.std() / self.count
                    #self.count += 1
                  else:
                    self.curWait += len(n_arr[self.activeChan]) / self.fs * 1000
                else:
                  events.append(self.peaks[-1])

                return events
        def handleEvents(eventType,sourceID,subProcessorIdx,timestamp,sourceIndex):
                """handle events passed from OE"""
        def handleSpike(self, electrode, sortedID, n_arr):
                """handle spikes passed from OE"""

def butter_bandpass(lowcut, highcut, fs, order=5):
    nyq = 0.5 * fs
    low = lowcut / nyq
    high = highcut / nyq
    b, a = butter(order, [low, high], btype='band')
    return b, a

def band(data, low, high, fs):
  b, a = butter_bandpass(low, high, fs, order=order)
  y = lfilter(b, a, data)
  return y


pluginOp = yPowerThresh()

include '../plugin.pyx'
