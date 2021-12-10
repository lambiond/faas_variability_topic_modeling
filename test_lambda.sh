#!/bin/bash

set -o pipefail

# Allow users to set the arch to test
if [ -z "$1" ]; then
	ARCH=`uname -m`
else
	ARCH=$1
fi

# Test different regions
if [ -z "$2" ]; then
	REGION='us-east-2'
else
	REGION=$2
fi

execute_lambda_function() {
	json={"\"function_name\"":"\"$1\""}
	# Set timeout to 10 minutes
	mystart=`date "+%y%m%d%H%M"`
	output=$(aws lambda invoke --cli-read-timeout 900 --invocation-type RequestResponse
		--function-name $2 --region $REGION --cli-binary-format raw-in-base64-out
		--payload "$json" /dev/stdout)
	local ret=$?
	if [[ $ret -ne 0 || -z "$output" ]]; then
		echo "ERROR: something bad happened!"
	else
		echo $output | head -n 1 | head -c -2 | jq | tee $4/$mystart-$3.txt
	fi
	return $ret
}
