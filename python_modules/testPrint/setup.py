from distutils.core import setup, Extension
from Cython.Build import cythonize
from Cython.Compiler import Options
import numpy

Options.embed = "main"


setup(
        name= "testPrint",
        ext_modules = cythonize("testPrint.pyx"),
        include_dirs = [numpy.get_include()]
        )
