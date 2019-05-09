import sys
import os
name = str(sys.argv[1])
os.mkdir(name)

with open(os.path.join(name, 'setup.py'),'w+') as w:
	with open('template/setup.py','r') as f:
		for line in f:
			toWrite = line.replace("EXAMPLE", name)
			w.write(toWrite)

with open(os.path.join(name, name +'.pyx'),'w+') as w:
	with open('template/template.pyx','r') as f:
		for line in f:
			toWrite = line.replace("EXAMPLE", name)
			w.write(toWrite)
