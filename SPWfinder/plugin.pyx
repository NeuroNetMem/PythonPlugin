import sys
import numpy as np
cimport numpy as np
from cython cimport view
import serial


import scipy.signal
import math
import numpy.random
from libc.stdlib cimport malloc, calloc





cdef extern from "../../Source/Processors/PythonProcessor/PythonParamConfig.h":
    enum paramType:
        TOGGLE, INT_SET, FLOAT_RANGE


# struct ParamConfig {
#     paramType type;
#     char name[255];
#     int isEnabled;
# };

cdef extern from "../../Source/Processors/PythonProcessor/PythonParamConfig.h":
    struct ParamConfig:
        paramType type
        char *name
        int isEnabled
        int nEntries
        int *entries
        float rangeMin
        float rangeMax
        float startValue


# struct PythonEvent {
#     unsigned char type;
#     int sampleNum;
#     unsigned char eventId;
#     unsigned char eventChannel;
#     unsigned char numBytes;
#     unsigned char *eventData;
#     struct PythonEvent *nextEvent
# };


cdef extern from "../../Source/Processors/PythonProcessor/PythonEvent.h":
    struct PythonEvent:
        unsigned char type
        int sampleNum
        unsigned char eventId
        unsigned char eventChannel
        unsigned char numBytes
        unsigned char *eventData
        PythonEvent *nextEvent


########### plugin starts here

class SPWFinder(object):
    def __init__(self):
        self.enabled = True
        self.jitter = False
        self.jitter_count_down = -2
        self.jitter_time = 200. # in ms
        self.chan_in = 0
        self.chan_ripples = 1
        self.band_lo_min = 50.
        self.band_lo_max = 200.
        self.band_lo_start = 100.
        self.band_lo = self.band_lo_start

        self.band_hi_min = 100.
        self.band_hi_max = 500.
        self.band_hi_start = 300.
        self.band_hi = self.band_hi_start

        self.thresh_min = 20.
        self.thresh_max = 200.
        self.thresh_start = 30.
        self.threshold = self.thresh_start

        self.pulseNo = 0
        self.triggered = 0
        self.samplingRate = 0.
        self.polarity = 0
        self.filter_a = []
        self.filter_b = []
        self.arduino = None
        self.lfp_buffer = np.zeros((500,))
        print "finished SPWfinder constructor"

    def startup(self, samplingRate):
        self.samplingRate = samplingRate
        print self.samplingRate

        self.filter_b, self.filter_a = scipy.signal.butter(3,
                                                     (self.band_lo/(self.samplingRate/2), self.band_hi/(self.samplingRate/2)),
                                                     'pass')
        print self.filter_a
        print self.filter_b
        print self.band_lo
        print self.band_hi
        print self.band_lo/(self.samplingRate/2)
        print self.band_hi/(self.samplingRate/2)
        self.enabled = 1
        self.jitter = 0
        try:
            self.arduino = serial.Serial('/dev/tty.usbmodem1411', 57600)
        except OSError, serial.serialutil.SerialException:
            print "Can't open Arduino"

    def plugin_name(self):
        return "SPWFinder"

    def is_ready(self):
        return 1

    def param_config(self):
        chan_labels = range(16)
        # return (("toggle", "Enabled", True),
        #         ("int_set", "chan_in", chan_labels),
        #         ("int_set", "chan_ripples", chan_labels),
        #         ("float_range", "band_lo", self.band_lo_min, self.band_lo_max, self.band_lo_start),
        #         ("float_range", "band_hi", self.band_hi_min, self.band_hi_max, self.band_hi_start))
        return (("toggle", "enabled", True),
                ("toggle", "jitter", False),
                ("int_set", "chan_in", chan_labels),
                ("float_range", "threshold", self.thresh_min, self.thresh_max, self.thresh_start))


    def bufferfunction(self, n_arr):
        #print "plugin start"

        print "shape: ", n_arr.shape
        events = []
        cdef int chan_in
        cdef int chan_out
        chan_in = self.chan_in
        chan_out = self.chan_ripples

        cdef int n_samples = n_arr.shape[1]
        signal_to_filter = np.hstack((self.lfp_buffer, n_arr[chan_in,:]))
        signal_to_filter = signal_to_filter - signal_to_filter[-1]
        filtered_signal = scipy.signal.lfilter(self.filter_b, self.filter_a, signal_to_filter)

        n_arr[chan_out,:] = filtered_signal[self.lfp_buffer.size:]
        self.lfp_buffer = n_arr[chan_in,:]
        n_arr[chan_out+1,:] = np.fabs(n_arr[chan_out,:])
        n_arr[chan_out+2,:] = 5. *np.mean(n_arr[chan_out+1,:]) * np.ones((1,n_samples))
        print "done processing"
        if not self.enabled:
            if np.mean(n_arr[chan_out+1,:]) > self.threshold:
                events.append({'type': 3, 'sampleNum': n_samples-1, 'eventId': 3})
                self.triggered = 1
            elif self.triggered:
                self.triggered = 0
                events.append({'type': 3, 'sampleNum': n_samples-1, 'eventId': 5})
        else:
            if np.mean(n_arr[chan_out+1,:]) > self.threshold and not self.triggered:
                self.triggered = 1
                if not self.jitter:
                    events.append({'type': 3, 'sampleNum': n_samples-1, 'eventId': 1})
                    try:
                        self.arduino.write('1' )
                    except AttributeError:
                        print "Can't send pulse"
                    self.pulseNo += 1
                    print "generating pulse ", self.pulseNo
                else:
                    events.append({'type': 3, 'sampleNum': n_samples-1, 'eventId': 4})
                    frame_time = 1000. * n_samples / self.samplingRate
                    self.jitter_count_down = int(self.jitter_time / frame_time)
            elif np.mean(n_arr[chan_out+1,:]) > self.threshold and  self.triggered:
                pass
            elif self.triggered:
                self.triggered = 0
                events.append({'type': 3, 'sampleNum': n_samples-1, 'eventId': 5})

            if self.jitter and self.jitter_count_down == -1:
                events = [{'type': 3, 'sampleNum': n_samples-1, 'eventId': 5},] # close the 1 event
                # FIXME apparently it bombs if more evnets are generated in the same frame!!!
                self.jitter_count_down = -2


            if self.jitter and self.jitter_count_down >= 0:
                if self.jitter_count_down == 0:
                    events.append({'type': 3, 'sampleNum': n_samples-1, 'eventId': 1})
                    try:
                        self.arduino.write('1'* 64)
                    except AttributeError:
                        print "Can't send pulse"
                    self.pulseNo += 1
                    print "generating pulse ", self.pulseNo
                    self.jitter_count_down = -1
                else:
                    self.jitter_count_down -= 1


        return events


