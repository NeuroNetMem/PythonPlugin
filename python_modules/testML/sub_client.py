import zmq
import _pickle as pickle
import numpy as np
import matplotlib.pyplot as plt
#plt.ion()
#fig, ax = plt.subplots()
x, y = [],[]
#sc = ax.scatter(x,y)
#plt.xlim(-200,200)
#plt.ylim(-200,200)
#plt.draw()

# Socket to talk to server
context = zmq.Context()
socket = context.socket(zmq.SUB)
port = "5556"
socket.connect ("tcp://localhost:%s" % port)

topicfilter = "10001"
socket.setsockopt_string(zmq.SUBSCRIBE, '')


total_value = 0
while True:
    data = pickle.loads(socket.recv_pyobj())
    print(np.shape(data))
    #obs,d=np.shape(data)
    #for i in range(0,obs):
    #    x.append(data[i,0])
    #    y.append(data[i,1])
    #sc.set_offsets(np.c_[x,y])
    #fig.canvas.draw_idle()
    #plt.pause(0.1)
