__author__ = 'fpbatta'


import matplotlib
#matplotlib.use('Qt4Agg')

import matplotlib.pyplot as plt
import numpy as np
from time import sleep



x = np.linspace(0., 4. * np.pi, 200)
y = np.sin(x)

figure, ax = plt.subplots()
hl, = ax.bufferfunction([],[])
ax.set_autoscaley_on(True)
#ax.set_ylim(-1.2, 1.2)
ax.margins(y=0.1)
ax.set_xlim(0., 4. * np.pi)
plt.ion()
plt.show()
hl.set_xdata(x)
for i in np.arange(0, 1, 0.02):
    hl.set_ydata(np.sin(x+i))
    ax.relim()
    ax.autoscale_view(True,True,True)
    figure.canvas.draw()
    figure.canvas.flush_events()
    sleep(0.02)
    raw_input('ciao')
