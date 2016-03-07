import numpy as np
cimport numpy as np
from cython cimport view
import serial
import scipy.signal


isDebug = False

class SWOFinder(object):
    def __init__(self):
        self.enabled = True
        self.refractory_count_down_thresh = 0
        self.refractory_count_down = 0
        self.refractory_time = 100. # time that the plugin will not react to trigger after one pulse
        self.refractory_time_min = 100.
        self.refractory_time_max = 6000.
        self.refractory_time_start = 2000.

        self.jitter_count_down_thresh = 0
        self.jitter_count_down = 0
        #self.jitter_time = 0. # in ms

        self.chan_in = 1
        self.chan_out = 0
        self.n_samples = 0
        self.chan_swo = 1
        self.band_lo_min = 0.1
        self.band_lo_max = 2.
        self.band_lo_start = 0.1
        self.band_lo = self.band_lo_start

        self.band_hi_min = 1.
        self.band_hi_max = 10.
        self.band_hi_start = 2. # TODO to be set in the interface
        self.band_hi = self.band_hi_start

        # self.thresh_min = 5.
        # self.thresh_max = 200.
        # self.thresh_start = 30.
        # self.threshold = self.thresh_start
        #
        #
        # self.swing_thresh_min = 10.
        # self.swing_thresh_max = 20000.
        # self.swing_thresh_start = 1000.
        # self.swing_thresh = self.swing_thresh_start

        self.jitter_time_min = 0.
        self.jitter_time_max = 2000.
        self.jitter_time_start = 0.
        self.jitter_time = self.jitter_time_start

        self.pulseNo = 0
        self.triggered = 0
        self.samplingRate = 0.
        self.polarity = 0
        self.filter_a = []
        self.filter_b = []
        self.arduino = None
        self.lfp_buffer_max_count = 500000
        self.lfp_buffer = np.zeros((self.lfp_buffer_max_count,))
        self.previous_val = np.nan
        self.cur_val = np.nan
        self.ASCENDING = False
        self.DESCENDING = True
        self.PEAK = False
        self.TROUGH = False
        self.READY=1
        self.ARMED=2
        self.REFRACTORY=3
        self.FIRING = 4
        self.state = self.READY

        print ("finished SPWfinder constructor")

    def startup(self, sampling_rate):
        self.samplingRate = sampling_rate
        print ('SR: ', self.samplingRate)

        try:
            self.filter_b, self.filter_a = scipy.signal.butter(3,
                                                     (self.band_hi/(self.samplingRate/2.)),
                                                     'lowpass')
        except Exception as e:
            print(e)
        print(self.filter_a)
        print(self.filter_b)
        #print(self.band_lo)
        print(self.band_hi)
        #print(self.band_lo/(self.samplingRate/2.))
        print(self.band_hi/(self.samplingRate/2.))
        self.enabled = 1
        try:
            self.arduino = serial.Serial('/dev/ttyACM0', 57600)
        except (OSError, serial.serialutil.SerialException):
            print("Can't open Arduino")

    def plugin_name(self):
        return "SPWFinder"

    def is_ready(self):
        return 1

    def param_config(self):
        chan_labels = range(1, 33)
        return (("toggle", "enabled", True),
                ("int_set", "chan_in", chan_labels),
                ("float_range", "jitter_time", self.jitter_time_min,
                 self.jitter_time_max, self.jitter_time_start),
                ("float_range", "refractory_time", self.refractory_time_min,
                 self.refractory_time_max, self.refractory_time_start)
                )

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
        #print("plugin start")
        if isDebug:
            print("shape: ", n_arr.shape)
        events = []
        cdef int chan_in
        cdef int chan_out
        chan_in = self.chan_in - 1
        self.chan_out = chan_in

        self.n_samples = int(n_arr.shape[1])

        if self.n_samples == 0:
            return events

        # setting up count down thresholds in units of samples
        self.refractory_count_down_thresh =  self.refractory_time * self.samplingRate / 1000.
        self.jitter_count_down_thresh = self.jitter_time * self.samplingRate / 1000.



        signal_to_filter = np.hstack((self.lfp_buffer, n_arr[chan_in,:]))
        #signal_to_filter = signal_to_filter - signal_to_filter[-1]
        # print('signal to filter, size = ', signal_to_filter.size)
        # print('min: ', np.min(signal_to_filter), ' max: ', np.max(signal_to_filter))
        filtered_signal =  scipy.signal.filtfilt(self.filter_b, self.filter_a, signal_to_filter)
        n_arr[self.chan_out,:] = filtered_signal[self.lfp_buffer.size:]
        self.cur_val = np.mean(n_arr[self.chan_out,:])
        # print('min: ', np.min(n_arr[self.chan_out,:]), ' max: ', np.max(n_arr[self.chan_out,:]))
        self.lfp_buffer = signal_to_filter
        if self.lfp_buffer.size > self.lfp_buffer_max_count:
            self.lfp_buffer = self.lfp_buffer[-self.lfp_buffer_max_count:]


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

        self.PEAK = False
        self.TROUGH = False
        if self.ASCENDING:
            if self.cur_val < self.previous_val:
                print('PEAK')
                self.PEAK = True
                self.ASCENDING = False
                self.DESCENDING = True
        elif self.DESCENDING:
            if self.cur_val > self.previous_val:
                print('TROUGH')
                self.TROUGH = True
                self.ASCENDING = True
                self.DESCENDING = False

        self.previous_val = self.cur_val

        if self.state == self.READY:
            if self.PEAK:
                if self.jitter_count_down_thresh > 0:
                    self.jitter_count_down = self.jitter_count_down_thresh
                    self.state = self.ARMED
                    print('ARMED')
                    self.new_event(events, 1, 1)
                else:
                    if self.enabled:
                        self.stimulate()
                        self.new_event(events, 2)
                        self.new_event(events, 1)
                    else:
                        self.new_event(events, 1, 3)
                    self.state = self.FIRING
                    print('FIRING')

        elif self.state == self.ARMED:
            if self.jitter_count_down == self.jitter_count_down_thresh:
                self.new_event(events, 5, 1)
            self.jitter_count_down -= self.n_samples
            if self.jitter_count_down <= 0:
                if self.enabled:
                    self.stimulate()
                    self.new_event(events, 2)
                    self.new_event(events, 1)
                else:
                    self.new_event(events, 1, 3)
                self.state = self.FIRING
                print('FIRING')

        elif self.state == self.FIRING:
            self.refractory_count_down = self.refractory_count_down_thresh-1
            self.state = self.REFRACTORY
            print('REFRACTORY')
            self.new_event(events, 5)
            self.new_event(events, 5, 3)
        elif self.state == self.REFRACTORY:
            self.refractory_count_down -= self.n_samples
            print('REFRACTORY countdown is ', self.refractory_count_down)
            if self.refractory_count_down <= 0:
                self.state = self.READY
                print('READY')



        return events


pluginOp = SWOFinder()

include "../plugin.pyx"