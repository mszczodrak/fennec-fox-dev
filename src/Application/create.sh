#!/bin/bash
# Author: Marcin Szczodrak
# msz@cs.columbia.edu

BASE_EXAMPLE="nullApp"
NEW_MODULE=$1

PP="_"
EXPECTED_ARGS=1
C="C.nc"
P="P.nc"
H=".h"
OLD_C=$BASE_EXAMPLE$C
OLD_P=$BASE_EXAMPLE$P
OLD_H=$BASE_EXAMPLE$H
NEW_C=$NEW_MODULE$C
NEW_P=$NEW_MODULE$P
NEW_H=$NEW_MODULE$H

if [ $# -ne $EXPECTED_ARGS ]; then
	echo "Usage" $0 "<new_module_name>";
	exit
fi


cp -R $BASE_EXAMPLE $NEW_MODULE
cd $NEW_MODULE


sed "s/$BASE_EXAMPLE/$NEW_MODULE/g" $OLD_C > $NEW_C
sed "s/$BASE_EXAMPLE/$NEW_MODULE/g" $OLD_P > $NEW_P
sed "s/$BASE_EXAMPLE/$NEW_MODULE/g" $OLD_H > $NEW_H


rm $BASE_EXAMPLE*

cd ..

echo "Looks like SUCCESS"
echo
echo -n "Don't forget to add the following line to "
echo -n $FENNEC_FOX_LIB
echo "/src/support/sfc/fennec.sfl"
echo
echo -n "use "
echo -n " <layer>"
echo -n " <give_it_a_name> "
echo -n $PWD/
echo $NEW_MODULE

