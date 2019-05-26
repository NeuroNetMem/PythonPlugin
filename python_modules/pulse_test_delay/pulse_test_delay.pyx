# noinspection PyUnresolvedReferences
import numpy as np
# noinspection PyUnresolvedReferences
cimport numpy as np
# noinspection PyUnresolvedReferences
from cython cimport view
import serial

isDebug = False


# noinspection PyPep8Naming
class pulse_test_delay(object):
    def __init__(self):
        """initialize object data"""
        self.Enabled = 1
        self.chan_in = 0
        self.thresh_min = -2
        self.thresh_max = 2
        self.thresh_start = 0
        self.threshold = self.thresh_start
        self.arduino = None
        self.triggered = 0
        self.samplingRate = 0

    def startup(self, sr):
        """to be run upon startup"""
        self.samplingRate = sr
        print (self.samplingRate)
        self.arduino = serial.Serial('/dev/tty.usbmodem45561', 57600)
        print ("Arduino: ", self.arduino)
        self.Enabled = 1

    def plugin_name(self):
        """tells OE the name of the program"""
        return "pulse_test_delay"

    def is_ready(self):
        """tells OE everything ran smoothly"""
        return self.Enabled

    def param_config(self):
        """return button, sliders, etc to be present in the editor OE side"""
        chan_labels = list(range(1,44))

        return (("toggle", "Enabled", True),
                ("int_set", "chan_in", chan_labels),
                ("float_range", "threshold", self.thresh_min, self.thresh_max, self.thresh_start))

    def bufferfunction(self, n_arr):
        """Access to voltage data buffer. Returns events"""
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
                try:
                    self.arduino.write(b'1')
                except AttributeError:
                    print("Can't send pulse")

        elif self.triggered:
            self.triggered = 0
            events.append({'type': 3, 'sampleNum': 10, 'eventId': 5})
            #n_arr[chan_in-2,:] = np.zeros((1,n_samples))
        else:
            pass
            # n_arr[chan_in-2,:] = np.zeros((1,n_samples))

        return events

    def handleEvents(self, eventType, sourceID, subProcessorIdx, timestamp, sourceIndex):
        """handle events passed from OE"""

    def handleSpike(self, electrode, sortedID, n_arr):
        """handle spikes passed from OE"""


pluginOp = pulse_test_delay()

include '../plugin.pyx'
