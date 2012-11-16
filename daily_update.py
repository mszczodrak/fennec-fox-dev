#!/usr/bin/python
# Author: Marcin Szczodrak
# Feb 18, 2011

import os
import shutil
import copy

SRC_FOLDER_NAME="fennecfox"
#REMOTE_SERVER="embedded.cs.columbia.edu"
#REMOTE_DIRECTORY="/home/www-data/web2py/applications/lpwn/static/software"
#REMOTE_DESTINATION="%s:%s/%s"%(REMOTE_SERVER, REMOTE_DIRECTORY, SRC_FOLDER_NAME)
#REMOTE_USER="www-data"
REMOTE_SERVER="clic.cs.columbia.edu"
REMOTE_DIRECTORY="html/projects/source"
REMOTE_DESTINATION="%s:%s"%(REMOTE_SERVER, REMOTE_DIRECTORY)
REMOTE_USER="msz"
SOURCE_LIST="pub_packages.txt"
RELEASE_NOTE = "RELEASE_NOTE"

os.mkdir(SRC_FOLDER_NAME)

try:
	os.system("fennec clean")
except:
	pass

fin = open(SOURCE_LIST, "r")

for line in fin.readlines():

	if line[0] == "#" or len(line) < 6:
		continue

	li = line.split('/')	
	path = "/".join(li[:-1])

	os.system("mkdir -p %s/%s"%(SRC_FOLDER_NAME, path))

	os.system("cp -pr ./%s ./%s/%s"%(line.rstrip(), SRC_FOLDER_NAME, path))

fin.close()

os.system("echo 'Release date:' >> ./%s/%s"%(SRC_FOLDER_NAME, RELEASE_NOTE))
os.system("date >> ./%s/%s"%(SRC_FOLDER_NAME, RELEASE_NOTE))
os.system("tar -cvvf %s.tar %s"%(SRC_FOLDER_NAME, SRC_FOLDER_NAME))
os.system("gzip %s.tar "%(SRC_FOLDER_NAME))
os.system("rm -rf %s"%(SRC_FOLDER_NAME))

os.system("scp %s.tar.gz %s@%s/%s.tar.gz"% (SRC_FOLDER_NAME, REMOTE_USER, REMOTE_DESTINATION, SRC_FOLDER_NAME))
os.system("rm %s.tar.gz"%(SRC_FOLDER_NAME))

