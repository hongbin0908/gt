#!/bin/sh
#########################
#@author hongbin2@staff.sina.com.cn
#@date 2013/11/29
#@desc test the SMA
#########################
export SCRIPT_PATH=`dirname $(readlink -f $0)` # get the path of the script
export SCRIPT_NAME=$(basename $(readlink -f $0))

pushd . > /dev/null 
cd "$SCRIPT_PATH"


cd ../Scripts

i=0
for sym in $(ls /data0/public/gt/stock_prices/| awk -F "." '{print $1'}); do
	i=$((i+1))
	#intor=$(expr $i % 5) 
	#if [ $intor -ne 0 ]; then
		#continue
	#fi
	echo $sym >> ${SCRIPT_NAME}.syms
done

mkdir -p $(SCRIPT_NAME).out
cat ${SCRIPT_NAME}.syms | while read line ; do
	sym=$line
	perl ./backtest.pl --option='Graphic::BackgroundColor=White'   --system='SS_HB1 9 18 36'   --close-strategy='CS_HB1 9 10 36'   --money-management="Basic"   --graph=${SCRIPT_NAME}.out/$sym.png  $sym  > ${SCRIPT_NAME}.out/$sym.result
done

$sum=0
for line in $(cat ${SCRIPT_NAME}.syms) ; do
	sym=$line
	performance=$(cat ${SCRIPT_NAME}.out/$sym.result | grep "Performance" | awk -F":|%" '{print $2}')
	buyhold=$(cat ${SCRIPT_NAME}.out/$sym.result | grep "Performance" | awk -F":|%" '{print $5}')
	sum=$(echo "$sum+$performance-$buyhold" | bc -l)
done

mkdir -p performance.out
echo $sum > performance.out/${SCRIPT_NAME}.sum 

cd -


popd  > /dev/null # return the directory orignal
