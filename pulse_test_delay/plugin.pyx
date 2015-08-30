import sys
import numpy as np
cimport numpy as np

from cython cimport view
import serial



from libc.stdlib cimport malloc, calloc





cdef extern from "../../Source/Processors/PythonProcessor/PythonParamConfig.h":
    enum paramType:
        TOGGLE, INT_SET, FLOAT_RANGE




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




cdef extern from "../../Source/Processors/PythonProcessor/PythonEvent.h":
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
        self.thresh_min = -2
        self.thresh_max = 2
        self.thresh_start = 0
        self.threshold = self.thresh_start
        self.arduino = None


        self.triggered = 0


    def startup(self, sr):
        self.samplingRate = sr
        print self.samplingRate
        self.arduino = serial.Serial('/dev/tty.usbmodem45561', 57600)
        print "Arduino: ", self.arduino
        self.enabled = 1

    def plugin_name(self):
        return "pulse_test_delay"

    def is_ready(self):
        return 1

    def param_config(self):
        chan_labels = range(1,44)

        return (("toggle", "Enabled", True),
                ("int_set", "chan_in", chan_labels),
                ("float_range", "threshold", self.thresh_min, self.thresh_max, self.thresh_start))


    def bufferfunction(self, n_arr):
        #print "plugin start"
        events = []
        cdef int chan_in
        cdef int chan_out
        chan_in = self.chan_in
        cdef int n_samples = n_arr.shape[1]

        if np.any(n_arr[chan_in-1,:] > self.threshold):
            if not self.triggered:
                #print 'triggered'
                events.append({'type': 3, 'sampleNum': 10, 'eventId': 1})
                self.triggered = 1
                self.arduino.write('1')
                #n_arr[chan_in-2,:] = 1 * np.ones((1,n_samples))
        elif self.triggered:
            self.triggered = 0
            events.append({'type': 3, 'sampleNum': 10, 'eventId': 5})
            #n_arr[chan_in-2,:] = np.zeros((1,n_samples))
        else:
            pass
            # n_arr[chan_in-2,:] = np.zeros((1,n_samples))



        #print "plugin end"
        return events


pluginOp = SPWFinder()
isDebug = False

############## here starts the C++ interface


cdef public void pluginStartup(float samplingRate):
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



cdef public void pluginFunction(float *buffer, int nChans, int nSamples, PythonEvent *events) with gil:
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

cdef public int pluginisready():
    return pluginOp.is_ready()

cdef public void setIntParam(char *name, int value) with gil:
    print "In Python: ", name, ": ", value
    setattr(pluginOp, name, value)

cdef public void setFloatParam(char *name, float value) with gil:
    # print "In Python: ", name, ": ", value
    setattr(pluginOp, name, value)


cdef public int getIntParam(char *name) with gil:
    if isDebug:
        print "In Python getIntParam: ", name
    value = getattr(pluginOp, name)
    return <int>value

cdef public float getFloatParam(char *name) with gil:
    # print "In Python: ", name, ": ", value
    value =  getattr(pluginOp, name)
    return <float>value