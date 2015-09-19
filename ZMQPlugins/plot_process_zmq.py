import matplotlib.pyplot as plt
import zmq
import sys
import numpy as np
import json
__author__ = 'fpbatta'


class OpenEphysEvent(object):
    def __init__(self, _d):
        self.type = 1
        self.eventId = 0
        self.sampleNum = 0
        self.eventChannel = 0
        self.numBytes = 0
        self.data = b''
        self.__dict__.update(_d)

    def set_data(self, _data):
        self.data = _data
        self.numBytes = len(_data)

    def __str__(self):
        return str(self.__dict__)


class PlotProcess(object):  # TODO more configuration stuff that may be obtained
    def __init__(self, ):
        # keep this slot for multiprocessing related initialization if needed
        self.context = zmq.Context()
        self.data_socket = None
        self.poller = zmq.Poller()
        self.message_no = -1

    def startup(self):
        pass

    @staticmethod
    def param_config():
        # TODO we'll have to pass the parameter requests via a second socket
        return ()

    def update_plot(self, n_arr):
        pass

    def update_plot_event(self, event):
        pass

    def callback(self):
        events = []

        if not self.data_socket:
            print("init socket")
            self.data_socket = self.context.socket(zmq.SUB)
            self.data_socket.connect("tcp://localhost:5556")
            # self.data_socket.connect("ipc://data.ipc")
            self.data_socket.setsockopt(zmq.SUBSCRIBE, b'')
            self.poller.register(self.data_socket, zmq.POLLIN)

        # print("************new read")
        while True:
            socks = dict(self.poller.poll(1))
            if not socks:
                # print("poll exits")
                break
            if self.data_socket in socks:
                try:
                    message = self.data_socket.recv_multipart(zmq.NOBLOCK)
                except zmq.ZMQError as err:
                    print("got error: {0}".format(err))
                    break
                if message:
                    try:
                        header = json.loads(message[0].decode('utf-8'))
                    except ValueError as e:
                        print("ValueError: ", e)
                        print(message[0])
                    if self.message_no != -1 and header['messageNo'] != self.message_no + 1:
                        print("missing a message at number", self.message_no)
                    self.message_no = header['messageNo']
                    if header['type'] == 'data':
                        c = header['content']
                        n_samples = c['nSamples']
                        n_channels = c['nChannels']
                        try:
                            n_arr = np.frombuffer(message[1], dtype=np.float32)
                            n_arr = np.reshape(n_arr, (n_channels, n_samples))
                            self.update_plot(n_arr)
                        except IndexError as e:
                            print(e)
                            print(header)
                            print(message[0])
                            if len(message) > 2:
                                print(len(message[1]))
                            else:
                                print("only one frame???")



                    elif header['type'] == 'event':

                        event = OpenEphysEvent(header['content'])
                        if header['dataSize'] > 0:
                            event.set_data(message[1])
                        print(event)
                        self.update_plot_event(event)
                    elif header['type'] == 'param':
                        c = header['content']
                        self.__dict__.update(c)
                        print(c)
                    else:
                        raise ValueError("message type unknown")

                else:
                    print("got not data")

                    break

        # print "finishing callback"
        if events:
            pass  # TODO implement the event passing

        return True

    @staticmethod
    def terminate():
        plt.close()
        sys.exit(0)
