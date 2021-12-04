#!/bin/bash

set -o pipefail

# Allow users to set the arch to test
if [ -z "$1" ]; then
	ARCH=`uname -m`
else
	ARCH=$1
fi

# This is the default project lambda function name
if [ "$ARCH" == 'x86_64' ]; then
	MY_FUNCTION='tcss562_term_project'
else
	MY_FUNCTION='tcss562_term_project_arm'
fi

execute_lambda_function() {
	echo "Calling lambda_function_$1"
	echo "--------------------------"
	json={"\"function_name\"":"\"lambda_function_$1\""}
	# Set timeout to 10 minutes
	time output=$(aws lambda invoke --cli-read-timeout 600 --invocation-type RequestResponse --function-name tcss562_term_project --region us-east-2 --payload $json /dev/stdout | head -n 1 | head -c -2)
	local ret=$?
	if [ $ret -ne 0 ]; then
		echo "ERROR: Stopping workflow, something bad happened!"
	else
		echo $output | jq
	fi
	return $ret
}

execute_lambda_function 1 && \
execute_lambda_function 2 && \
execute_lambda_function 3
