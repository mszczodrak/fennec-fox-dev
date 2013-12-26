#!/bin/bash
# Author: Marcin Szczodrak
# msz@cs.columbia.edu

BASE_EXAMPLE="null"
NEW_MODULE=$1

PP="_"
EXPECTED_ARGS=1
LAYER="Mac"
FULL_LAYER_NAME="mac"
C="C.nc"
P="P.nc"
H=".h"
OLD_C=$BASE_EXAMPLE$LAYER$C
OLD_P=$BASE_EXAMPLE$LAYER$P
OLD_H=$BASE_EXAMPLE$LAYER$H
NEW_C=$NEW_MODULE$LAYER$C
NEW_P=$NEW_MODULE$LAYER$P
NEW_H=$NEW_MODULE$LAYER$H

if [ $# -ne $EXPECTED_ARGS ]; then
	echo "Usage" $0 "<new_module_name>";
	exit
fi


cp -R $BASE_EXAMPLE $NEW_MODULE
cd $NEW_MODULE


sed "s/null/$NEW_MODULE/g" $OLD_C > $NEW_C
sed "s/null/$NEW_MODULE/g" $OLD_P > $NEW_P
sed "s/null/$NEW_MODULE/g" $OLD_H > $NEW_H


rm $BASE_EXAMPLE*
rm temp

cd ..

echo "Looks like SUCCESS"
echo
echo -n "Don't forget to add the following line to "
echo -n $FENNEC_FOX_LIB
echo "/src/support/sfc/fennec.sfl"
echo
echo -n "use "
echo -n $FULL_LAYER_NAME
echo -n " <give_it_a_name> "
echo -n $PWD/
echo $NEW_MODULE

