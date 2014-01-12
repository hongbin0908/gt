symfile=$1
resultdir=$2
scriptspath=$3
body=$4
mkdir -p $resultdir

cd ${scriptspath}

mkdir -p $resultdir
cat $symfile | while read line ; do
	sym=$line
	source $body
done


cd -
