#!/bin/bash

cd `dirname $0`

# keep track of the # of iterations parsed
ITERATIONS=0
# keep track of number of errors encountered in parsed iterations
ERRCNT=0
# fields to parse in json
FIELDS="\(.runtime\),\(.cpuModel\),\(.vmcpustealDelta\)"
# parse results into .csv format to view in spreadsheet software
RESULTS=$PWD/results.csv

parse_json() {
	[ -f "$1" ] && eval jq "$2" < $1 || let ERRCNT++
}

check_state() {
	local ret=$(jq -r '.newcontainer' < $1)
	if [ $ret -ne 0 ]; then
		let ERRCNT++
	fi
	return $ret
}

get_stats() {
	let ITERATIONS++
	local logstarttime=$(ls *function_1* | sed -r 's|.*-(.{4})(.{2})(.{2})(.{2})(.{2})(.{2}).json|\1-\2-\3 \4:\5:\6|')
	local function1=($(parse_json *function_1* "$FIELDS"))
	local function2=($(parse_json *function_2* "$FIELDS"))
	local function3=($(parse_json *function_3* "$FIELDS"))
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
	local vmcpustealDelta_div_min_fun1=$(bc -l <<< "${function1[2]}*60000/${function1[0]}")
	local vmcpustealDelta_div_min_fun2=$(bc -l <<< "${function2[2]}*60000/${function2[0]}")
	local vmcpustealDelta_div_min_fun3=$(bc -l <<< "${function3[2]}*60000/${function3[0]}")
	local vmcpustealDelta_div_min=$(bc -l <<< "$totalvmcpustealDelta*60000/$totalruntime")
	local comment
	# Check warm/cold state
	local f
	for f in *; do
		if ! check_state $f; then
			if [ -n "$comment" ]; then
				comment="$comment; $f container not warm"
			else
				comment="$f container not warm"
			fi
		fi
	done
	echo "$1,$2,$logstarttime,$cpumodel,${function1[0]},${function2[0]},${function3[0]},$vmcpustealDelta_div_min_fun1,$vmcpustealDelta_div_min_fun2,$vmcpustealDelta_div_min_fun3,$totalruntime,$totalvmcpustealDelta,$vmcpustealDelta_div_min,$comment" | tee -a $RESULTS
}

# initialize results.csv file
echo 'region,arch,start time,cpu model,runtime function1 (ms),runtime function2 (ms),runtime function3 (ms),vmcpustealDelta/min function1,vmcpustealDelta/min function2,vmcpustealDelta/min function3,total runtime (ms),total vmcpustealDelta,total vmcpustealDelta/min,comment' | tee $RESULTS

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
