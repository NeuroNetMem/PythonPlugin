# PythonPlugin 

A plugin for open-ephys enabling the insertion of Cython (Python code translated to C and compiled) into the open-ephys signal chain. 
Most of the Cython peculiarities are dealt with by a wrapper code, so that essentially usual, "pure" Python code may be used. 
A tutorial on how to write a python module will follow soon, however, the code in the examples under the `python-modules` directory may serve as good guidance for now.

## Installation Instruction

At the moment, the plugin is compatible with the Linux and MacOSX versions of Open Ephys. I don't have Windows development expertise, so I will not port it to Windows myseld. If you are interested in porting it to Windows, this is probably a fairly simple task for an experienced developer (most if not all of the work will be replacing the dlopen/dlsym UNIX-style DLL import with the Windows equivalent). Please do contact me, and I will support the port as far as I can. 

### Compile from source code

The Plugin is organized so that it can be compiled as much as possible outside of the main open-ephys source tree. Under Linux, a symlink to the Source/Plugins directory is however necessary. 
A recent Python version is required 
The Plugin needs to link to a recent enough version of Python. Development work was done with a recent [Anaconda Python](https://www.continuum.io/why-anaconda) distribution, supporting python 3.5 to 3.7. 


To compile, extract in a folder just outside the Open Ephys plugin-GUI source tree
e.g. 

```
$ ls src
plugin-GUI/
PythonPlugin/
etc...
```

The rest of the procedure is system dependent

#### Linux 

The script `build-linux.sh` should detect the version and location of the python installation automatically. It will use the one of the executable that is at the top of the PATH, so make sure that the shell you are running it from is properly configured

Under Ubuntu 16.04 and later:
- with default python install. This comes by default without a proper `distutils` package, and without the Python development environment, to install those run 
```
sudo apt install python3-distutils
sudo apt install python3-dev
```

To compile the python modules you will need (at least) Cython and numpy which may be installed by 
```
pip install cython
pip install numpy
```


- With Anaconda: everything should be detected automatically, so no further action is needed at compilation time. 
To compile the python modules you will need Cython which may be installed by 
```
conda install cython numpy
```
or even better make your virtual environment with all the packages that are needed by your module. 

- run `./build-linux.sh`. The Plugin should be compiled and copied to the neighboring plugin-GUI source tree. 

#### MacOSX
- With Anaconda: a detection script runs at compilation. Because the compilation environment gets evaluated by XCode before any of the build phases are run, you may need to build the project *twice*, the second time should succeed. If any XCode guru has a solution for that, that would be welcome. 

## Usage

### Create New Module Dirctory and Framework Code
- Navigate to python_modules directy from the command line.
```
cd PythonPlugin/python_modules
```
- Run module creation code, where "YourPluginName" is the name you choose for the plugin.
```
python generatePlugin.py YourPluginName
```
### Modifying Template Code
- Place data to be held in RAM within the __init__(self) function. For example, if you want to hold an "electrodoes" variable accessible by other functions in the class, initialize it as follows:
```
def __init__(self):
    """initialize object data"""
    self.Enabled = 1
    self.electrodes = 16
```

- The startup(self, sr) function is called after selecting the .so file. This allows for the sampling rate (sr) to be passed off to the python plugin. This is also a useful place to connect to an arduino (after importing the serial library), shown as follows:
```
def startup(self, sr):
    self.samplingRate = sr
    print (self.samplingRate)
    self.arduino = serial.Serial('/dev/tty.usbmodem45561', 57600)
    print ("Arduino: ", self.arduino)
```

- The params_config(self) functions allows for the python plugin to have various buttons and sliders. This allows for the module to be more dynamic. The following code shows how to create a toggle button:
```
def param_config(self):
    """return button, sliders, etc to be present in the editor OE side"""
    return [("toggle", "Enabled", True)]
```

- The bufferfunction(self,n_arr) function is where the voltage data comes in and events go out to the rest of the OE signal chain. The variable "n_arr" is a matrix of the voltage data, accessed as `n_arr[electode][sample]`. The function must return events, even if the events are empty. The following code shows how to send out an event if the minimum value in the buffer on electrode 12 is below a predefined threshold.
```
def bufferfunction(self, n_arr):
    events = []
    min = np.min(n_arr[12][:])
    if min < self.thresh:
        events.append({'type': 3, 'sampleNum': 10, 'eventId': 1})
    return events
```

- The handleEvents(eventType,sourceID,subProcessorIdx,timestamp,sourceIndex) function passes on events (but not spike events) generated elsewhere in the OE signal chain to the python plugin. The following code shows how to save the timestamps of these events.
```
def handleEvents(eventType,sourceID,subProcessorIdx,timestamp,sourceIndex):
    """handle events passed from OE"""
    self.eventBuffer.append(timestamp)
````

- The handleSpike(self,electrode,sortedID,n_arr) function passes on spike events generated elsewhere in the OE signal chain to the python plugin. the n_arr is an 18 element long spike waveform. 

### Compilation
- In the module's directory (i.e. "YourPluginName/") run setup.py. 
```
python setup.py build_ext --inplace
```
- If you get a warning about the numpy version, you can safely ignore it.

### Load Python Module in Open Ephys
- Drag PythonFilter into signal chain

![alt text](https://github.com/MemDynLab/PythonPlugin/blob/event_reciever/images/examplePic1.png)

- Click on the select file button
- Navigate to the module's directory in the file selector
- Double click on the .so file (or select the file and click "open")

![alt text](https://github.com/MemDynLab/PythonPlugin/blob/event_reciever/images/examplePic2.png)



 



