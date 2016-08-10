#!/bin/bash
ln -s PythonPlugin/Source/ ../plugin-GUI/Source/Plugins/PythonPlugin
cd ../plugin-GUI/Builds/Linux/
make -f Makefile.plugins

