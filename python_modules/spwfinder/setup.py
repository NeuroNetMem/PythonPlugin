from distutils.core import setup, Extension
from Cython.Build import cythonize
import numpy

setup(
        name= "spwfinder",
        ext_modules = cythonize(Extension('spwfinder',sources=["spwfinder.pyx"],export_symbols=['pluginStartup','pluginisready','getParamNum','getParamConfig','pluginFunction','eventFunction','spikeFunction','setIntParam','setFloatParam','getIntParam','getFloatParam'])),
        include_dirs = [numpy.get_include()]
        )
