#!/bin/bash

cd `dirname $0`
source test_lambda.sh 'x86' 'us-east-2'

for ((i=0; i<100; i++)); do
	mydir="test/us-east-2/x86/warm/workflow$i/"
	mkdir -p $mydir
	execute_lambda_function "lambda_function_1" "tcss562_term_project" "warm-x86-function1" "$mydir" && \
	execute_lambda_function "lambda_function_2" "tcss562_term_project" "warm-x86-function2" "$mydir" && \
	execute_lambda_function "lambda_function_3" "tcss562_term_project" "warm-x86-function3" "$mydir" 
done
