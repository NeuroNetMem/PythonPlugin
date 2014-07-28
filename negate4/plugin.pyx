cimport numpy as np
import numpy as np
from libc.stdlib cimport malloc

from cython cimport view


class Negate(object):


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

    def __init__(self):
        self.enabled = 1
        self.channel = 1
        self.mult = 1.
        self.range_min = 0.2
        self.range_max = 5
        self.start_value = 1
        self.idx = 1

    def startup(self):
        self.enabled = 1

    def plugin_name(self):
        return "Negate"

    def is_ready(self):
        return 1

    def param_config(self):
        chan_labels = range(16)
        return (("toggle", "enabled" , True),
                ("int_set", "channel", chan_labels),
                ("float_range", "mult", self.range_min, self.range_max, self.start_value))

    def bufferfunction(self, n_arr):
        #print "plugin start"
        cdef float mult
        cdef int chan
        chan = self.channel
        mult = self.mult

        n_arr[chan,:] = mult * n_arr[chan,:]
        print self.idx
        self.idx += 1
        #print "plugin end"


cdef Negate pluginOp = Negate()

############## here starts the C++ interface


cdef public void pluginStartup():
    cdef Negate po = pluginOp
    po.startup()

cdef public int getParamNum():
    cdef Negate po = pluginOp
    return len(po.param_config())

cdef public void getParamConfig(ParamConfig *params):
    cdef int *ent
    cdef Negate po = pluginOp
    ppc = po.param_config()
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
    cdef Negate po = pluginOp
    po.set_events(events)
    po.bufferfunction(n_arr)

cdef public int pluginisready():
    cdef Negate po = pluginOp
    return po.is_ready()

cdef public void setIntParam(char *name, int value):
    cdef Negate po = pluginOp
    print "In Python: ", name, ": ", value
    setattr(po, name, value)

cdef public void setFloatParam(char *name, float value):
    # print "In Python: ", name, ": ", value
    cdef Negate po = pluginOp
    setattr(po, name, value)