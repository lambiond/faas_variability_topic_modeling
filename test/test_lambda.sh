#!/bin/bash

# Change to the directory containing the test script
cd $(dirname $0)
# Allow users to set the arch to test
[ -z "$1" ] && ARCH=`uname -m` || ARCH=$1
# Test different regions
[ -z "$2" ] && REGION=`awk '/region/ {print $NF}' /home/$USER/.aws/config` || REGION=$2
# Iterations in pipeline
[ -z "$3" ] && ITERATIONS=1 || ITERATIONS=$3
# Retry after failures
[ -z "$4" ] && RETRY=5 || RETRY=$4
# Delay between function execution
[ -z "$5" ] && DELAY=1 || DELAY=$5
# Backoff rate
[ -z "$6" ] && BACKOFF=2 || BACKOFF=$6

# lambda_name = $1
# function_name = $2
# directory_name = $3
# retry = $4
# delay = $5
execute_lambda_function() {
	printf "\n\e[36mExecuting $1 ($2)...\n---\e[0m\n"
	sleep $5
	local mystart=`date`
	local json="{\"function_name\":\"$2\", \"startWallClock\":\"$mystart\"}"
	# Set timeout to 10 minutes
	local output=$(/usr/local/bin/aws lambda invoke \
		--cli-read-timeout 900 \
		--invocation-type RequestResponse \
		--function-name $1 \
		--region $REGION \
		--payload "$json" /dev/stdout)
	local ret=$?
	if [ $ret -ne 0 ] || [ -z "$output" ] || echo "$output" | grep -q 'errorType'; then
		echo "ERROR: something bad happened!"
		if [[ -n "$4" && $4 -gt 0 ]]; then
			execute_lambda_function "$1" "$2" "$3" $(($4-1)) $(($5*$BACKOFF))
			ret=$?
		else
			exit 1
		fi
	else
		mystart=$(date -d "$mystart" "+%Y%m%d%H%M%S")
		echo $output | awk -F'}' '{print $1"}"}' | tee $3/$1-$2-$mystart.json
	fi
	return $ret
}

# Execute workflow pipeline
for ((i=0; i<$ITERATIONS; i++)); do
	mydir="$REGION/$ARCH/$(date -u "+%Y%m%d")/workflow$i/"
	mkdir -p $mydir && \
	execute_lambda_function "topic-modeling-$ARCH" "lambda_function_1" "$mydir" $RETRY $DELAY && \
	execute_lambda_function "topic-modeling-$ARCH" "lambda_function_2" "$mydir" $RETRY $DELAY && \
	execute_lambda_function "topic-modeling-$ARCH" "lambda_function_3" "$mydir" $RETRY $DELAY && \
	/usr/local/bin/aws s3 rm "s3://$(echo topic-modeling-$REGION-$ARCH | tr '_' '-')" --recursive 
done
