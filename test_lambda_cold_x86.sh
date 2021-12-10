#!/bin/bash

cd `dirname $0`
source test_lambda.sh 'x86' 'us-east-2'
i=$1
while true; do
	mydir="test/us-east-2/x86/cold/workflow$i/"
	mkdir -p $mydir
	let i++
	execute_lambda_function "lambda_function_1" "x86-function1" "cold-x86-function1" "$mydir" && \
	execute_lambda_function "lambda_function_2" "x86-function2" "cold-x86-function2" "$mydir" && \
	execute_lambda_function "lambda_function_3" "x86-function3" "cold-x86-function3" "$mydir"
done
