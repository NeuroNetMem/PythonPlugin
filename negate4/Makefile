all:
	cython plugin.pyx
	gcc -g -O2 -fpic -c plugin.c -o plugin.o `python-config --includes` -I`python -c "import numpy; print numpy.get_include()"`
	gcc -g -O2 -shared -o negate4.so plugin.o `python-config --ldflags`

clean:
	rm -f plugin.c plugin.h *.o *.so
