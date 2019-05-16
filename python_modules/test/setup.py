from distutils.core import setup, Extension
from Cython.Build import cythonize
import numpy

setup(
        name= "test",
        ext_modules = cythonize(Extension('test',sources=["test.pyx"],export_symbols=['pluginStartup','pluginisready','getParamNum','getParamConfig','pluginFunction','eventFunction','spikeFunction','setIntParam','setFloatParam','getIntParam','getFloatParam'])),
        include_dirs = [numpy.get_include()]
        )
