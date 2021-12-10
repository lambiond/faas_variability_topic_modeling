#!/bin/bash

cd `dirname $0`
. ./lambda_test.sh 'arm' 'us-east-2'

for ((i=0; i<100; i++)); do
	mydir="test/us-east-2/arm/cold/workflow$i/"
	mkdir -p $mydir
	execute_lambda_function "lambda_function_1" "arm-function1" "cold-arm-function1" "$mydir" && \
	execute_lambda_function "lambda_function_2" "arm-function2" "cold-arm-function2" "$mydir" && \
	execute_lambda_function "lambda_function_3" "arm-function3" "cold-arm-function3" "$mydir" 
done
