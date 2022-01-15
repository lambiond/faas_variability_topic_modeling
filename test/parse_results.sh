#!/bin/bash

get_runtime() {
	echo $(awk '/runtime/ {print substr($2, 1, length($2)-1)}' $1)
}

check_state() {
	if [ "$1" == "warm" ]; then
		grep -q "newcontainer.*1" $2
	else
		grep -q "newcontainer.*0" $2
	fi
	return $?
}

get_stats() {
	logstarttime=$(ls *function1* | sed -r 's|^(.{4})(.{2})(.{2})(.{2})(.{2})(.{2}).*|\1-\2-\3 \4:\5:\6|')
	let total++
	runtime1=$(get_runtime *function1*)
	runtime2=$(get_runtime *function2*)
	runtime3=$(get_runtime *function3*)
	# Check warm/cold state
	if check_state $3 *function1* ||
		check_state $3 *function2* ||
		check_state $3 *function3*; then
		let errcnt++
	elif [[ -z "$runtime1" || -z "$runtime2" || -z "$runtime3" ]]; then
	# Check for empty runtimes
		# one of the runtimes is empty
		let errcnt++
	else
		totalruntime=$(($runtime1+$runtime2+$runtime3))
		echo "$1,$logstarttime,$2,$3,$runtime1,$runtime2,$runtime3,$totalruntime" | tee -a $RESULTS
	fi
}

cd `dirname $0`
# parse results into .csv format to view in spreadsheet software
RESULTS=$PWD/results.csv
# initialize results.csv file
echo 'region,start time,arch,state,function 1 runtime (ms),function 2 runtime (ms),function 3 runtime (ms),total runtime (ms)' | tee $RESULTS

# We are storing cold and warm starts for each region/arch
states='cold warm'

# Parse regions dynamically in case we want to include more
#regions=$(find -maxdepth 1 -type d ! -name '.' -exec basename {} \;)
regions='us-east-2'
for region in $regions; do
	pushd $region > /dev/null

	# Parse the arch dynamically
	cpus=$(find -maxdepth 1 -type d ! -name '.' -exec basename {} \;)
	for cpu in $cpus; do
		pushd $cpu > /dev/null

			# We will have a cold and warm state in every instance
			for state in $states; do
				pushd $state > /dev/null

					# parse workflows dynamically, we do not know how many we have
					workflows=$(find -maxdepth 1 -type d ! -name '.' | grep -o '[0-9]\+' | sort -n)
					for workflow in $workflows; do
						pushd workflow$workflow > /dev/null
							# Do work son!
							get_stats $region $cpu $state
						popd > /dev/null
					done

				popd > /dev/null
			done
		popd > /dev/null
	done
	popd > /dev/null
done
echo "Total workflows parsed: $total, Error in records: $errcnt ($((errcnt*100/total))%)"
