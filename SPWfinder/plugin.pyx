import sys
import numpy as np
cimport numpy as np
from cython cimport view
import serial


import scipy.signal

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
        self.jitter_count_down_thresh = 0
        self.jitter_count_down = 0
        self.jitter_time = 200. # in ms
        self.refractory_count_down_thresh = 0
        self.refractory_count_down = 0
        self.refractory_time = 100. # time that the plugin will not react to trigger after one pulse
        self.chan_in = 0
        self.chan_out = 0
        self.n_samples = 0
        self.chan_ripples = 1
        self.band_lo_min = 50.
        self.band_lo_max = 200.
        self.band_lo_start = 100.
        self.band_lo = self.band_lo_start

        self.band_hi_min = 100.
        self.band_hi_max = 500.
        self.band_hi_start = 300.
        self.band_hi = self.band_hi_start

        self.thresh_min = 5.
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

        self.READY=1
        self.ARMED=2
        self.REFRACTORY=3
        self.FIRING = 4
        self.state = self.READY

        print "finished SPWfinder constructor"

    def startup(self, sampling_rate):
        self.samplingRate = sampling_rate
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

    def spw_condition(self, n_arr):
        return np.mean(n_arr[self.chan_out+1,:]) > self.threshold

    def stimulate(self):
        try:
            self.arduino.write('1'* 64)
        except AttributeError:
            print "Can't send pulse"
        self.pulseNo += 1
        print "generating pulse ", self.pulseNo

    def new_event(self, events, code, timestamp=None):
        if not timestamp:
            timestamp = self.n_samples
        events.append({'type': 3, 'sampleNum': timestamp, 'eventId': code})

    def bufferfunction(self, n_arr):
        #print "plugin start"
        if isDebug:
            print "shape: ", n_arr.shape
        events = []
        cdef int chan_in
        cdef int chan_out
        chan_in = self.chan_in
        self.chan_out = self.chan_ripples

        self.n_samples = int(n_arr.shape[1])

        frame_time = 1000. * self.n_samples / self.samplingRate
        self.jitter_count_down_thresh = int(self.jitter_time / frame_time)
        self.refractory_count_down_thresh = int(self.refractory_time / frame_time)
        signal_to_filter = np.hstack((self.lfp_buffer, n_arr[chan_in,:]))
        signal_to_filter = signal_to_filter - signal_to_filter[-1]
        filtered_signal = scipy.signal.lfilter(self.filter_b, self.filter_a, signal_to_filter)

        n_arr[self.chan_out,:] = filtered_signal[self.lfp_buffer.size:]
        self.lfp_buffer = n_arr[chan_in,:]
        n_arr[self.chan_out+1,:] = np.fabs(n_arr[self.chan_out,:])
        n_arr[self.chan_out+2,:] = 5. *np.mean(n_arr[self.chan_out+1,:]) * np.ones((1,self.n_samples))


        if isDebug:
            print "done processing"

        #events
        # 1: pulse sent
        # 2: jittered, pulse_sent
        # 3: triggered, not enabled
        # 4: trigger armed, jittered
        # 5: terminating pulse

        # machines:
        # ENABLED vs. DISABLED vs. JITTERED
        # states:
        # READY, REFRACTORY, ARMED, FIRING

        if not self.enabled:
            # DISABLED machine, has only READY state
            if self.spw_condition(n_arr):
                self.new_event(events, 3)
        elif not self.jitter:
            # ENABLED machine, has READY, REFRACTORY, FIRING states
            if self.state == self.READY:
                if self.spw_condition(n_arr):
                    self.stimulate()
                    self.new_event(events, 1)
                    self.state = self.FIRING
            elif self.state == self.FIRING:
                self.refractory_count_down = self.refractory_count_down_thresh-1
                self.state = self.REFRACTORY
                self.new_event(events, 5)
            elif self.state == self.REFRACTORY:
                self.refractory_count_down -= 1
                if self.refractory_count_down == 0:
                    self.state = self.READY
            else:
                # checking for a leftover ARMED state
                self.state = self.READY
        else:
            # JITTERED machine, has READY, ARMED, FIRING and REFRACTORY states
            if self.state == self.READY:
                if self.spw_condition(n_arr):
                    self.jitter_count_down = self.jitter_count_down_thresh
                    self.state = self.ARMED
                    self.new_event(events, 4)
            elif self.state == self.ARMED:
                self.jitter_count_down -= 1
                if self.jitter_count_down == 0:
                    self.stimulate()
                    self.new_event(events, 2)
                    self.state = self.FIRING
                    self.new_event(events, 1)
            elif self.state == self.FIRING:
                self.refractory_count_down = self.refractory_count_down_thresh-1
                self.state = self.REFRACTORY
                self.new_event(events, 5)
            else:
                self.refractory_count_down -= 1
                if self.refractory_count_down == 0:
                    self.state = self.READY

        return events


pluginOp = SPWFinder()
sr = 1.
isDebug = False
############## here starts the C++ interface


# noinspection PyPep8Naming
cdef public void pluginStartup(float sampling_rate) with gil:
    global sr
    #import scipy.signal
    #import PIL
    #print "executable is", sys.executable
#    print "signal is", scipy.signal
    if isDebug:
        print "The python path is"
        print sys.path
    sr = sampling_rate
    pluginOp.startup(sr)

# noinspection PyPep8Naming
cdef public int getParamNum()  with gil:
    return len(pluginOp.param_config())

# noinspection PyPep8Naming
cdef public void getParamConfig(ParamConfig *params) with gil:
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



# noinspection PyPep8Naming
cdef public void pluginFunction(float *data_buffer, int nChans, int nSamples, PythonEvent *events) with gil:
    global sr
    n_arr = np.asarray(<np.float32_t[:nChans, :nSamples]> data_buffer)
    #pluginOp.set_events(events)
    #pm2 = PluginModule(pm)

    if isDebug:
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
        if isDebug:
            print "in Plugin, event ", e_c.eventId, " added"
        last_e_c = e_c
        for i in range(1,len(events_to_add)):
            e_py = events_to_add[i]
            e_c = <PythonEvent *>calloc(1, sizeof(PythonEvent))
            if isDebug:
                print "in Plugin, event ", e_c.eventId, " added"
            last_e_c.nextEvent = e_c
            add_event(e_c, e_py)
            last_e_c = e_c
        last_e_c.nextEvent = NULL
        
cdef void add_event(PythonEvent *e_c, object e_py) with gil:
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

cdef public int pluginisready() with gil:
    return pluginOp.is_ready()

# noinspection PyPep8Naming
cdef public void setIntParam(char *name, int value) with gil:
    if isDebug:
        print "In Python: ", name, ": ", value
    setattr(pluginOp, name, value)

# noinspection PyPep8Naming
cdef public void setFloatParam(char *name, float value) with gil:
    # print "In Python: ", name, ": ", value
    setattr(pluginOp, name, value)

# noinspection PyPep8Naming
cdef public int getIntParam(char *name) with gil:
    if isDebug:
        print "In Python getIntParam: ", name
    value = getattr(pluginOp, name)
    return <int>value

# noinspection PyPep8Naming
cdef public float getFloatParam(char *name) with gil:
    # print "In Python: ", name, ": ", value
    value =  getattr(pluginOp, name)
    return <float>value