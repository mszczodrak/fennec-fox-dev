#!/bin/bash
# Marcin Szczodrak
# This program syncs fennec-fox-dev repo with the public one

DEV_REPO=`pwd`
PUB_REPO=`pwd`/../fennec-fox
PUB_CODE=pubs

echo "Clean Repo"
fennec clean

echo "Delete all files from $PUB_REPO"
rm -rf $PUB_REPO/*

while read -r path
do
	echo "Copying - $path"
	cp -R  --parents $path $PUB_REPO
done < "$PUB_CODE"

cd $PUB_REPO
git add *
git commit -am "Sync from `date`"
git push

