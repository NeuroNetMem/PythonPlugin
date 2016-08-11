#!/bin/bash
export CONDA_HOME=/usr/local/anaconda
export CONFIG=Release
ln -s ../../../PythonPlugin/PythonPlugin/ ../plugin-GUI/Source/Plugins/PythonPlugin
cd ../plugin-GUI/Builds/Linux/
make -f Makefile.plugins