pluginOp = SPWFinder()
sr = 1.
############## here starts the C++ interface


cdef public void pluginStartup(float samplingRate):
    global sr
    #import scipy.signal
    #import PIL
    #print "executable is", sys.executable
#    print "signal is", scipy.signal
    print "path is"
    print sys.path
    sr = samplingRate
    pluginOp.startup(sr)

cdef public int getParamNum():
    return len(pluginOp.param_config())

cdef public void getParamConfig(ParamConfig *params):
    cdef int *ent
    ppc = pluginOp.param_config()
    for i in range(len(ppc)):
        par = ppc[i]
        if par[0] == "toggle":
            params[i].type = TOGGLE
            params[i].name = par[1]
            params[i].isEnabled = par[2]
        elif par[0] == "int_set":
            params[i].type = INT_SET
            params[i].name = par[1]
            params[i].nEntries = len(par[2])
            ent = <int *> malloc (sizeof (int) * len(par[2]) )
            for k in range(len(par[2])):
                ent[k] = par[2][k]
            params[i].entries = ent
        elif par[0] == "float_range":
            params[i].type = FLOAT_RANGE
            params[i].name = par[1]
            params[i].rangeMin = par[2]
            params[i].rangeMax = par[3]
            params[i].startValue = par[4]



cdef public void pluginFunction(float *buffer, int nChans, int nSamples, PythonEvent *events):
    global sr
    n_arr = np.asarray(<np.float32_t[:nChans, :nSamples]> buffer)
    #pluginOp.set_events(events)
    #pm2 = PluginModule(pm)

    print "sr: ", sr
    samples_to_read = int(nSamples * sr / 44100.)
    events_to_add = pluginOp.bufferfunction(n_arr[:,0:samples_to_read])

        # struct PythonEvent:
        # unsigned char type
        # int sampleNum
        # unsigned char eventId
        # unsigned char eventChannel
        # unsigned char numBytes
        # unsigned char *eventData
        # PythonEvent *nextEvent
    if len(events_to_add) > 0:
        e_py = events_to_add[0]
        e_c = events
        add_event(e_c, e_py)
        print "in Plugin, event ", e_c.eventId, " added"
        last_e_c = e_c
        for i in range(1,len(events_to_add)):
            e_py = events_to_add[i]
            e_c = <PythonEvent *>calloc(1, sizeof(PythonEvent))
            print "in Plugin, event ", e_c.eventId, " added"
            last_e_c.nextEvent = e_c
            add_event(e_c, e_py)
            last_e_c = e_c

cdef void add_event(PythonEvent *e_c, object e_py):
    e_c.type = <unsigned char>e_py['type']
    e_c.sampleNum = <int>e_py['sampleNum']
    if 'eventId' in e_py:
        e_c.eventId = <unsigned char>e_py['eventId']
    if 'eventChannel' in e_py:
        e_c.eventChannel = <unsigned char>e_py['eventChannel']
    if 'numBytes' in e_py:
        e_c.numBytes = <unsigned char>e_py['numBytes']
    if 'eventData' in e_py:
        e_c.eventData = <unsigned char *>e_py['eventData'] #TODO this leaves the brunt of converting to a uint8 pointer to the plugin module
        # it will be desirable to have this expressed as a numpy array so that we don't need to have C pointers in the plugin necessarily

cdef public int pluginisready():
    return pluginOp.is_ready()

cdef public void setIntParam(char *name, int value):
    print "In Python: ", name, ": ", value
    setattr(pluginOp, name, value)

cdef public void setFloatParam(char *name, float value):
    # print "In Python: ", name, ": ", value
    setattr(pluginOp, name, value)