#!/bin/bash

set -o pipefail

cd $(dirname $0)

# Install jq if not present to make json easier to read
#if ! which jq > /dev/null; then
#	sudo apt update && sudo apt install -y jq
#fi

# Allow users to set the arch to test
[ -z "$1" ] && ARCH=`uname -m` || ARCH=$1

# Test different regions
[ -z "$2" ] && REGION='us-east-2' || REGION=$2

# Iterations in pipeline
[ -z "$3" ] && ITERATIONS=1 || ITERATIONS=$3

# function_name = $1
# lambda_function = $2
# filename_postfix = $3
# directory_name = $4
# retry = $5
# sleep = $6
execute_lambda_function() {
	local mystart=`date`
	local json="{\"function_name\":\"$1\", \"startWallClock\":\"$mystart\"}"
	# Set timeout to 10 minutes
	sleep $6
	echo aws lambda invoke --cli-read-timeout 900 --invocation-type RequestResponse --function-name $2 --region $REGION --payload "$json" /dev/stdout
	local output=$(aws lambda invoke \
		--cli-read-timeout 900 \
		--invocation-type RequestResponse \
		--function-name $2 \
		--region $REGION \
		--payload "$json" /dev/stdout)
	local ret=$?
	if [ $ret -ne 0 ] || [ -z "$output" ] || echo "$output" | grep -q 'errorType'; then
		echo "ERROR: something bad happened!"
		if [[ -n "$5" && $5 -gt 0 ]]; then
			execute_lambda_function "$1" "$2" "$3" "$4" $((${5}-1)) $((${6}*2))
		else
			exit 1
		fi
	else
		mystart=$(date -d "$mystart" "+%Y%m%d%H%M%S")
		echo $output | awk -F'}' '{print $1"}"}' | tee $4/$mystart-$3.txt
	fi
	return $ret
}

i=0
while [ $ITERATIONS -gt 0 ]; do
    mydir="$REGION/$ARCH/workflow$i/"
    mkdir -p $mydir
    let i++
	let ITERATIONS--
    execute_lambda_function "lambda_function_1" "topic-modeling-$ARCH" "$ARCH-function1" "$mydir" 5 1 && \
    execute_lambda_function "lambda_function_2" "topic-modeling-$ARCH" "$ARCH-function2" "$mydir" 5 1 && \
    execute_lambda_function "lambda_function_3" "topic-modeling-$ARCH" "$ARCH-function3" "$mydir" 5 1
done
