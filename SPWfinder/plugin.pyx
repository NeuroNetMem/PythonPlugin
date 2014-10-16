import sys
import numpy as np
cimport numpy as np
from cython cimport view

# try:
#     import scipy.signal
# except ImportError as detail:
#     print "couldn't import scipy ", detail

print "ciao"
import scipy.signal
print "sono io"
from libc.stdlib cimport malloc, calloc





cdef extern from "../../Source/Processors/PythonParamConfig.h":
    enum paramType:
        TOGGLE, INT_SET, FLOAT_RANGE


# struct ParamConfig {
#     paramType type;
#     char name[255];
#     int isEnabled;
# };

cdef extern from "../../Source/Processors/PythonParamConfig.h":
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


cdef extern from "../../Source/Processors/PythonEvent.h":
    struct PythonEvent:
        unsigned char type
        int sampleNum
        unsigned char eventId
        unsigned char eventChannel
        unsigned char numBytes
        unsigned char *eventData
        PythonEvent *nextEvent

class SPWFinder(object):
    def __init__(self):
        self.enabled = 1
        self.chan_in = 0
        self.chan_ripples = 1
        self.band_lo_min = 50
        self.band_lo_max = 200
        self.band_lo_start = 100
        self.band_lo = self.band_lo_start

        self.band_hi_min = 100
        self.band_hi_max = 500
        self.band_hi_start = 300
        self.band_hi = self.band_hi_start

        self.samplingRate = 0.
        self.polarity = 0

        self.filter_a = []
        self.filter_b = []

    def startup(self, sr):
        self.samplingRate = sr
        print self.samplingRate
        # self.filter_b, self_filter_a = signal.butter(3,
        #                      (self.band_lo/(self.samplingRate/2), self.band_hi/(self.samplingRate/2)),
        #                      'pass')
        self.enabled = 1

    def plugin_name(self):
        return "SPWFinder"

    def is_ready(self):
        return 1

    def param_config(self):
        chan_labels = range(16)
        return (("toggle", "Enabled", True),
                ("int_set", "chan_in", chan_labels),
                ("int_set", "chan_ripples", chan_labels),
                ("float_range", "band_lo", self.band_lo_min, self.band_lo_max, self.band_lo_start),
                ("float_range", "band_hi", self.band_hi_min, self.band_hi_max, self.band_hi_start))
        # return (("toggle", "enabled" , True),
        #         ("int_set", "channel", chan_labels),
        #         ("float_range", "mult", self.range_min, self.range_max, self.start_value))

    def bufferfunction(self, n_arr):
        #print "plugin start"
        events = []
        cdef int chan_in
        cdef int chan_out
        chan_in = self.chan_in
        chan_out = self.chan_ripples

        # n_arr[chan_out,:] = signal.filtfilt(self.filter_b, self.filter_a, n_arr[chan_in,:])

        #print "plugin end"
        return events


pluginOp = SPWFinder()

############## here starts the C++ interface


cdef public void pluginStartup(float samplingRate):
    print "executable is", sys.executable
#    print "signal is", scipy.signal
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
    n_arr = np.asarray(<np.float32_t[:nChans, :nSamples]> buffer)
    #pluginOp.set_events(events)
    #pm2 = PluginModule(pm)
    events_to_add = pluginOp.bufferfunction(n_arr)

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