from distutils.core import setup, Extension
from Cython.Build import cythonize
import numpy

setup(
        name= "test",
        ext_modules = cythonize("test.pyx"),
        include_dirs = [numpy.get_include()]
        )


