from distutils.core import setup, Extension
from Cython.Build import cythonize
import numpy

setup(
        name= "test2",
        ext_modules = cythonize("test2.pyx"),
        include_dirs = [numpy.get_include()]
        )


