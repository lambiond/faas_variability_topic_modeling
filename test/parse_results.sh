#!/bin/bash

cd `dirname $0`

# keep track of the # of iterations parsed
ITERATIONS=0
# keep track of number of errors encountered in parsed iterations
ERRCNT=0
# parse results into .csv format to view in spreadsheet software
RESULTS=$PWD/results.csv

parse_json() {
	[ -f "$1" ] && echo $(eval jq "$2" < $1) || let ERRCNT++
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
	local fields="\(.runtime\),\(.cpuModel\),\(.vmcpustealDelta\)"
	local function1=($(parse_json *function_1* "$fields"))
	local function2=($(parse_json *function_2* "$fields"))
	local function3=($(parse_json *function_3* "$fields"))
	# Check if any of the function runtimes are empty
	if [[ -z "${function1[0]}" || -z "${function2[0]}" || -z "${function3[0]}" ]]; then
		echo "ERROR: One or more of the runtimes is empty"
		return 1
	fi
	if [[ "${function1[1]}" != "${function2[1]}" || "${function1[1]}" != "${function3[1]}" ]]; then
		echo "ERROR: One or more CPU model is not consistent"
		return 1
	fi
	local cpumodel=$(echo ${function1[1]} | sed -e 's/^"\(.*\)"$/\1/')
	local totalruntime=$((${function1[0]}+${function2[0]}+${function3[0]}))
	local totalvmcpustealDelta=$((${function1[2]}+${function2[2]}+${function3[2]}))
	local vmcpustealDelta_div_min=$(bc -l <<< "$totalvmcpustealDelta*60000/$totalruntime")
	echo "$1,$2,$logstarttime,$cpumodel,$totalruntime,$totalvmcpustealDelta,$vmcpustealDelta_div_min" | tee -a $RESULTS
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
