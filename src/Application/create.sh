#!/bin/bash
#
# Copyright (c) 2010 Columbia University. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
#
# - Redistributions of source code must retain the above copyright
#   notice, this list of conditions and the following disclaimer.
# - Redistributions in binary form must reproduce the above copyright
#   notice, this list of conditions and the following disclaimer in the
#   documentation and/or other materials provided with the
#   distribution.
# - Neither the name of the copyright holder nor the names of
#   its contributors may be used to endorse or promote products derived
#   from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
# FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL
# THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
# INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
# STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
# OF THE POSSIBILITY OF SUCH DAMAGE.
#
#
# @author: Marcin Szczodrak
# @email: msz@cs.columbia.edu
# @updated: November 26 2012
#

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
sed -i "/^[ ]*\*\|^\/\*/ d" $NEW_C
sed -i "/^[ ]*\*\|^\/\*/ d" $NEW_P
sed -i "/^[ ]*\*\|^\/\*/ d" $NEW_H
echo "$NEW_MODULE Fennec Fox module" > README

rm $BASE_EXAMPLE*

cd ..

echo "Looks like SUCCESS"
echo
echo -n "Don't forget to add the following line to "
echo -n $FENNEC_FOX_LIB
echo "/support/sfc/fennec.sfl"
echo
echo -n "use "
echo -n " <layer>"
echo -n " <give_it_a_name> "
echo -n $PWD/
echo $NEW_MODULE

