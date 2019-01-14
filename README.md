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

`cd PythonPlugin/python_modules`

- Run module creation code, where "YourPluginName" is the name you choose for the plugin.

`python generatePlugin.py YourPluginName`

### Modifying Framework Code
### Compilation
- In the module's directory (i.e. "YourPluginName/"), run setup.py.

`python setup.py build_ext --inplace`

### Load Python Module in Open Ephys
- Drag PythonFilter into signal chain
- Click on the select file button
- Navigate to the module's directory in the file selector
- Double click on the .so file



 



