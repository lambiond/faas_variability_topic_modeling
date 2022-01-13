#!/bin/bash

set -o pipefail

# Install jq if not present to make json easier to read
if ! which jq > /dev/null; then
	sudo apt update && sudo apt install -y jq
fi

# Allow users to set the arch to test
[ -z "$1" ] && ARCH=`uname -m` || ARCH=$1

# Test different regions
[ -z "$2" ] && REGION='us-east-2' || REGION=$2

# function_name = $1
# lambda_function = $2
# filename_postfix = $3
# directory_name = $4
# retry = $5
execute_lambda_function() {
	json="{\"function_name\":\"$1\", \"startWallClock\":\"$(date)\"}"
	# Set timeout to 10 minutes
	mystart=`date`
	output=$(aws lambda invoke \
		--cli-read-timeout 900 \
		--invocation-type RequestResponse \
		--function-name $2 \
		--region $REGION \
		--payload "$json" /dev/stdout)
	local ret=$?
	if [ $ret -ne 0 ] || [ -z "$output" ] || echo "$output" | grep -q 'errorType'; then
		echo "ERROR: something bad happened!"
		if [[ -n "$5" && $5 -gt 0 ]]; then
			retry=$((${5}-1))
			sleep 1
			execute_lambda_function "$1" "$2" "$3" "$4" $retry
		else
			exit 1
		fi
	else
		mystart=$(date -d "$mystart" "+%y%m%d%H%M")
		echo $output | awk -F'}' '{print $1"}"}' | jq | tee $4/$mystart-$3.txt
	fi
	return $ret
}
