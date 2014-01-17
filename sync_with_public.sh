#!/bin/bash
# Marcin Szczodrak

DEV=./
PUB=../fennec-fox
MAIN_FOLDER=src
PUBS=pubs

echo "Delete pub repo files"
rm -rf $PUB/$MAIN_FOLDER

while read -r path
do
	echo "Name read from file - $path"
	cp -R  --parents $path $PUB
done < "$PUBS"

cd $PUB
git add *

