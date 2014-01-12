i=0
> syms.selected
for sym in $(ls /data0/public/gt/stock_prices/| awk -F "." '{print $1'}); do
	i=$((i+1))
	intor=$(expr $i % 50) 
	#if [ $intor -ne 0 ]; then
	#	continue
	#fi
	echo $sym >> syms.selected
done
