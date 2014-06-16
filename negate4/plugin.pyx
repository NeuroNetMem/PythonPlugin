cimport numpy as np
import numpy as np
from cython cimport view

cdef public void pluginFunction(float *buffer, int nChans, int nSamples):
    print "plugin start"

    #cdef view.array c_arr = <float[:nChans, :nSamples]> buffer
    n_arr = np.asarray(<np.float32_t[:nChans, :nSamples]> buffer)
    #c_arr[4,:] = c_arr[4,:] * 2
    n_arr[4,:] = - n_arr[4,:]
    print "plugin end"


cdef public int pluginisready():
    return 1

