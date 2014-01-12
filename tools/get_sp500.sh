#!/bin/sh
#########################
#@author hongbin2@staff.sina.com.cn
#@date 
#@desc TODO
#########################
export PATH=/usr/bin:$PATH
export SCRIPT_PATH=`dirname $(readlink -f $0)` # get the path of the script
pushd . > /dev/null 


cd  /home/abin/geniustrader/data/; ls *.txt | awk -F"." '{print $1}'

cd "$SCRIPT_PATH"
popd  > /dev/null # return the directory orignal
