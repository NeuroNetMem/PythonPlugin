import matplotlib.pyplot as plt
import zmq
import sys
import numpy as np
import json
import uuid
import time
__author__ = 'fpbatta'


class OpenEphysEvent(object):
    event_types = {0: 'TIMESTAMP', 1: 'BUFFER_SIZE', 2: 'PARAMETER_CHANGE',
                   3: 'TTL', 4: 'SPIKE', 5: 'MESSAGE', 6: 'BINARY_MSG'}

    def __init__(self, _d, _data=None):
        self.type = 0
        self.eventId = 0
        self.sampleNum = 0
        self.eventChannel = 0
        self.numBytes = 0
        self.data = b''
        self.__dict__.update(_d)
        self.timestamp = None
        self.type = OpenEphysEvent.event_types[self.type]
        if _data:
            self.data = _data
            self.numBytes = len(_data)
        if self.type == 'TIMESTAMP':
            t = np.frombuffer(self.data, dtype=np.int64)
            self.timestamp = t[0]

    def set_data(self, _data):
        self.data = _data
        self.numBytes = len(_data)

    def __str__(self):
        ds = self.__dict__.copy()
        del ds['data']
        return str(ds)


class PlotProcess(object):  # TODO more configuration stuff that may be obtained
    def __init__(self, ):
        # keep this slot for multiprocessing related initialization if needed
        self.context = zmq.Context()
        self.data_socket = None
        self.event_socket = None
        self.poller = zmq.Poller()
        self.message_no = -1
        self.event_waits_reply = False
        self.event_no = 0
        self.app_name = 'Plot Process'
        self.uuid = str(uuid.uuid4())
        self.last_heartbeat_time = 0
        self.heartbeat_waits_reply = False

    def startup(self):
        pass

    @staticmethod
    def param_config():
        # TODO we'll have to pass the parameter requests via a second socket
        # this is meant to support a mechanism to set parameters of the application from the Open Ephys GUI.
        # not sure if it will be needed actually, it may disappear
        return ()

    def update_plot(self, n_arr):
        pass

    def update_plot_event(self, event):
        pass

    def send_heartbeat(self):
        d = {'application': self.app_name, 'uuid': self.uuid, 'type': 'heartbeat'}
        j_msg = json.dumps(d)
        self.event_socket.send(j_msg.encode('utf-8'))
        self.last_heartbeat_time = time.time()
        self.heartbeat_waits_reply = True

    def send_event(self, event_list=None, event_type=3, sample_num=0, event_id=2, event_channel=1):
        if not self.event_waits_reply:
            self.event_no += 1
            if event_list:
                for e in event_list:
                    self.send_event(event_type=e['event_type'], sample_num=e['sample_num'], event_id=e['event_id'],
                                    event_channel=e['event_channel'])
            else:
                de = {'type': event_type, 'sample_num': sample_num, 'event_id': event_id % 2 + 1,
                      'event_channel': event_channel}
                d = {'application': self.app_name, 'uuid': self.uuid, 'type': 'event', 'event': de}
                j_msg = json.dumps(d)
                print(j_msg)
                self.event_socket.send(j_msg.encode('utf-8'), 0)
            self.event_waits_reply = True
        else:
            print("can't send event, still waiting for previous reply")

    def callback(self):
        events = []

        if not self.data_socket:
            print("init socket")
            self.data_socket = self.context.socket(zmq.SUB)
            self.data_socket.connect("tcp://localhost:5556")

            self.event_socket = self.context.socket(zmq.REQ)
            self.event_socket.connect("tcp://localhost:5557")

            # self.data_socket.connect("ipc://data.ipc")
            self.data_socket.setsockopt(zmq.SUBSCRIBE, b'')
            self.poller.register(self.data_socket, zmq.POLLIN)
            self.poller.register(self.event_socket, zmq.POLLIN)

        # send every two seconds a "heartbeat" so that Open Ephys knows we're alive

        if (time.time() - self.last_heartbeat_time) > 2.:
            self.send_heartbeat()

        # TODO: merely for testing
        if np.random.random() < 0.005:
            self.send_event(event_type=3, sample_num=0, event_id=self.event_no, event_channel=1)

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
                    if len(message) < 2:
                        print("no frames for message: ", message[0])
                    try:
                        header = json.loads(message[1].decode('utf-8'))
                    except ValueError as e:
                        print("ValueError: ", e)
                        print(message[1])
                    if self.message_no != -1 and header['message_no'] != self.message_no + 1:
                        print("missing a message at number", self.message_no)
                    self.message_no = header['message_no']
                    if header['type'] == 'data':
                        c = header['content']
                        n_samples = c['n_samples']
                        n_channels = c['n_channels']
                        n_real_samples = c['n_real_samples']

                        try:
                            n_arr = np.frombuffer(message[2], dtype=np.float32)
                            n_arr = np.reshape(n_arr, (n_channels, n_samples))
                            if n_real_samples > 0:
                                n_arr = n_arr[:, 0:n_real_samples]
                                self.update_plot(n_arr)
                        except IndexError as e:
                            print(e)
                            print(header)
                            print(message[1])
                            if len(message) > 2:
                                print(len(message[2]))
                            else:
                                print("only one frame???")

                    elif header['type'] == 'event':

                        if header['data_size'] > 0:
                            event = OpenEphysEvent(header['content'], message[2])
                        else:
                            event = OpenEphysEvent(header['content'])
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
            elif self.event_socket in socks:
                message = self.event_socket.recv()
                print("event reply received")
                print(message)
                if self.event_waits_reply:
                    self.event_waits_reply = False
                elif self.heartbeat_waits_reply:
                    self.heartbeat_waits_reply = False
                else:
                    print("???? getting a reply before a send?")
        # print "finishing callback"
        if events:
            pass  # TODO implement the event passing

        return True

    @staticmethod
    def terminate():
        plt.close()
        sys.exit(0)
