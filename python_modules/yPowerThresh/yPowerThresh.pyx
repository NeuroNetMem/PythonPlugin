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
                self.freq = 100
                self.prevMax = 0

                # Wait 100 milliseconds between peaks(remove long lasting peaks counting mulitple times)
                self.waitTime = 100
                self.curWait = 101
                self.f = open('C:\\Users\\Ephys\\Desktop\\buffersize.txt', 'w')
 
                self.buffer = pd.DataFrame()

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
                self.peaks = np.zeros(3)
                # Keep track of how long we've been creating our threshold
                self.threshTime = 0
                self.sampPerRev = self.fs / self.freq

                return self.Enabled
        def param_config(self):
                """return button, sliders, etc to be present in the editor OE side"""
                chanLabels = range(1, 33)
                freqIn = [8,20,40,80,100]
                #channel = {"int_set", "Active Channel", chanLabels}
                #self.activeChan = 0 # Create dropdown from activeChans?
                return [("int_set", "activeChan", chanLabels),("int_set", "freq", freqIn)]

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
                # Change from human readable to software channel
                chanIn = self.activeChan - 1

                # If still buidling threshold
                if self.threshTime < self.prelimLen:
                  nSamp = len(n_arr[chanIn][:])
                  wave = pd.DataFrame(n_arr[chanIn][:])
                  self.threshTime += nSamp / self.fs

                  # At least one full revolution in buffer
                  if nSamp > self.sampPerRev:
                    self.handlePeak(wave.max()[0])

                  # Fill a buffer until at least 1 full revolution
                  elif nSamp < self.sampPerRev:
                    self.f.write('filling' + '\n')
                    self.buffer = self.buffer.append(wave, ignore_index = True)
                    if self.buffer.size > self.sampPerRev:
                      self.f.write(self.buffer + '\n')
                      self.handlePeak(self.buffer.max()[0])
                      self.buffer = pd.DataFrame() # Create empty dataframe to append data to

                # Output threshold to selected channel
                else:
                  if self.f.closed==False:
                    self.f.close()
                  for i in range(len(n_arr[chanIn][:])):
                    n_arr[chanIn][i] = self.peaks[-1]

                return events
        def handleEvents(self,eventType,sourceID,subProcessorIdx,timestamp,sourceIndex):
                """handle events passed from OE"""
        def handleSpike(self, electrode, sortedID, n_arr):
                """handle spikes passed from OE"""
        def handlePeak(self, max):
                """handles peaks when creating threshold"""
                # If a max was found last buffer, check if this buffer's max is larger and only save one
                # Prevents a rising slope of the end of one buffer being counted a second time when it reaches its peak at the start of the next buffer
                if self.prevMax != 0:
                  if max > self.prevMax:
                    newMax = max
                  else:
                    newMax = self.prevMax
                  self.prevMax = 0
                  self.f.write(str(newMax) + '\n')
                  for i in range(len(self.peaks)): # Loop through peaks so we can insert the new peak into the correct place (Makes it sorted)
                    if newMax >= self.peaks[i]:
                      self.peaks = np.concatenate((self.peaks[:i], [newMax], self.peaks[i:])) # INSERT our new peak in its correct spot.
                      self.peaks = self.peaks[:-1].copy() # Remove the last (now unwanted peak), because everything was shifted when new peak was added
                      break
                  self.prevMax = 0 # Reset prevMax so we dont keep adding the same peak
                # If a max is found wait until next buffer to make sure it's the peak of the wave
                elif max > self.peaks[-1]:
                  self.prevMax = max


pluginOp = yPowerThresh()

include '../plugin.pyx'

'''
if self.curWait > self.waitTime:
  wave = pd.DataFrame(n_arr[chanIn][:])
  max = wave.max()
  self.f.write(str(n_arr[chanIn][0:29]) + "\n")
  if max[0] > self.peaks[-1]:
    for i in range(len(self.peaks)):
      if max[0] >= self.peaks[i]:
        self.peaks = np.concatenate((self.peaks[:i], [max[0]], self.peaks[i:]))
        self.peaks = self.peaks[:-1].copy()
        self.curWait = 0
        break
      else:
        self.curWait += len(n_arr[chanIn]) / self.fs * 1000
'''
