#!/bin/bash
errcnt=0
temp=`mktemp`
cd `dirname $0`
results='results.csv'
echo "region,start time,state,function1 runtime (ms),function2 runtime(ms),function3 runtime(ms),total runtime(msec)" > $results
for f in *json; do
	jq -r ".[] | \"\(.functionRegion),\(.startWallClock),\(.newcontainer),\(.function),\(.runtime)\"" $f > $temp
	echo $f
	num=1
	end=`wc -l < $temp`
	for ((i=1; i<$end; i+=3)); do
		runtime1=$(awk -F"," "NR==$i {print \$NF}" $temp)
		runtime2=$(awk -F"," "NR==$((i+1)) {print \$NF}" $temp)
		runtime3=$(awk -F"," "NR==$((i+2)) {print \$NF}" $temp)
		region=$(awk -F"," "NR==$i {print \$1}" $temp)
		starttime=$(date -d "$(awk -F"," "NR==$i {print \$2}" $temp)" "+%y-%m-%d %H:%M")
		state1=$(awk -F"," "NR==$i {print \$3}" $temp)
		state2=$(awk -F"," "NR==$((i+1)) {print \$3}" $temp)
		state3=$(awk -F"," "NR==$((i+2)) {print \$3}" $temp)
		if [[ $state1 -ne $state2 || $state1 -ne $state3 ]]; then
			let errcnt++
			continue
		elif [ "$state1" == "0" ]; then
			state="warm"
		else
			state="cold"
		fi
		totalruntime=$((runtime1+runtime2+runtime3))
		echo "$region,$starttime,$state,$runtime1,$runtime2,$runtime3,$totalruntime" | tee -a $results
	done
done
rm $temp
echo $errcnt
