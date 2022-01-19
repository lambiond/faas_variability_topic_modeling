#!/bin/bash

cd `dirname $0`

# keep track of the # of iterations parsed
ITERATIONS=0
# keep track of number of errors encountered in parsed iterations
ERRCNT=0
# parse results into .csv format to view in spreadsheet software
RESULTS=$PWD/results.csv

get_runtime() {
	[ -f "$1" ] && echo $(jq -r '.runtime' < $1) || let ERRCNT++
}

check_state() {
	local ret=$(jq -r '.newcontainer' < $1)
	if [ $ret -ne 0 ]; then
		echo "Error in $1, container not warm"
		let ERRCNT++
	fi
	return $ret
}

get_stats() {
	let ITERATIONS++
	local logstarttime=$(ls *function_1* | sed -r 's|.*-(.{4})(.{2})(.{2})(.{2})(.{2})(.{2}).json|\1-\2-\3 \4:\5:\6|')
	local runtime1=$(get_runtime *function_1*)
	local runtime2=$(get_runtime *function_2*)
	local runtime3=$(get_runtime *function_3*)
	# Check if any of the function runtimes are empty
	if [[ -z "$runtime1" || -z "$runtime2" || -z "$runtime3" ]]; then
		echo "ERROR: One or more of the runtimes is empty"
		return 1
	else
		local totalruntime=$(($runtime1+$runtime2+$runtime3))
		echo "$1,$2,$logstarttime,$runtime1,$runtime2,$runtime3,$totalruntime" | tee -a $RESULTS
	fi
	# Check warm/cold state
	local f
	for f in *; do
		check_state $f
	done
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
echo "Total iterations parsed: $ITERATIONS, Errors in records: $ERRCNT"
