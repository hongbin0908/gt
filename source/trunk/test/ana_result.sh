symfile=$1
resultdir=$2

sum=0
sum_avg=0
num=0
for line in $(cat $symfile) ; do
	sym=$line
	avg=$(cat ${resultdir}/$sym.result | grep "Average gain"|awk -F"%|:" '{print $(NF-1)}')
	if [ "$avg" == "" ] ;then
		continue
	fi
	sum_avg=$(echo "($sum_avg)+($avg)"|bc -l)
	num=$((num+1))
done

mkdir -p performance.out
echo $(echo "$sum_avg/$num" | bc -l)
