# PythonPlugin 

A plugin for open-ephys enabling the insertion of Cython (Python code translated to C and compiled) into the open-ephys signal chain. 
Most of the Cython peculiarities are dealt with by a wrapper code, so that essentially usual, "pure" Python code may be used. 
A tutorial on how to write a python module will follow soon, however, the code in the examples under the `python-modules` directory may serve as good guidance for now.

## Installation Instruction

At the moment, the plugin is compatible with the Linux and MacOSX versions of Open Ephys. I don't have Windows development expertise, so I will not port it to Windows myseld. If you are interested in porting it to Windows, this is probably a fairly simple task for an experienced developer (most if not all of the work will be replacing the dlopen/dlsym UNIX-style DLL import with the Windows equivalent). Please do contact me, and I will support the port as far as I can. 

### Compile from source code

The Plugin is organized so that it can be compiled as much as possible outside of the main open-ephys source tree. Under Linux, a symlink to the Source/Plugins directory is however necessary. 
A recent Python version is required 
The Plugin needs to link to a recent enough version of Python. Development work was done with a recent [Anaconda Python](https://www.continuum.io/why-anaconda) distribution, supporting python 3.5. 
By default, we expect Anaconda to be installed in `/usr/local/anaconda` , however this may be changed easily as explained below.

To compile, extract in a folder just outside the Open Ephys plugin-GUI source tree
e.g. 

```
$ ls src
plugin-GUI/
PythonPlugin/
etc...
```

The rest of the procedure is system dependent

####Linux 
- With Anaconda: edit `build-linux.sh` and change `CONDA_HOME` to the Anaconda installation directory (default `/usr/local/anaconda`), if needed. 
- With a different Python distribution: Edit `Builds/Linux/Makefile` and change the include and lib directories as needed. 
- run `./build-linux.sh`. The Plugin should be copied to the neighboring plugin-GUI source tree. 

####MacOSX
- With Anaconda: edit  `Builds/MacOS/Config/Plugin.xcconfig` and set `PYTHON_DIR` to the Anaconda installation directory
- With a different Python distribution: in the same file, edit `HEADER_SEARCH_PATHS` and `LIBRARY_SEARCH_PATHS` to the proper places. 
- Open `Builds/MacOS/PythonPlugin.xcodeproj` in XCode and compile


### Binary installation 
A binary installation (Linux only for the time being) is provided in XXX. This assumes that you have a suitable Anaconda Python distribution (see above) and that that resides in /usr/local/anaconda. If that is not the case, a symlink should be enough 
```bash 
sudo ln -s /my/install/anaconda /usr/local/anaconda
```

- Use the Binary-distributed version of Open-Ephys or compile it from source with the Release configuration. 
- Copy PythonPlugin.so to the `plugins` directory, and you are done. 



 



then 
$ cd PythonPlugin
$ ./build-linux.sh