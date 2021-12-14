#!/bin/bash

get_runtime() {
	echo $(awk '/runtime/ {print substr($2, 1, length($2)-1)}' $1)
}

get_stats() {
	logstarttime=$(ls *function1* | sed -r 's|^(.{2})(.{2})(.{2})(.{2})(.{2}).*|\1-\2-\3 \4:\5|')

	runtime1=$(get_runtime *function1*)
	runtime2=$(get_runtime *function2*)
	runtime3=$(get_runtime *function3*)
	if [[ -z "$runtime1" || -z "$runtime2" || -z "$runtime3" ]]; then
		# one of the runtimes is empty
		return 1
	fi
	totalruntime=$(($runtime1+$runtime2+$runtime3))
	echo "$1,$logstarttime,$2,$3,$runtime1,$runtime2,$runtime3,$totalruntime" | tee -a $RESULTS
}

cd `dirname $0`
# parse results into .csv format to view in spreadsheet software
RESULTS=$PWD/results.csv
# initialize results.csv file
echo 'start time,region,arch,state,workflow,function 1 runtime (ms),function 2 runtime (ms),function 3 runtime (ms),total runtime (ms)' | tee $RESULTS

# All the results are stored in the test directory
basedir='test'
cd $basedir

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
