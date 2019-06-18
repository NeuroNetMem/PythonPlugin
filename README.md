# PythonPlugin

A plugin for open-ephys enabling the insertion of Cython (Python code translated to C and compiled) into the open-ephys signal chain.
Most of the Cython peculiarities are dealt with by a wrapper code, so that essentially usual, "pure" Python code may be used.
A tutorial on how to write a python module can be found below. Example modules can be found under the `python-modules` directory.

## Installation Instruction

### Compile from source code

The Plugin is organized so that it can be compiled as much as possible outside of the main open-ephys source tree. Under Linux, a symlink to the Source/Plugins directory is however necessary.
A recent Python version is required.
The Plugin needs to link to a recent enough version of Python. Development work was done with a recent [Anaconda Python](https://www.continuum.io/why-anaconda) distribution, supporting python 3.5 to 3.7. Windows users must use python 3.6 (see below).

To compile the plugin, extract in a folder just outside the Open Ephys plugin-GUI source tree
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

#### Windows
- Install Anaconda, python3.6 ONLY (see compilation section), then add the required modules:
```
conda install cython numpy
```

- Copy the folder `PythonPlugin` to your plugin-GUI source tree under `Source\Plugins`.

- Copy the contents of `WindowsPlugin` to a new folder in your plugin-GUI source tree called `Builds\VisualStudio2013\Plugins\PythonPlugin`.

- Open the Plugins solution in Visual Studio and add the Python plugin by right-clicking the top-level solution in the Solution Explorer, selecting `Add > Existing Project`, and opening the `Python.vcxproj` project file that you just copied into the `PythonPlugin` build folder.

- If you created a virtual environment for Open Ephys (as suggested below) or installed Anaconda in somewhere other than the default (your home directory), you need to tell the plugin where your Python root is by setting the `CONDA_HOME` environment variable. Follow these steps:

1. From the Start menu, start typing "environment" and then select "Edit environment variables for your account"
2. Click "New..." to create a new variable. Enter `CONDA_HOME` as the name and the path to your Python 3.6 root folder as the value. For example, if you are using a conda environment called `oeEnv`, this would be something like `C:\Users\your_username\Anaconda3\envs\oeEnv`. Do _not_ use a trailing slash. Click OK twice to save.
3. Restart Visual Studio completely if you have it open. Open the Plugins solution and select Project > Rescan Solution to make sure the `PYTHON_HOME_NAME` macro gets updated.

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
- Place data to be held in RAM within the __init__(self) function. For example, if you want to hold an "electrodes" variable accessible by other functions in the class, initialize it as follows:
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
Currently, only Cython version 0.28.2 is supported. Recently downloaded or upgraded versions of Anaconda will come with version 0.29.2, which will cause the application to crash upon loading a python module. To avoid this, create a virtual enviroment with the correct versions of python and cython by running:

```
conda create -n oeEnv python=3.6 cython=0.28.2
```
To activate the enviroment on Linux or Mac:
```
source activate oeEnv
```
To activate the enviroment on Windows:
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
