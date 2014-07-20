cimport numpy as np
import numpy as np
from cython cimport view

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
    pass

cdef public int getParamNum():
    return 3



cdef public void pluginFunction(float *buffer, int nChans, int nSamples):
    print "plugin start"

    #cdef view.array c_arr = <float[:nChans, :nSamples]> buffer
    n_arr = np.asarray(<np.float32_t[:nChans, :nSamples]> buffer)
    #c_arr[4,:] = c_arr[4,:] * 2
    n_arr[4,:] = - n_arr[4,:]
    print "plugin end"


cdef public int pluginisready():
    return 1

cdef public void getParamConfig(ParamConfig *params):
    params[0].type = TOGGLE
    params[0].name = "Apple"
    params[1].type = TOGGLE
    params[1].name = "Banana"
    params[2].type = TOGGLE
    params[2].name = "Cherry"
