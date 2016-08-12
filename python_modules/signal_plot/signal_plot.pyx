import sys
import numpy as np
cimport numpy as np
from cython cimport view
import matplotlib
# matplotlib.use('CocoaAgg')
matplotlib.use('QT4agg')
import matplotlib.pyplot as plt

isDebug = False

class SimplePlotter(object):
    def __init__(self):
        print ("init")
        #define variables
        self.y = np.empty([0,], dtype = np.float32)
        self.chan_in = 2
        self.plotting_interval = 250. # in ms
        self.frame_count = 0
        self.frame_max = 0
        self.sampling_rate = 0.
        self.ax = None
        self.hl = None
        self.figure = None
        self.n_samples = 0

    def startup(self, sr):
        print ("startup")
        #initialize plot
        self.sampling_rate = sr
        self.figure, self.ax = plt.subplots()
        print ("figure: ", self.figure)
        self.hl, = self.ax.plot([],[])
        self.ax.set_autoscaley_on(True)
        self.ax.margins(y=0.1)
        self.ax.set_xlim(0., 4. * np.pi)
        # plt.ion()
        plt.show(block=False)
        self.hl.set_ydata(np.zeros(100,))
        self.hl.set_xdata(np.linspace(0, 4 *np.pi, 100))
        self.ax.relim()
        self.ax.autoscale_view(True,True,True)
        self.figure.canvas.draw()
        self.figure.canvas.flush_events()


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
            print ("updating plot")
            x = np.arange(len(self.y), dtype=np.float32) * 1000. / self.sampling_rate
            print( x[-1])
            self.hl.set_ydata(self.y)
            self.hl.set_xdata(x)
            self.ax.set_xlim(0., self.plotting_interval)
            self.ax.relim()
            self.ax.autoscale_view(True,True,True)
            self.figure.canvas.draw()
            # self.figure.canvas.flush_events()

            self.frame_count = 0
            self.y = np.empty([0,], dtype = np.float32)

        events = []
        return events


pluginOp = SimplePlotter()
include "../plugin.pyx"