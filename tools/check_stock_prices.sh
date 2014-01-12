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

mkdir -p ${SCRIPT_PATH}/../log/
logfile=${SCRIPT_PATH}/../log/get_stock_prices.py.log.$(date '+%Y%m%d')
echo "get_stock_prices.py start ..." > $logfile

while [ 1 ]; do
    python get_stock_prices.py  /home/abin/geniustrader/data 2>1 >>  $logfile
done

echo "get_stock_prices.py end ..." >> $logfile

popd  > /dev/null # return the directory orignal

