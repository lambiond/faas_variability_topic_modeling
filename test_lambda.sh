#!/bin/bash

set -o pipefail

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
	json={"\"function_name\"":"\"$1\""}
	# Set timeout to 10 minutes
	mystart=`date "+%y%m%d%H%M"`
	output=$(aws lambda invoke --cli-read-timeout 900 --invocation-type RequestResponse --function-name $2 --region $REGION --cli-binary-format raw-in-base64-out --payload "$json" /dev/stdout)
	local ret=$?
	if [[ $ret -ne 0 || -z "$output" || echo "$output" | grep -q 'errorType' ]]; then
		echo "ERROR: something bad happened!"
		if [[ -n "$5" && $5 -gt 0 ]]; then
			retry=$((${5}-1))
			execute_lambda_function "$1" "$2" "$3" "$4" $retry
		else
			exit 1
		fi
	else
		echo $output | head -n 1 | head -c -2 | jq | tee $4/$mystart-$3.txt
	fi
	return $ret
}
