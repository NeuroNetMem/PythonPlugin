import matplotlib.pyplot as plt

import sys
__author__ = 'fpbatta'


class PlotSubprocess(object):  # TODO more configuration stuff that may be obtained
    def __init__(self, ):
        # keep this slot for multiprocessing related initialization if needed
        self.pipe = None

    def startup(self):
        pass

    def __call__(self, pipe):
        # initialize plot, this is the "main" of the child process

        # initialize pipe
        self.pipe = pipe

        self.startup()
        # start plotting thread

    @staticmethod
    def param_config():
        return ()

    def is_ready(self):  # TODO propagate to plugin method
        return 1

    def callback(self):

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
                elif k == 'terminate':
                    print "terminating"
                    self.terminate()
        # print "finishing callback"
        if events:
            for e in events:
                self.pipe.send(e)

        return True

    def terminate(self):
        plt.close()
        sys.exit(0)