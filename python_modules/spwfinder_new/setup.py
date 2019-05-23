from distutils.core import setup, Extension
from Cython.Build import cythonize
import numpy

setup(
        name= "spwfinder_new",
        ext_modules = cythonize(Extension('spwfinder_new',sources=["spwfinder_new.pyx"],export_symbols=['pluginStartup','pluginisready','getParamNum','getParamConfig','pluginFunction','eventFunction','spikeFunction','setIntParam','setFloatParam','getIntParam','getFloatParam'])),
        include_dirs = [numpy.get_include()]
        )
