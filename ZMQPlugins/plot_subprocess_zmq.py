import matplotlib.pyplot as plt
import zmq
import sys
import numpy as np

__author__ = 'fpbatta'


class PlotSubprocess(object):  # TODO more configuration stuff that may be obtained
    def __init__(self, ):
        # keep this slot for multiprocessing related initialization if needed
        self.context = zmq.Context()
        self.data_socket = None
        self.poller = zmq.Poller()

    def startup(self):
        pass

    @staticmethod
    def param_config():
        # TODO we'll have to pass the parameter requests via a second socket
        return ()

    def update_plot(self, n_arr):
        pass

    def callback(self):
        events = []

        if not self.data_socket:
            print("init socket")
            self.data_socket = self.context.socket(zmq.SUB)
            self.data_socket.connect("tcp://localhost:5556")
            #self.data_socket.connect("ipc://data.ipc")
            self.data_socket.setsockopt(zmq.SUBSCRIBE, b'')
            self.poller.register(self.data_socket, zmq.POLLIN)

        print("new read")
        while True:
            socks = dict(self.poller.poll(1))
            if not socks:
                print("got no data")
                break
            if self.data_socket in socks:
                try:
                    message = self.data_socket.recv(zmq.NOBLOCK)
                except zmq.ZMQError as err:
                    print("got error: {0}".format(err))
                    break
                if message:
                    n_arr = np.frombuffer(message, dtype=np.float32)
                    n_arr = np.reshape(n_arr, (20,1000)) # TODO communciate array shape from other side
                    self.update_plot(n_arr)
                else:
                    print("got not data")

                    break


        # print "finishing callback"
        if events:
            pass # TODO implement the event passing

        return True

    def terminate(self):
        plt.close()
        sys.exit(0)