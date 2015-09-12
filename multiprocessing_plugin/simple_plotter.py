import time
import numpy as np
# import matplotlib
import matplotlib.pyplot as plt
from matplotlib.widgets import Slider

from multiprocessing import Pipe, Process
import sys
__author__ = 'fpbatta'


class SimplePlotter(object):  # TODO more configuration stuff that may be obtained
    def __init__(self, sampling_rate):
        """
        :param sampling_rate: the sampling rate of the process
        :return: None
        Here all the configuration detail that is available at initialization time, however,
        no matplotlib object should be defined in here because they can't be pickled and sent it
        through the process borders. The constructor gets called in the
        """
        self.y = np.empty((0, ), dtype=np.float32)  # the buffer for the data that gets accumulated
        self.chan_in = 2
        self.plotting_interval = 250.  # in ms
        self.frame_count = 0
        self.frame_max = 0
        self.sampling_rate = sampling_rate

        # matplotlib members, initialized to None, they will be filled in the child process
        self.ax = None
        self.hl = None
        self.figure = None
        self.n_samples = 0
        self.pipe = None
        self.code = 0

    def __call__(self, pipe):
        # initialize plot, this is the "main" of the child process

        # initialize pipe
        self.pipe = pipe

        # build the plot
        ylim0 = 200
        print "starting plot"
        self.figure, self.ax = plt.subplots()
        plt.subplots_adjust(left=0.1, bottom=0.2)
        axcolor = 'lightgoldenrodyellow'
        axylim = plt.axes([0.1, 0.05, 0.65, 0.03], axisbg=axcolor)
        sylim = Slider(axylim, 'Freq', 50, 500, valinit=ylim0)

        def update(val):
            yl = sylim.val
            self.ax.set_ylim(-yl, yl)
            plt.draw()

        sylim.on_changed(update)

        self.hl, = self.ax.plot([], [])
        self.ax.set_autoscaley_on(True)
        self.ax.margins(y=0.1)
        self.ax.set_xlim(0., 1)
        self.ax.set_ylim(-ylim0, ylim0)
        # initialize timer
        timer = self.figure.canvas.new_timer(interval=100, )
        timer.add_callback(self.callback)  # will it work like this?
        timer.start()

        # start plotting thread
        plt.show()

    @staticmethod
    def param_config():
        chan_labels = range(32)
        return ("int_set", "chan_in", chan_labels),

    def is_ready(self):  # TODO propagate to plugin method
        return 1

    def callback(self):  # TODO send events
        # print "entering callback"

        events = []

        while 1:
            if not self.pipe.poll():
                break

            command = self.pipe.recv()
            for k, v in command.iteritems():
                if k == 'data':
                    events = self.update_plot(v)
                elif k == 'param':
                    for name, value in v.iteritems():
                        setattr(self, name, value)
                        # DEBUG
                        print v, " chan_in = ", self.chan_in
                elif k == 'terminate':
                    print "terminating"
                    self.terminate()
        # print "finishing callback"
        if events:
            print "sending events"
            for e in events:
                self.pipe.send(e)

        return True

    def update_plot(self, n_arr):
        # setting up frame dependent parameters
        # print "updating plot"
        self.n_samples = int(n_arr.shape[1])
        events = []
        frame_time = 1000. * self.n_samples / self.sampling_rate
        self.frame_max = int(self.plotting_interval / frame_time)
        # increment the buffer
        self.y = np.append(self.y, n_arr[self.chan_in-1, :])
        self.frame_count += 1

        if self.frame_count == self.frame_max:
            # update the plot
            x = np.arange(len(self.y), dtype=np.float32) * 1000. / self.sampling_rate
            self.hl.set_ydata(self.y)
            self.hl.set_xdata(x)
            self.ax.set_xlim(0., self.plotting_interval)
            self.ax.relim()
            self.ax.autoscale_view(True, True, False)
            self.figure.canvas.draw()
            self.figure.canvas.flush_events()

            self.frame_count = 0
            self.y = np.empty((0, ), dtype=np.float32)

        # if np.random.random() < 0.5:
        #     events.append({'type': 3, 'sampleNum': 0, 'eventId': self.code})
        #     self.code += 1
        return events

    def terminate(self):
        print "terminating plot process"
        plt.close()
        sys.exit(0)


class MPPlugin(object):
    # this functionality needs to be implemented in the cython parent side
    def __init__(self):
        self.plot_pipe, plotter_pipe = Pipe()
        self.plotter = SimplePlotter(20000.)
        self.plot_process = Process(target=self.plotter,
                                    args=(plotter_pipe, ))
        self.plot_process.daemon = True
        self.plot_process.start()

    def bufferfunction(self, n_arr = None, finished=False):
        # print "entering plot"
        send = self.plot_pipe.send
        if finished:
            send(None)
        else:
            # print "sending data"
            data = np.random.random((11, 1000))
            send({'data': n_arr})

        while 1:
            if not self.plot_pipe.poll():
                break
            e = self.plot_pipe.recv()
            print e

    def setparam(self, name, value):
        self.plot_pipe.send({'param': {name: value}})


def main():
    pl = MPPlugin()
    for jj in range(10):
        for ii in range(10):
            pl.bufferfunction()
            time.sleep(0.02)
        pl.setparam('chan_in', jj)
    raw_input('press Enter...')
    pl.bufferfunction(finished=True)
    pl.plot_process.join()

if __name__ == '__main__':
    main()
