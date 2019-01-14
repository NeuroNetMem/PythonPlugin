from distutils.core import setup, Extension
from Cython.Build import cythonize
import numpy

setup(
        name= "EXAMPLE",
        ext_modules = cythonize("EXAMPLE.pyx"),
        include_dirs = [numpy.get_include()]
        )


