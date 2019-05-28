from distutils.core import setup, Extension
from Cython.Build import cythonize
import numpy
import runpy

cfg = runpy.run_path('../.config.py')


setup(
    name="pulse_test_delay",
    ext_modules=cythonize(Extension('pulse_test_delay', sources=["pulse_test_delay.pyx"],
                                    export_symbols=['pluginStartup', 'pluginisready', 'getParamNum', 'getParamConfig',
                                                    'pluginFunction', 'eventFunction', 'spikeFunction', 'setIntParam',
                                                    'setFloatParam', 'getIntParam', 'getFloatParam'])),
    include_dirs=[numpy.get_include(), cfg['PYTHON_PLUGIN_SRC_DIR']]
)
