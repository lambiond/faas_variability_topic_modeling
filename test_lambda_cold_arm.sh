#!/bin/bash

cd `dirname $0`
source test_lambda.sh 'arm' 'us-east-2'
i=$1
while true; do
	mydir="test/us-east-2/arm/cold/workflow$i/"
	mkdir -p $mydir
	let i++
	execute_lambda_function "lambda_function_1" "arm-function1" "cold-arm-function1" "$mydir" && \
	execute_lambda_function "lambda_function_2" "arm-function2" "cold-arm-function2" "$mydir" && \
	execute_lambda_function "lambda_function_3" "arm-function3" "cold-arm-function3" "$mydir"
done
