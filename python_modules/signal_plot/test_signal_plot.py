__author__ = 'fpbatta'

import sys
import time
sys.path.append('/home/fpbatta/src/GUI/Plugins/')

import numpy as np
import signal_plot
#import signal_plot.signal_plot

s = signal_plot.SimplePlotter()
s.startup(20000.)

time.sleep(10)
for i in range(100):
    s.bufferfunction(np.random.random((20,1000)))

