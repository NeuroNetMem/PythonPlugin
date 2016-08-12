import sys
import numpy as np
cimport numpy as np
from cython cimport view

import multiprocessing as mp
#mp.set_start_method('spawn')

# print ("the file")
# print (__file__)
# sys.path.append('/home/fpbatta/src/GUI/Plugins')
# sys.path.append('/home/fpbatta/src/GUI/Plugins/multiprocessing_plugin') # TODO put the python path in the C++ executalbe
sys.path.append('/Users/fpbatta/src/GUImerge/GUI/Plugins')
sys.path.append('/Users/fpbatta/src/GUImerge/GUI/Plugins/multiprocessing_plugin') # TODO put the python path in the C++ executalbe

isDebug = False

import simple_plotter

class MultiprocessingPlugin(object):
    def __init__(self):
        self.if_params = ()
        #define variables
        self.plot_pipe = None
        self.plotter = None
        self.plot_process = None
        self.has_child = False


    def startup(self, sr):
        ctx = mp.get_context('spawn')
        #mp.freeze_support()
        ctx.set_executable('/usr/local/anaconda3/anaconda/bin/python') # TODO make choice of executable automatic
        self.plot_pipe, plotter_pipe = ctx.Pipe()
        self.plotter = simple_plotter.SimplePlotter(20000.)
        self.plot_process = ctx.Process(target=self.plotter,
                                    args=(plotter_pipe, ))
        self.plot_process.daemon = True

        self.plot_process.start()
        self.has_child = True
        self.if_params = self.plotter.param_config()

    def plugin_name(self):
        return "SimplePlotter"

    def is_ready(self):
        return self.has_child

    def param_config(self):
        return self.plotter.param_config()

    def bufferfunction(self, n_arr = None, finished=False):
        # print("entering plot")
        send = self.plot_pipe.send
        if finished:
            print("sending stop signal")
            send({'terminate': 0})
        else:
            # print "sending data"
            send({'data': n_arr})

        events = []
        while 1:
            if not self.plot_pipe.poll():
                break
            e = self.plot_pipe.recv()
            events.append(e)
            print(e)
        return events

    def set_param(self, name, value):
        self.plot_pipe.send({'param': {name: value}})

    def __setattr__(self, key, value):
        if hasattr(self, "if_params"):
            for l in self.if_params:
                if key == l[1]:
                    self.set_param(key, value)
                    return
        object.__setattr__(self, key, value)

    def __del__(self):
        print("deleting mp") # DEBUG
        self.bufferfunction(finished=True)


pluginOp = MultiprocessingPlugin()
include "../plugin.pyx"