#!/bin/bash

rm EnvSerialMsg.py*
cd ./sf
make clean
rm Makefile Makefile.in aclocal.m4 autoconf.h autoconf.h.in config.log config.status 
rm configure serialpacket.c serialpacket.h serialprotocol.h stamp-h1
rm -rf autom4te.cache config-aux
