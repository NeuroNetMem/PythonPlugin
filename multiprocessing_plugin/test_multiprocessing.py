__author__ = 'fpbatta'

import time

import numpy as np
import sys
sys.path.append('/Users/fpbatta/src/GUImerge/GUI/Plugins')
sys.path.append('/Users/fpbatta/src/GUImerge/GUI/Plugins/multiprocessing_plugin')
from multiprocessing_plugin import MultiprocessingPlugin


m = MultiprocessingPlugin()

m.startup(20000.)
m.bufferfunction(np.random.random((11,1000)))

for i in range(100):
    m.bufferfunction(np.random.random((11,1000)))
    time.sleep(0.05)

time.sleep(5)