#!/bin/bash

cd `dirname $0`
. ./lambda_test.sh 'x86' 'us-east-2'

for ((i=0; i<100; i++)); do
	mydir="test/us-east-2/x86/cold/workflow$i/"
	mkdir -p $mydir
	execute_lambda_function "lambda_function_1" "x86-function1" "cold-x86-function1" "$mydir" && \
	execute_lambda_function "lambda_function_2" "x86-function2" "cold-x86-function2" "$mydir" && \
	execute_lambda_function "lambda_function_3" "x86-function3" "cold-x86-function3" "$mydir" 
done
