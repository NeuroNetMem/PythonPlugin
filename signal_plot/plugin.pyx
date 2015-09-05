import sys
import numpy as np
cimport numpy as np
from cython cimport view
import serial
import matplotlib
#matplotlib.use('Qt4Agg')

import matplotlib.pyplot as plt

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

class SimplePlotter(object):
    def __init__(self):
        #define variables
        self.y = np.empty([0,], dtype = np.float32)
        self.chan_in = 2
        self.plotting_interval = 1000. # in ms
        self.frame_count = 0
        self.frame_max = 0
        self.sampling_rate = 0.
        self.ax = None
        self.hl = None
        self.figure = None
        self.n_samples = 0

    def startup(self, sr):
        #initialize plot
        self.sampling_rate = sr
        self.figure, self.ax = plt.subplots()
        self.hl, = self.ax.plot([],[])
        self.ax.set_autoscaley_on(True)
        self.ax.margins(y=0.1)
        self.ax.set_xlim(0., 4. * np.pi)
        plt.ion()
        plt.show()


    def plugin_name(self):
        return "SimplePlotter"

    def is_ready(self):
        return 1

    def param_config(self):
        return ()

    def bufferfunction(self, n_arr):
        # setting up frame dependent parameters
        self.n_samples = int(n_arr.shape[1])

        frame_time = 1000. * self.n_samples / self.sampling_rate
        self.frame_max = int(self.plotting_interval / frame_time)
        #increment the buffer
        self.y = np.append(self.y, n_arr[self.chan_in-1, :])
        self.frame_count += 1

        if self.frame_count == self.frame_max:
            #update the plot
            x = np.arange(len(self.y), dtype=np.float32) * 1000. / self.sampling_rate
            self.hl.set_ydata(self.y)
            self.hl.set_xdata(x)
            self.ax.set_xlim(0., self.plotting_interval)

            self.ax.relim()
            self.ax.autoscale_view(True,True,True)
            self.figure.canvas.draw()
            self.figure.canvas.flush_events()

            self.frame_count = 0
            self.y = np.empty([0,], dtype = np.float32)

        events = []
        return events


pluginOp = SimplePlotter()
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