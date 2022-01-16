#!/bin/bash

cd `dirname $0`

# parse results into .csv format to view in spreadsheet software
RESULTS=$PWD/results.csv

get_runtime() {
	echo $(jq -r '.runtime' < $1)
}

check_state() {
	return $(jq -r '.newcontainer' < $1)
}

get_stats() {
	let total++
	logstarttime=$(ls *function_1* | sed -r 's|.*-(.{4})(.{2})(.{2})(.{2})(.{2})(.{2}).json|\1-\2-\3 \4:\5:\6|')
	runtime1=$(get_runtime *function_1*)
	runtime2=$(get_runtime *function_2*)
	runtime3=$(get_runtime *function_3*)
	# Check warm/cold state
	if ! check_state *function_1* ||
		! check_state *function_2* ||
		! check_state *function_3*; then
		let errcnt++
	elif [[ -z "$runtime1" || -z "$runtime2" || -z "$runtime3" ]]; then
		# one of the runtimes is empty
		let errcnt++
	else
		totalruntime=$(($runtime1+$runtime2+$runtime3))
		echo "$1,$2,$logstarttime,$runtime1,$runtime2,$runtime3,$totalruntime" | tee -a $RESULTS
	fi
}

# initialize results.csv file
echo 'region,arch,start time,function 1 runtime (ms),function 2 runtime (ms),function 3 runtime (ms),total runtime (ms)' | tee $RESULTS

# Parse regions dynamically in case we want to include more
regions=$(find -maxdepth 1 -type d ! -name '.' -exec basename {} \;)
for region in $regions; do
	pushd $region > /dev/null
	# Parse the arch dynamically
	cpus=$(find -maxdepth 1 -type d ! -name '.' -exec basename {} \;)
	for cpu in $cpus; do
		pushd $cpu > /dev/null
		dates=$(find -maxdepth 1 -type d ! -name '.' -exec basename {} \;)
		for day in $dates; do
			pushd $day > /dev/null
			# parse iterations dynamically, we do not know how many we have
			iterations=$(find -maxdepth 1 -type d ! -name '.' | grep -o '[0-9]\+' | sort -n)
			for i in $iterations; do
				pushd iteration$i > /dev/null
				get_stats $region $cpu
				popd > /dev/null
			done
			popd > /dev/null
		done
		popd > /dev/null
	done
	popd > /dev/null
done
echo "Total iterations parsed: $total, Error in records: $errcnt ($((errcnt*100/total))%)"
