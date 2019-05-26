from distutils.core import setup, Extension
from Cython.Build import cythonize
import numpy

setup(
        name= "spwrandom",
        ext_modules = cythonize(Extension('spwrandom',sources=["spwrandom.pyx"],export_symbols=['pluginStartup','pluginisready','getParamNum','getParamConfig','pluginFunction','eventFunction','spikeFunction','setIntParam','setFloatParam','getIntParam','getFloatParam'])),
        include_dirs = [numpy.get_include()]
        )
