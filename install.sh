#!/bin/bash
# Marcin Szczodrak

sed -i '/FENNEC_FOX_LIB/ d' ~/.profile
echo "export FENNEC_FOX_LIB=`pwd`/src" >> ~/.profile
echo "Please logout or at least enter 'source ~/.profile'"


