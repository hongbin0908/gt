#!/bin/bash
#########################
#@author hongbin0908@126.com
#@date 
#@desc get then option chains
#########################
export PATH=/bin/:/usr/bin/:$PATH
export SCRIPT_PATH=`dirname $(readlink -f $0)` # get the path of the script
pushd . > /dev/null
cd "$SCRIPT_PATH"


num=$(ps aux |grep run_get_stock_prices.sh |grep -v "grep" | wc -l)

if [ $num -ge 1 ]; then
    exit 0
fi  

sh run_get_stock_prices.sh

popd  > /dev/null # return the directory orignal

