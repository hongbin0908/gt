#!/bin/sh
#########################
#@author hongbin2@staff.sina.com.cn
#@date 
#@desc TODO
#########################
export SCRIPT_PATH=`dirname $(readlink -f $0)` # get the path of the script
pushd . > /dev/null 
cd "$SCRIPT_PATH"

function do_test() {
	source  run_test.sh  ${SCRIPT_PATH}/syms.selected  ${SCRIPT_PATH}/../data/$(date '+%Y%m%d')/$1.out/  ${SCRIPT_PATH}/../Scripts/ ${SCRIPT_PATH}/$1 2> /dev/null 
	
	sum=$(source ana_result.sh ${SCRIPT_PATH}/syms.selected ${SCRIPT_PATH}/../data/$(date '+%Y%m%d')/$1.out/)
	echo $1" "$sum
}

source select_sym.sh

do_test test_sma1.sh
do_test test_sma2.sh
do_test test_sma3.sh

popd  > /dev/null # return the directory orignal
