from distutils.core import setup, Extension
from Cython.Build import cythonize
import numpy

setup(
        name= "test2",
        ext_modules = cythonize(Extension('test2',sources=["test2.pyx"],export_symbols=['pluginStartup','pluginisready','getParamNum','getParamConfig','pluginFunction','eventFunction','spikeFunction','setIntParam','setFloatParam','getIntParam','getFloatParam'])),
        include_dirs = [numpy.get_include()]
        )
