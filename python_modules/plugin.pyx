# cython: language_level=3
import sys
import numpy as np
cimport numpy as np
from cython cimport view
from libc.stdlib cimport malloc, calloc
from libc.string cimport memcpy

sr = 1.

cdef extern from "PythonParamConfig.h":
    enum paramType:
        TOGGLE, INT_SET, FLOAT_RANGE



cdef extern from "PythonParamConfig.h":
    struct ParamConfig:
        paramType type
        char *name
        int isEnabled
        int nEntries
        int *entries
        float rangeMin
        float rangeMax
        float startValue


cdef extern from "PythonEvent.h":
    struct PythonEvent:
        unsigned char type
        int sampleNum
        unsigned char eventId
        unsigned char eventChannel
        unsigned char numBytes
        unsigned char *eventData
        PythonEvent *nextEvent


# noinspection PyPep8Naming
cdef public void pluginStartup(int nChans, float samplingRate, int *chanStates):
    print("pre anything")
    global isDebug
    print("after is debug")
    global pluginOp
    cdef bint[:] states
    if nChans == 0:
        # pointer might be null
        pluginOp.startup(nChans, samplingRate, [])
    else:
        states = <bint[:nChans]>(<bint*> chanStates)
        pluginOp.startup(nChans, samplingRate, states)

# noinspection PyPep8Naming
cdef public int getParamNum():
    return len(pluginOp.param_config())

# noinspection PyPep8Naming
cdef public void getParamConfig(ParamConfig *params):
    cdef int *ent
    cdef char * par_name
    cdef size_t par_len
    ppc = pluginOp.param_config()
    for i in range(len(ppc)):
        par = ppc[i]
        print("par[0], ", par[0])
        print("par[1], ", par[1])
        print("par[2], ", par[2])
        par_len = len(par[1])+1
        print("par len: ",par_len)
        par_name = <char *>malloc(par_len)
        par_bytes = par[1].encode('utf-8')
        print("par_bytes: ", par_bytes)
        print("par_name 1: ", par_name)
        memcpy(par_name, <char*>par_bytes, int(par_len-1))
        #par_name = par_bytes
        par_name[par_len-1] = 0
        print("par_name 2: ", par_name)
        if par[0] == "toggle":
            params[i].type = TOGGLE
            params[i].name = par_name
            params[i].isEnabled = par[2]
        elif par[0] == "int_set":
            params[i].type = INT_SET
            params[i].name = par_name
            params[i].nEntries = len(par[2])
            ent = <int *> malloc (sizeof (int) * len(par[2]) )
            for k in range(len(par[2])):
                ent[k] = par[2][k]
            params[i].entries = ent
        elif par[0] == "float_range":
            params[i].type = FLOAT_RANGE
            params[i].name = par_name
            params[i].rangeMin = par[2]
            params[i].rangeMax = par[3]
            params[i].startValue = par[4]



# noinspection PyPep8Naming
cdef public void pluginFunction(float *data_buffer, int nChans, int nSamples, int nRealSamples, PythonEvent *events):
    global sr
    n_arr = np.asarray(<np.float32_t[:nChans, :nSamples]> data_buffer)
    #pluginOp.set_events(events)
    #pm2 = PluginModule(pm)
    if isDebug:
        print("sr: ", sr)
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
            print("in Plugin, event ", e_c.eventId, " added")
        last_e_c = e_c
        for i in range(1,len(events_to_add)):
            e_py = events_to_add[i]
            e_c = <PythonEvent *>calloc(1, sizeof(PythonEvent))
            if isDebug:
                print("in Plugin, event ", e_c.eventId, " added")
            last_e_c.nextEvent = e_c
            add_event(e_c, e_py)
            last_e_c = e_c
        last_e_c.nextEvent = NULL

# noinspection PyPep8Naming
cdef public void eventFunction(int eventType, int sourceID, int subProcessorIdx, double timestamp, int sourceIndex):
    pluginOp.handleEvents(eventType,sourceID,subProcessorIdx,timestamp,sourceIndex)

# noinspection PyPep8Naming
cdef public void spikeFunction(int electrode, int sortedID, float[18] spikeSample):
    n_arr = np.asarray(<np.float32_t[:1, :18]> spikeSample)
    pluginOp.handleSpike(electrode,sortedID,n_arr)

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
        e_c.eventData = <unsigned char *>e_py['eventData']
        # TODO to be tested if this works with a numpy input


cdef public int pluginisready():
    return pluginOp.is_ready()


# called from C++ updateSettings (not during acquisition)
cdef public void updateSettings(int nChans, float samplingRate):
    pluginOp.update_settings(nChans, samplingRate)

# called any time param button is changed (maybe during acquisition)
cdef public void channelChanged(int chan, int newState):
    pluginOp.channel_changed(chan, <bint>newState)

# noinspection PyPep8Naming
cdef public void setIntParam(char *name, int value):
    if isDebug:
        print("In Python: ", name, ": ", value)
    setattr(pluginOp, name.decode('utf-8'), value)

# noinspection PyPep8Naming
cdef public void setFloatParam(char *name, float value):
    # print ("In Python: ", name, ": ", value)
    setattr(pluginOp, name.decode('utf-8'), value)

# noinspection PyPep8Naming
cdef public int getIntParam(char *name):
    if isDebug:
        print("In Python getIntParam: ", name)
    value = getattr(pluginOp, name.decode('utf-8'))
    return <int>value

# noinspection PyPep8Naming
cdef public float getFloatParam(char *name):
    # print( "In Python: ", name, ": ", value)
    value =  getattr(pluginOp, name.decode('utf-8'))
    return <float>value
