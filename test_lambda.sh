#!/bin/bash

execute_lambda_function() {
	echo "Calling lambda_function_$1"
	echo "--------------------------"
	json={"\"function_name\"":"\"lambda_function_$1\""}
	time output=$(aws lambda invoke --invocation-type RequestResponse --function-name tcss562_term_project --region us-east-2 --payload $json /dev/stdout | head -n 1 | head -c -2)
	echo $output | jq
}

execute_lambda_function 1 && \
execute_lambda_function 2 && \
execute_lambda_function 3
