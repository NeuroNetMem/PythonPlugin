from distutils.core import setup, Extension
from Cython.Build import cythonize
from Cython.Compiler import Options
import numpy

Options.embed = "main"


setup(
        name= "testPrint",
        ext_modules = cythonize(Extension('testPrint',sources=["testPrint.pyx"],export_symbols=['pluginStartup','pluginisready','getParamNum','getParamConfig','pluginFunction','eventFunction','spikeFunction','setIntParam','setFloatParam','getIntParam','getFloatParam',])),
        include_dirs = [numpy.get_include()]
        )
