#!/bin/bash

cd `dirname $0`
source test_lambda.sh 'x86_64' 'us-east-2'
# Allow user to start at 0 or 1
if [ -z "$1" ]; then
	echo "Input a number to start test loop, default to 0"
	i=0
else
	i=$1
fi
while true; do
	mydir="$REGION/$ARCH/warm/workflow$i/"
	mkdir -p $mydir
	let i++
	execute_lambda_function "lambda_function_1" "topic-modeling-$ARCH" "warm-$ARCH-function1" "$mydir" 5 && \
	execute_lambda_function "lambda_function_2" "topic-modeling-$ARCH" "warm-$ARCH-function2" "$mydir" 5 && \
	execute_lambda_function "lambda_function_3" "topic-modeling-$ARCH" "warm-$ARCH-function3" "$mydir" 5
done
