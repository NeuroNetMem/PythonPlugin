#!/bin/bash
export CONDA_HOME=$(python -c "from distutils import sysconfig; \
import re; \
z = sysconfig.get_config_var('prefix'); \
print(z)")

export PYTHON_VERSION=$(python -c "from distutils import sysconfig; \
import re; \
z = sysconfig.get_config_var('BLDLIBRARY'); \
m = re.search(r'-l(.*)', z); \
print(m.group(1))")

export CONFIG=Debug
ln -s ../../../PythonPlugin/PythonPlugin/ ../plugin-GUI/Source/Plugins/PythonPlugin
cd ../plugin-GUI/Builds/Linux/
make -f Makefile.plugins

