__author__ = 'fpbatta'

import time
import numpy as np
import matplotlib
import matplotlib.pyplot as plt
from multiprocessing import Pipe


class SimplePlotter(object): #TODO more configuration stuff that may be obtained
    def __init__(self, sampling_rate):
        """
        :param sampling_rate: the sampling rate of the process
        :return: None
        Here all the configuration detail that is available at initialization time, however,
        no matplotlib object should be defined in here because they can't be pickled and sent it
        through the process borders. The constructor gets called in the
        """
        self.y = np.empty([0,], dtype = np.float32) # the buffer for the data that gets accumulated
        self.chan_in = 2
        self.plotting_interval = 250. # in ms
        self.frame_count = 0
        self.frame_max = 0
        self.sampling_rate = sampling_rate

        # matplotlib members, initialized to None, they will be filled in the child process
        self.ax = None
        self.hl = None
        self.figure = None
        self.n_samples = 0
        self.pipe = None

    def __call__(self, pipe):
        #initialize plot, this will be called in the child process

        # initialize pipe
        self.pipe = pipe

        # build the plot
        self.figure, self.ax = plt.subplots()
        self.hl, = self.ax.plot([],[])
        self.ax.set_autoscaley_on(True)
        self.ax.margins(y=0.1)
        self.ax.set_xlim(0., 1)

        # initialize timer
        timer = self.figure.new_timer(interval = 300, )
        timer.add_callback(self.callback) # will it work like this?
        timer.start()

        # start plotting thread
        plt.show()


    def is_ready(self): #TODO propagate to plugin method
        return 1

    def param_config(self): #TODO to define parameters to be manipulated in the OE GUI
        return ()

    def update_plot(self, n_arr):
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


