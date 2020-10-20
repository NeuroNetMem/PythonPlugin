# PythonPlugin

A plugin for open-ephys enabling the insertion of Cython (Python code translated to C and compiled) into the open-ephys signal chain.
Most of the Cython peculiarities are dealt with by a wrapper code, so that essentially usual, "pure" Python code may be used.
A tutorial on how to write a python module can be found below. Example modules can be found under the `python-modules` directory.

## Installation Instruction

### Compile from source code

The Plugin is organized so that it can be compiled as much as possible outside of the main open-ephys source tree.
A recent Python version is required.
The Plugin needs to link to a recent enough version of Python.
Development work was done with a recent [Anaconda Python](https://www.continuum.io/why-anaconda) distribution, supporting python 3.5 to 3.8.
Windows users must use python 3.6 (see below).
Onlinux it also work with standard pip+virtualenv installation.

Currently, only Cython version 0.28.2 is supported.
Recently downloaded or upgraded versions of Anaconda will come with version 0.29.2,
which will cause the application to crash upon loading a python module.
To avoid this, create a virtual enviroment with the correct versions of python and cython. See below.


To compile the plugin, extract in a folder just outside the Open Ephys plugin-GUI source tree
e.g.

```
$ ls src
plugin-GUI/
PythonPlugin/
etc...
```

The rest of the procedure is system dependent

#### Linux with conda

Example with python3.6

```
conda create -n oeEnv python=3.6
```

```
source activate oeEnv
conda install cython=0.28.2 numpy
```


```
cd /home/XXXX/PythonPlugin/Build
make
make install
```

#### Linux with pip + virtualenv

Here a recipe that need to be adapted depending the virtual system.

Here a working recipe with : **Unbutu 20.04 + python3.8 + plugin-GUI 0.5**

Install system packge
```
sudo apt install python3-distutils
sudo apt install python3-dev
sudo apt install virtualenvwrapper
sudo apt install gcc-8 g++-8 
```

Create environement
```
mkvirtualenv --python=/usr/bin/python3.8 oeEnv
```

Enter in env and update pip **(very important!!!)**
```
workon oeEnv 
# (or source /home/myusername/.virtualenvs/oeEnv/bin/activate)
pip install --upgarde pip
```

And install package
```
pip install cython==0.28.2
```

Build the C++
gcc must forced to version 8 because due to juice the system have gcc-9 by default
```
cd /home/myusername/path_to_oe/PythonPlugin/Build
export CC=gcc-8 && export CXX=g++-8
export CONDA_HOME=/home/myusername/.virtualenvs/oeEnv
cmake -DPYTHON_PATH=/home/myusername/.virtualenvs/oeEnv/lib/python3.8/site-packages ..
make
make install
```


#### MacOSX

- With Anaconda: a detection script runs at compilation. Because the compilation environment gets evaluated
by XCode before any of the build phases are run, you may need to build the project *twice*,
the second time should succeed. If any XCode guru has a solution for that, that would be welcome.


#### Windows

**TODO : the following is not tested**

- Install Anaconda, python3.6 ONLY (see compilation section)





If you created a virtual environment for Open Ephys (as suggested below) or installed Anaconda in somewhere other than the default (your home directory), you need to tell the plugin where your Python root is by setting the `CONDA_HOME` environment variable. Follow these steps:

1. From the Start menu, start typing "environment" and then select "Edit environment variables for your account"
2. Click "New..." to create a new variable. Enter `CONDA_HOME` as the name and the path to your Python 3.6 root folder as the value. For example, if you are using a conda environment called `oeEnv`, this would be something like `C:\Users\your_username\Anaconda3\envs\oeEnv`. Do _not_ use a trailing slash. Click OK twice to save.
3. Restart Visual Studio completely if you have it open. Open the Plugins solution and select Project > Rescan Solution to make sure the `PYTHON_HOME_NAME` macro gets updated.

```
activate oeEnv
```

Install required modules:

```
conda install cython=0.28.2 numpy
```


```
cd c:\Users\myusername\path_to_oe\PythonPlugin\Build
cmake ..
make 
make install
```



## Usage

### Create New Module Directory and Framework Code
- Navigate to python_modules directy from the command line.
```
cd PythonPlugin/python_modules
```
- Run module creation code, where "YourPluginName" is the name you choose for the plugin.
```
python generatePlugin.py YourPluginName
```
### Modifying Template Code
- Place data to be held in RAM within the __init__(self) function. For example, if you want to hold an "electrodes"
  variable accessible by other functions in the class, initialize it as follows:
```
def __init__(self):
    """initialize object data"""
    self.Enabled = 1
    self.electrodes = 16
```

- The startup(self, sr) function is called after selecting the .so file. This allows for the sampling rate (sr) 
  to be passed off to the python plugin. This is also a useful place to connect to an arduino (after importing the serial library), shown as follows:
```
def startup(self, sr):
    self.samplingRate = sr
    print (self.samplingRate)
    self.arduino = serial.Serial('/dev/tty.usbmodem45561', 57600)
    print ("Arduino: ", self.arduino)
```

- The params_config(self) functions allows for the python plugin to have various buttons and sliders.
  This allows for the module to be more dynamic. The following code shows how to create a toggle button:
```
def param_config(self):
    """return button, sliders, etc to be present in the editor OE side"""
    return [("toggle", "Enabled", True)]
```

- The bufferfunction(self,n_arr) function is where the voltage data comes in and events go out to the
  rest of the OE signal chain. The variable "n_arr" is a matrix of the voltage data, accessed
  as `n_arr[electode][sample]`. The function must return events, even if the events are empty.
  The following code shows how to send out an event if the minimum value in the buffer on electrode
  12 is below a predefined threshold.
```
def bufferfunction(self, n_arr):
    events = []
    min = np.min(n_arr[12][:])
    if min < self.thresh:
        events.append({'type': 3, 'sampleNum': 10, 'eventId': 1})
    return events
```

- The handleEvents(eventType,sourceID,subProcessorIdx,timestamp,sourceIndex) function passes on events
  (but not spike events) generated elsewhere in the OE signal chain to the python plugin.
  The following code shows how to save the timestamps of these events.
```
def handleEvents(eventType,sourceID,subProcessorIdx,timestamp,sourceIndex):
    """handle events passed from OE"""
    self.eventBuffer.append(timestamp)
````

- The handleSpike(self,electrode,sortedID,n_arr) function passes on spike events generated elsewhere
  in the OE signal chain to the python plugin. the n_arr is an 18 element long spike waveform.

### Compilation of a python plugin


Be sure that you have a gcc version 8

```
export CC=gcc-8 && export CXX=g++-8
```

To activate the enviroment on Linux or Mac:
```
source activate oeEnv
```

or for virtualenvwrapper:
```
workon oeEnv
```

or for windows:
```
activate oeEnv
```



For more information on virtual enviroments, please click [here](https://conda.io/projects/conda/en/latest/user-guide/tasks/manage-environments.html).

- To compile the python module with cython, run setup.py in the module's directory (i.e. "YourPluginName/").
```
python setup.py build_ext --inplace
```
- If you get a warning about the NumPy version, you can safely ignore it.

### Load Python Module in Open Ephys
- Drag Python Filter into signal chain
- Click on the select file button
- Navigate to the module's directory in the file selector
- Double click on the .so file (or select the file and click "open")

![alt text](https://github.com/MemDynLab/PythonPlugin/blob/event_reciever/images/demonstration.gif)
