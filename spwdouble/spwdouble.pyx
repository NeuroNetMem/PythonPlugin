import numpy as np
cimport numpy as np
from cython cimport view
import serial
import scipy.signal


isDebug = False

class SPWFinder(object):
    def __init__(self):
        self.enabled = True
        self.refractory_count_down_thresh = 0
        self.refractory_count_down = 0
        self.refractory_time = 100. # time that the plugin will not react to trigger after one pulse
        self.double_count_down_thresh = 0
        self.double_count_down = 0
        self.double_time = 200.
        self.double_rate = 1. / 3.
        self.chan_in = 1
        self.chan_out = 0
        self.n_samples = 0
        self.chan_ripples = 1
        self.band_lo_min = 50.
        self.band_lo_max = 200.
        self.band_lo_start = 100.
        self.band_lo = self.band_lo_start

        self.band_hi_min = 100.
        self.band_hi_max = 500.
        self.band_hi_start = 300.
        self.band_hi = self.band_hi_start

        self.thresh_min = 5.
        self.thresh_max = 200.
        self.thresh_start = 30.
        self.threshold = self.thresh_start


        self.swing_thresh_min = 10.
        self.swing_thresh_max = 20000.
        self.swing_thresh_start = 1000.
        self.swing_thresh = self.swing_thresh_start

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
        self.TRIGGERED2 = 5
        self.FIRING2 = 6
        self.state = self.READY

        print ("finished SPWfinder constructor")

    def startup(self, sampling_rate):
        self.samplingRate = sampling_rate
        print (self.samplingRate)

        self.filter_b, self.filter_a = scipy.signal.butter(3,
                                                     (self.band_lo/(self.samplingRate/2), self.band_hi/(self.samplingRate/2)),
                                                     'pass')
        print(self.filter_a)
        print(self.filter_b)
        print(self.band_lo)
        print(self.band_hi)
        print(self.band_lo/(self.samplingRate/2))
        print(self.band_hi/(self.samplingRate/2))
        self.enabled = 1
        try:
            self.arduino = serial.Serial('/dev/tty.usbmodem1411', 57600)
        except (OSError, serial.serialutil.SerialException):
            print("Can't open Arduino")

    def plugin_name(self):
        return "SPWFinder"

    def is_ready(self):
        return 1

    def param_config(self):
        chan_labels = range(32)
        return (("toggle", "enabled", True),
                ("int_set", "chan_in", chan_labels),
                ("float_range", "threshold", self.thresh_min, self.thresh_max, self.thresh_start),
                ("float_range", "swing_thresh", self.swing_thresh_min, self.swing_thresh_max, self.swing_thresh_start))

    def spw_condition(self, n_arr):
        return (np.mean(n_arr[self.chan_out+1,:]) > self.threshold) and self.swing_state == self.NOT_SWINGING

    def stimulate(self):
        try:
            self.arduino.write('1'* 64)
        except AttributeError:
            print("Can't send pulse")
        self.pulseNo += 1
        print("generating pulse ", self.pulseNo)

    def new_event(self, events, code, channel=0, timestamp=None):
        if not timestamp:
            timestamp = self.n_samples
        events.append({'type': 3, 'sampleNum': timestamp, 'eventId': code, 'eventChannel': channel})

    def bufferfunction(self, n_arr):
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
        frame_time = 1000. * self.n_samples / self.samplingRate
        self.refractory_count_down_thresh = int(self.refractory_time / frame_time)
        self.double_count_down_thresh = int(self.double_time / frame_time)
        self.swing_count_down_thresh = int(self.swing_down_time / frame_time)

        signal_to_filter = np.hstack((self.lfp_buffer, n_arr[chan_in,:]))
        signal_to_filter = signal_to_filter - signal_to_filter[-1]
        filtered_signal = scipy.signal.lfilter(self.filter_b, self.filter_a, signal_to_filter)
        n_arr[self.chan_out,:] = filtered_signal[self.lfp_buffer.size:]
        self.lfp_buffer = np.append(self.lfp_buffer, n_arr[chan_in,:])
        if self.lfp_buffer.size > self.lfp_buffer_max_count:
            self.lfp_buffer = self.lfp_buffer[-self.lfp_buffer_max_count:]
        n_arr[self.chan_out+1,:] = np.fabs(n_arr[self.chan_out,:])
        n_arr[self.chan_out+2,:] = 5. *np.mean(n_arr[self.chan_out+1,:]) * np.ones((1,self.n_samples))


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

        if not self.enabled:
            # DISABLED machine, has only READY state
            if self.spw_condition(n_arr):
                self.new_event(events, 3)
        else:
            # ENABLED machine, has READY, REFRACTORY, FIRING states
            if self.state == self.READY:
                if self.spw_condition(n_arr):
                    self.stimulate()
                    self.new_event(events, 1)
                    self.state = self.FIRING
            elif self.state == self.FIRING:
                if np.random.random() < self.double_rate:
                    self.double_count_down = self.double_count_down_thresh-1
                    print('double')
                    self.state = self.TRIGGERED2
                else:
                    self.refractory_count_down = self.refractory_count_down_thresh-1
                    self.state = self.REFRACTORY
                self.new_event(events, 5)
            elif self.state == self.TRIGGERED2:
                self.double_count_down -= 1
                if self.double_count_down <= 0:
                    self.stimulate()
                    self.new_event(events, 1)
                    self.state = self.FIRING2
            elif self.state == self.FIRING2:
                self.refractory_count_down = self.refractory_count_down_thresh-1
                self.state = self.REFRACTORY
                self.new_event(events, 5)
            elif self.state == self.REFRACTORY:
                self.refractory_count_down -= 1
                if self.refractory_count_down <= 0:
                    self.state = self.READY
            else:
                # checking for a leftover ARMED state
                self.state = self.READY


        return events


pluginOp = SPWFinder()

include "../plugin.pyx"