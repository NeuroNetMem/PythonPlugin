#!/bin/bash
ln -s ../../../PythonPlugin/PythonPlugin/ ../plugin-GUI/Source/Plugins/PythonPlugin
cd ../plugin-GUI/Builds/Linux/
make -f Makefile.plugins

