#!/bin/bash

cd `dirname $0`
. ./lambda_test.sh 'arm' 'us-east-2'

for ((i=0; i<100; i++)); do
	mydir="test/us-east-2/arm/warm/workflow$i/"
	mkdir -p $mydir
	execute_lambda_function "lambda_function_1" "tcss562_term_project_arm" "warm-arm-function1" "$mydir" && \
	execute_lambda_function "lambda_function_2" "tcss562_term_project_arm" "warm-arm-function2" "$mydir" && \
	execute_lambda_function "lambda_function_3" "tcss562_term_project_arm" "warm-arm-function3" "$mydir" 
done
