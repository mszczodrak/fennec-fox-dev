
import os

from_str_1 = '<organization>'
to_str_1 = 'Columbia University'

from_str_2 = '<COPYRIGHT HOLDER>'
to_str_2 = 'COLUMBIA UNIVERSITY'

for root, dirs, files in os.walk("./src"):
	for f in files:
		path = "%s/%s" % (root, f)
		if os.path.isfile(path):
			cmd1 = "sed -i 's/%s/%s/g' %s"% (from_str_1, to_str_1, path)
			cmd2 = "sed -i 's/%s/%s/g' %s"% (from_str_2, to_str_2, path)
			print cmd1
			os.system(cmd1)
			print cmd2
			os.system(cmd2)
	
