#!/bin/bash

cd `dirname $0`
source test_lambda.sh 'arm' 'us-east-2'
i=$1
while true; do
	mydir="test/us-east-2/arm/warm/workflow$i/"
	mkdir -p $mydir
	let i++
	execute_lambda_function "lambda_function_1" "tcss562_term_project_arm" "warm-arm-function1" "$mydir" && \
	execute_lambda_function "lambda_function_2" "tcss562_term_project_arm" "warm-arm-function2" "$mydir" && \
	execute_lambda_function "lambda_function_3" "tcss562_term_project_arm" "warm-arm-function3" "$mydir"
done
