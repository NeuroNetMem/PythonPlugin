#!/bin/bash

if hash python 2>/dev/null; then
	PYTHON_COMMAND=python
else
	PYTHON_COMMAND=python3
fi

export CONDA_HOME=$(${PYTHON_COMMAND} -c "from distutils import sysconfig; \
import re; \
z = sysconfig.get_config_var('prefix'); \
print(z)")

export PYTHON_VERSION=$(${PYTHON_COMMAND} -c "from distutils import sysconfig; \
import re; \
z = sysconfig.get_config_var('BLDLIBRARY'); \
m = re.search(r'-l(.*)', z); \
print(m.group(1))")

export CONFIG=Debug
ln -s ../../../PythonPlugin/PythonPlugin/ ../plugin-GUI/Source/Plugins/PythonPlugin
cd ../plugin-GUI/Builds/Linux/
make -f Makefile.plugins

