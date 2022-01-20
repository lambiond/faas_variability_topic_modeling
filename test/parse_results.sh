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

get_cpumodel() {
	[ -f "$1" ] && echo $(jq -r '.cpuModel' < $1) || let ERRCNT++
}

get_vmcpustealDelta() {
	[ -f "$1" ] && echo $(jq -r '.vmcpustealDelta' < $1) || let ERRCNT++
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
	local cpumodel1=$(get_cpumodel *function_1*)
	local cpumodel2=$(get_cpumodel *function_2*)
	local cpumodel3=$(get_cpumodel *function_3*)
	local vmcpustealDelta1=$(get_vmcpustealDelta *function_1*)
	local vmcpustealDelta2=$(get_vmcpustealDelta *function_2*)
	local vmcpustealDelta3=$(get_vmcpustealDelta *function_3*)
	# Check if any of the function runtimes are empty
	if [[ -z "$runtime1" || -z "$runtime2" || -z "$runtime3" ]]; then
		echo "ERROR: One or more of the runtimes is empty"
		return 1
	fi
	if [[ "$cpumodel1" != "$cpumodel2" || "$cpumodel1" != "$cpumodel3" ]]; then
		echo "ERROR: One or more CPU model is not consistent"
		return 1
	fi
	totalvmcpustealDelta=$((vmcpustealDelta1+vmcpustealDelta2+vmcpustealDelta3))
	local totalruntime=$(($runtime1+$runtime2+$runtime3))
	vmcpustealDelta_div_min=$(bc -l <<< "$totalvmcpustealDelta*60000/$totalruntime")
	echo "$1,$2,$logstarttime,$cpumodel1,$totalruntime,$totalvmcpustealDelta,$vmcpustealDelta_div_min" | tee -a $RESULTS
	# Check warm/cold state
	local f
	for f in *; do
		check_state $f
	done
}

# initialize results.csv file
echo 'region,arch,start time,cpu model,total runtime (ms),total vmcpustealDelta,total vmcpustealDelta/min' | tee $RESULTS

# Parse regions dynamically in case we want to include more
regions="us-east-2 ap-northeast-1 eu-central-1"
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
