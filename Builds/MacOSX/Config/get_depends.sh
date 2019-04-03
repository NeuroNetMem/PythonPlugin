#!/bin/bash 


. ~/.bash_profile

CONFIG_DIR=${PROJECT_DIR}/Config

PYTHON_DIR=$(python -c "from distutils import sysconfig; \
import re; \
z = sysconfig.get_config_var('prefix'); \
print(z)")

PYTHON_VERSION=$(python -c "from distutils import sysconfig; \
import re; \
z = sysconfig.get_config_var('BLDLIBRARY'); \
m = re.search(r'-l(.*)', z); \
print(m.group(1))")

echo $PYTHON_DIR
echo $PYTHON_VERSION

sed -e "s%#PYTHON_DIR#%${PYTHON_DIR}%" -e "s%#PYTHON_VERSION#%${PYTHON_VERSION}%" <${CONFIG_DIR}/Plugin.xcconfig.tmpl >${CONFIG_DIR}/Plugin.xcconfig
