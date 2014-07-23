cimport numpy as np
import numpy as np
from cython cimport view


class Negate(object):
    def __init__(self):
        self.enabled = 1

    def startup(self):
        self.enabled = 1

    def plugin_name(self):
        return "Negate"

    def isReady(self):
        return 1

    def paramConfig(self):
        return (("toggle", "enabled" , True),)

    def bufferfunction(self, n_arr):
        #print "plugin start"
        cdef float mult
        mult = 1. - 2. * self.enabled
        n_arr[4,:] = mult * n_arr[4,:]
        #print "plugin end"


pluginOp = Negate()


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



cdef public void pluginStartup():
    pluginOp.startup()

cdef public int getParamNum():
    return len(pluginOp.paramConfig())

cdef public void getParamConfig(ParamConfig *params):
    ppc = pluginOp.paramConfig()
    for i in range(len(ppc)):
        par = ppc[i]
        if par[0] == "toggle":
            params[0].type = TOGGLE
            params[0].name = par[1]
            params[0].isEnabled = par[2]
        #TODO other types of commands

cdef public void pluginFunction(float *buffer, int nChans, int nSamples):
    n_arr = np.asarray(<np.float32_t[:nChans, :nSamples]> buffer)
    pluginOp.bufferfunction(n_arr)

cdef public int pluginisready():
    return pluginOp.isReady()

cdef public void setIntParam(char *name, int value):
    print "In Python: ", name, ": ", value
    setattr(pluginOp, name, value)

cdef public void setFloatParam(char *name, int value):
    print "In Python: ", name, ": ", value
    setattr(pluginOp, name, value)