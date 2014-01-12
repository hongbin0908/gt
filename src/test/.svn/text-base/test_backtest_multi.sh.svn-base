#!/bin/sh
#########################
#@author hongbin2@staff.sina.com.cn
#@date 2013/11/29
#@desc test the backtest_multi.pl in *GT*
#########################
export SCRIPT_PATH=`dirname $(readlink -f $0)` # get the path of the script
export SCRIPT_NAME=$(basename $(readlink -f $0))

pushd . > /dev/null 
cd "$SCRIPT_PATH"


cd ${SCRIPT_PATH}/../Scripts

mkdir -p $(SCRIPT_NAME).out
cat ${SCRIPT_NAME}.syms | while read line ; do
	sym=$line
	perl ./backtest.pl --option='Graphic::BackgroundColor=White'   --system='SS_HB1'   --close-strategy='CS_HB1'   --money-management="Basic"   --graph=${SCRIPT_NAME}.out/$sym.png  $sym  > ${SCRIPT_NAME}.out/$sym.result
done


cd -


popd  > /dev/null # return the directory orignal
