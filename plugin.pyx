import sys
import numpy as np
cimport numpy as np
from cython cimport view
from libc.stdlib cimport malloc, calloc

sr = 1.

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


# noinspection PyPep8Naming
cdef public void pluginStartup(float sampling_rate) with gil:
    global sr
    global isDebug
    global pluginOp
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
cdef public void pluginFunction(float *data_buffer, int nChans, int nSamples, int nRealSamples, PythonEvent *events) with gil:
    global sr
    n_arr = np.asarray(<np.float32_t[:nChans, :nSamples]> data_buffer)
    #pluginOp.set_events(events)
    #pm2 = PluginModule(pm)

    if isDebug:
        print "sr: ", sr
    samples_to_read = nRealSamples
    events_to_add = []
    if samples_to_read > 0:
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
        e_c.eventData = <unsigned char *>e_py['eventData']
        # TODO to be tested if this works with a numpy input

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