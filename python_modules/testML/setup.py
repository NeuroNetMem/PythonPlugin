from distutils.core import setup, Extension
from Cython.Build import cythonize
import numpy

setup(
	name= "testML",
	ext_modules = cythonize("testML.pyx"),
	include_dirs = [numpy.get_include()]
	)
