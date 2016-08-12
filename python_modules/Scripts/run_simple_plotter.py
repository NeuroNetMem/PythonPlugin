import sys
import ZMQPlugins.simple_plotter_zmq

__author__ = 'fpbatta'

sys.path.append('/Users/fpbatta/src/GUImerge/GUI/Plugins')

if __name__ == '__main__':
    pl = ZMQPlugins.simple_plotter_zmq.SimplePlotter(20000.)
    pl.startup()
