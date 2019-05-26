# noinspection PyUnresolvedReferences
import numpy as np
# noinspection PyUnresolvedReferences
cimport numpy as np
# noinspection PyUnresolvedReferences
from cython cimport view
import serial

isDebug = False


# noinspection PyPep8Naming
class spwrandom(object):
    def __init__(self):
        """initialize object data"""
        self.Enabled = 1
        self.refractory_count_down_thresh = 0
        self.refractory_count_down = 0
        self.refractory_time = 100. # time that the plugin will not react to trigger after one pulse
        self.chan_in = 1
        self.chan_out = 0
        self.n_samples = 0
        self.chan_ripples = 1


        self.SWINGING = 1
        self.NOT_SWINGING = 0
        self.swing_state = self.NOT_SWINGING
        self.swing_count_down_thresh = 0
        self.swing_count_down = 0
        self.swing_down_time = 2000. # time that it will be prevetned from firing after a swing event

        self.pulseNo = 0
        self.triggered = 0
        self.samplingRate = 0.
        self.polarity = 0
        self.filter_a = []
        self.filter_b = []
        self.arduino = None
        self.lfp_buffer = np.zeros((500,))
        self.lfp_buffer_max_count = 500
        self.READY=1
        self.ARMED=2
        self.REFRACTORY=3
        self.FIRING = 4
        self.state = self.READY
        self.random_stim_rate = 1 # in Hertz
        self.random_stim_rate_min = 0.1
        self.random_stim_rate_max = 5
        self.prob_threshold = 0.

        self.swing_thresh_min = 10.
        self.swing_thresh_max = 20000.
        self.swing_thresh_start = 1000.
        self.swing_thresh = self.swing_thresh_start

    def startup(self, sr):
        """to be run upon startup"""
        self.samplingRate = sr
        print (self.samplingRate)

        print('starting random stimulation at rate ', self.random_stim_rate)

        self.Enabled = 1
        try:
            self.arduino = serial.Serial('/dev/ttyACM0', 57600)
        except (OSError, serial.serialutil.SerialException):
            print("Can't open Arduino")

    def plugin_name(self):
        """tells OE the name of the program"""
        return "spwrandom"

    def is_ready(self):
        """tells OE everything ran smoothly"""
        return self.Enabled

    def param_config(self):
        """return button, sliders, etc to be present in the editor OE side"""
        chan_labels = range(1,33)
        return (("toggle", "Enabled", True),
                ("float_range", "random_stim_rate", self.random_stim_rate_min, self.random_stim_rate_max, self.random_stim_rate),
                ("float_range", "swing_thresh", self.swing_thresh_min, self.swing_thresh_max, self.swing_thresh_start))

    def spw_condition(self, n_arr):
        return np.random.random() < self.prob_threshold and self.swing_state == self.NOT_SWINGING

    def stimulate(self):
        try:
            self.arduino.write(b'1')
        except AttributeError:
            print("Can't send pulse")
        self.pulseNo += 1
        print("generating pulse ", self.pulseNo)

    def new_event(self, events, code, channel=0, timestamp=None):
        if not timestamp:
            timestamp = self.n_samples
        events.append({'type': 3, 'sampleNum': timestamp, 'eventId': code, 'eventChannel': channel})

    def bufferfunction(self, n_arr):
        """Access to voltage data buffer. Returns events"""
                #print("plugin start")
        if isDebug:
            print("shape: ", n_arr.shape)
        events = []
        cdef int chan_in
        cdef int chan_out
        chan_in = self.chan_in - 1
        self.chan_out = self.chan_ripples

        self.n_samples = int(n_arr.shape[1])

        if self.n_samples == 0:
            return events

        # setting up frame dependent parameters
        frame_time = 1000. * self.n_samples / self.samplingRate  # in milliseconds
        self.prob_threshold = frame_time * self.random_stim_rate / 1000.
        self.refractory_count_down_thresh = int(self.refractory_time / frame_time)
        self.swing_count_down_thresh = int(self.swing_down_time / frame_time)


        # the swing detector state machine
        max_swing = np.max(np.fabs(n_arr[chan_in,:]))
        if self.swing_state == self.NOT_SWINGING:
            if max_swing > self.swing_thresh:
                self.swing_state = self.SWINGING
                self.swing_count_down = self.swing_count_down_thresh
                self.new_event(events, 6)
                print("SWINGING")
        else:
            self.swing_count_down -= 1
            if self.swing_count_down == 0:
                self.swing_state = self.NOT_SWINGING
                print("NOT_SWINGING")

        if isDebug:
            print("Mean: ", np.mean(n_arr[self.chan_out+1,:]))
            print("done processing")

        #events
        # 1: pulse sent
        # 2: jittered, pulse_sent
        # 3: triggered, not enabled
        # 4: trigger armed, jittered
        # 5: terminating pulse
        # 6: swing detected
        # machines:
        # ENABLED vs. DISABLED vs. JITTERED
        # states:
        # READY, REFRACTORY, ARMED, FIRING


        if self.Enabled:
            # ENABLED machine, has READY, REFRACTORY, FIRING states
            if self.state == self.READY:
                if self.spw_condition(n_arr):
                    self.stimulate()
                    self.new_event(events, 1)
                    self.state = self.FIRING
            elif self.state == self.FIRING:
                self.refractory_count_down = self.refractory_count_down_thresh-1
                self.state = self.REFRACTORY
                self.new_event(events, 5)
            elif self.state == self.REFRACTORY:
                self.refractory_count_down -= 1
                if self.refractory_count_down == 0:
                    self.state = self.READY
            else:
                # checking for a leftover ARMED state
                self.state = self.READY

        return events

    @staticmethod
    def handleEvents(eventType, sourceID, subProcessorIdx, timestamp, sourceIndex):
        """handle events passed from OE"""

    @staticmethod
    def handleSpike(self, electrode, sortedID, n_arr):
        """handle spikes passed from OE"""


pluginOp = spwrandom()

include '../plugin.pyx'
