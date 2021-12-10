#!/bin/bash

set -o pipefail

# Allow users to set the arch to test
if [ -z "$1" ]; then
	ARCH=`uname -m`
else
	ARCH=$1
fi

# This is the default project lambda function name
#if [ "$ARCH" == 'x86_64' ]; then
#	MY_FUNCTION='tcss562_term_project'
#else
#	MY_FUNCTION='tcss562_term_project_arm'
#fi

execute_lambda_function() {
	json={"\"function_name\"":"\"lambda_function_$1\""}
	# Set timeout to 10 minutes
	mystart=`date "+%y%m%d%H%M"`
	time output=$(aws lambda invoke --cli-read-timeout 600 --invocation-type RequestResponse --function-name tcss562_term_project_arm --region us-east-2 --cli-binary-format raw-in-base64-out --payload "$json" /dev/stdout)
	local ret=$?
	if [[ $ret -ne 0  || -z "$output" ]]; then
		echo "ERROR: Stopping workflow, something bad happened!"
	else
		echo $output | head -n 1 | head -c -2 | jq | tee $mydir/$mystart-warm-arm-function$1.txt
	fi
	return $ret
}

for ((i=0; i<100; i++)); do
	mydir="test/us-east-2/arm/warm/workflow$i/"
	mkdir -p $mydir
	execute_lambda_function 1 && \
	execute_lambda_function 2 && \
	execute_lambda_function 3
done
