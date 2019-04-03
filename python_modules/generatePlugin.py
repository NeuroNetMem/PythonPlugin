import sys
from subprocess import call
call(["mkdir",str(sys.argv[1])])
w = open(str(sys.argv[1])+'/'+'setup.py','w+')
with open('template/setup.py','r') as f:
	for line in f:
		toWrite = line.replace("EXAMPLE",str(sys.argv[1]))
		w.write(toWrite)
w.close()
f.close()
w = open(str(sys.argv[1])+'/'+str(sys.argv[1])+'.pyx','w+')
with open('template/template.pyx','r') as f:
	for line in f:
		toWrite = line.replace("EXAMPLE",str(sys.argv[1]))
		w.write(toWrite)
w.close()
f.close()
