__author__ = 'fpbatta'

__doc__ = """
simple data extractor for testing the plugins
"""

import sys
import h5py
import math
import numpy as np
import matplotlib.pyplot as plt

pluginDir = "/Users/fpbatta/src/GUImerge/GUI/Plugins"
testDataFile = "/Users/fpbatta/dataLisa/disruption0724/100_raw.kwd"
sys.path.append(pluginDir)

import SPWfinder.plugin

plugin = SPWfinder.plugin.SPWFinder()
tFile = h5py.File(testDataFile)
tData = tFile["/recordings/0/data"]
sample_rate = tFile["/recordings/0"].attrs["sample_rate"][0]
bit_volts = tFile["/recordings/0/application_data"].attrs["channel_bit_volts"]
samples_per_frame = 1024 # audio frame in OE
frame = samples_per_frame /44100.

print "tData: ", tData
print "sample_rate: ", sample_rate

plugin.startup(sample_rate)
def reload_plugin():
    reload(SPWfinder.plugin)
    plugin = SPWfinder.plugin.SPWFinder()


def lookup_data(tStart, tEnd):
    iStart = int(tStart * sample_rate)
    print "iStart: ", iStart
    iEnd = int(tEnd * sample_rate)
    iD = iEnd - iStart
    iD = samples_per_frame * math.floor(iD/samples_per_frame)
    iEnd = int(iStart + iD)

    print "iEnd: ", iEnd

    data = tData[iStart:iEnd, :] * bit_volts
    spread = 1000
    chans_to_plot = [1, 2, 3, 4, 9]
    nSamples = data.shape[0]
    nChans = data.shape[1]
    print nSamples

    plugin.chan_in = 9-1
    print "chan_in: ", plugin.chan_in
    frame_starts = np.arange(iStart, iEnd, samples_per_frame, dtype=np.int)
    data = np.zeros([0,nChans], dtype=np.float32)
    for ix in frame_starts:
        d = tData[ix:(ix+samples_per_frame), :].astype(np.float32)
        #d0 = d.copy()
        plugin.bufferfunction(d.transpose())
        data = np.concatenate((data, d), axis=0)

    t = np.linspace(tStart, tEnd, data.shape[0])
    for ix, ch in enumerate(chans_to_plot):
        x = t
        y = data[:,ch-1]-ix*spread
        plt.plot(x, y)
        plt.text(tStart+(tEnd-tStart)*1., -ix*spread, str(ch))
    plt.show()


if __name__ == '__main__':
    lookup_data(17,19)









