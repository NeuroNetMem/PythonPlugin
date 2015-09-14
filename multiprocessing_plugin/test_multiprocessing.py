__author__ = 'fpbatta'

import time

import numpy as np
import sys
import multiprocessing as mp
if __name__ == '__main__':
    #mp.freeze_support()

    print(mp.get_all_start_methods())
    sm = mp.get_start_method()
    print("sm: ", sm)
    mp.set_start_method('forkserver', force=True)
    print("sm 2: ", sm)

    sys.path.append('/Users/fpbatta/src/GUImerge/GUI/Plugins')
    #sys.path.append('/Users/fpbatta/src/GUImerge/GUI/Plugins/multiprocessing_plugin')
    from multiprocessing_plugin import MultiprocessingPlugin


    m = MultiprocessingPlugin()

    m.startup(20000.)
    m.bufferfunction(np.random.random((11,1000)))

    for i in range(100):
        m.bufferfunction(200. * np.random.random((11,1000)))
        time.sleep(0.05)

    time.sleep(2)
    del m