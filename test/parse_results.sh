#!/bin/bash

cd `dirname $0`

# keep track of the # of iterations parsed
ITERATIONS=0
# keep track of number of errors encountered in parsed iterations
ERRCNT=0
# fields to parse in json
FIELDS='(.runtime),(.cpuModel),(.vmcpustealDelta),(.pageFaultsDelta),(.contextSwitchesDelta),(.totalMemory),(.freeMemory)'
# parse results into .csv format to view in spreadsheet software
RESULTS=$PWD/results.csv
# date to end parsing (e.g. 2022-01-20)
[ -n "$1" ] && END_DATE="$1"

parse_json() {
	[ -f "$1" ] && jq "$2" < $1 || let ERRCNT++
}

check_state() {
	local ret=$(jq -r '.newcontainer' < $1)
	[ $ret -ne 0 ] && let ERRCNT++
	return $ret
}

get_stats() {
	let ITERATIONS++
	# Append region and arch to output
	local output="$1,$2,"
	local logstarttime=$(ls *function_1* | sed -r 's|.*-(.{4})(.{2})(.{2})(.{2})(.{2})(.{2}).json|\1-\2-\3 \4:\5:\6|')
	# Check if we have reached the end date set by user
	if [ -n "$END_DATE" ]; then
		echo $logstarttime | grep -q $END_DATE && return 2
	fi
	output+="${logstarttime},"
	# Parse all function results
	local function1=($(parse_json *function_1* "$FIELDS"))
	local function2=($(parse_json *function_2* "$FIELDS"))
	local function3=($(parse_json *function_3* "$FIELDS"))
	# Check if any of the function runtimes are empty
	if [[ -z "${function1[0]}" || -z "${function2[0]}" || -z "${function3[0]}" ]]; then
		echo "ERROR: One or more of the runtimes is empty"
		return 1
	fi
	# Check if cpumodel if consistent between functions
	if [[ "${function1[1]}" != "${function2[1]}" || "${function1[1]}" != "${function3[1]}" ]]; then
		echo "ERROR: One or more CPU model is not consistent"
		return 1
	else
		output+="$(echo ${function1[1]} | sed -e 's/^"\(.*\)"$/\1/'),"
	fi
	# Append runtimes to results output
	for runtime in ${function1[0]} ${function2[0]} ${function3[0]}; do
		output+="${runtime},"
	done
	# Get function level vmcpustealDelta/min
	output+="$(bc -l <<< "${function1[2]}*60000/${function1[0]}"),"
	output+="$(bc -l <<< "${function2[2]}*60000/${function2[0]}"),"
	output+="$(bc -l <<< "${function3[2]}*60000/${function3[0]}"),"
	# Get function level pagefaultsDelta/min
	output+="$(bc -l <<< "${function1[3]}*60000/${function1[0]}"),"
	output+="$(bc -l <<< "${function2[3]}*60000/${function2[0]}"),"
	output+="$(bc -l <<< "${function3[3]}*60000/${function3[0]}"),"
	# Get function level contextSwitchesDelta/min
	output+="$(bc -l <<< "${function1[4]}*60000/${function1[0]}"),"
	output+="$(bc -l <<< "${function2[4]}*60000/${function2[0]}"),"
	output+="$(bc -l <<< "${function3[4]}*60000/${function3[0]}"),"
	# Get function level memoryUsage = totalMemory-freeMemory
	output+="$(bc -l <<< "${function1[5]}-${function1[6]}"),"
	output+="$(bc -l <<< "${function2[5]}-${function2[6]}"),"
	output+="$(bc -l <<< "${function3[5]}-${function3[6]}"),"
	# Calculate overall pipeline results
	local total_runtime=$((${function1[0]}+${function2[0]}+${function3[0]}))
	local total_vmcpustealDelta=$((${function1[2]}+${function2[2]}+${function3[2]}))
	local total_vmcpustealDelta_per_min=$(bc -l <<< "$total_vmcpustealDelta*60000/$total_runtime")
	# Check warm/cold state
	local comment
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
	# Output to results.csv
	echo "${output}$total_runtime,$total_vmcpustealDelta,$total_vmcpustealDelta_per_min,$comment" | tee -a $RESULTS
}

# initialize results.csv file
echo "region,arch,start time,cpu model,\
function1 runtime (ms),function2 runtime (ms),function3 runtime (ms),\
function1 vmcpustealDelta/min,function2 vmcpustealDelta/min,function3 vmcpustealDelta/min,\
function1 memoryUsage,function2 memoryUsage,function3 memoryUsage,\
function1 pageFaultsDelta/min,function2 pageFaultsDelta/min,function3 pageFaultsDelta/min,\
function1 contextSwitchesDelta/min,function2 contextSwitchesDelta/min,function3 contextSwitchesDelta/min,\
total runtime (ms),total vmcpustealDelta,total vmcpustealDelta/min,comment" | tee $RESULTS

# Parse regions dynamically in case we want to include more
regions="us-east-2 us-west-2 ap-northeast-1 eu-central-1"
for region in $regions; do
	pushd $region > /dev/null
	# Parse the arch dynamically
	cpus=$(find -maxdepth 1 -type d ! -name '.' -exec basename {} \;)
	for cpu in $cpus; do
		pushd $cpu > /dev/null
		dates=$(find -maxdepth 1 -type d ! -name '.' -exec basename {} \;)
		for day in $dates; do
			pushd $day > /dev/null
			# Parse iterations dynamically, we do not know how many we have
			iterations=$(find -maxdepth 1 -type d ! -name '.' | grep -o '[0-9]\+' | sort -n)
			for i in $iterations; do
				pushd iteration$i > /dev/null
				get_stats $region $cpu
				ret=$?
				popd > /dev/null
				# Check if we have reached the end date set by users
				if [ $ret -eq 2 ]; then
					unset ret
					break
				fi
			done
			popd > /dev/null
		done
		popd > /dev/null
	done
	popd > /dev/null
done
echo "Total iterations parsed: $ITERATIONS, Errors in records: $ERRCNT"
