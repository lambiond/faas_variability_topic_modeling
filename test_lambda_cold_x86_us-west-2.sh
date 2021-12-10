#!/bin/bash

ARCH='x86'
REGION='us-west-2'
# Allow user to start at 0 or 1
if [ -z "$1" ]; then
	echo "Input a number to start test loop, default to 0"
	i=0
else
	i=$1
fi

cd `dirname $0`
source test_lambda.sh $ARCH $REGION
while true; do
	mydir="test/$REGION/$ARCH/cold/workflow$i/"
	mkdir -p $mydir
	let i++
	execute_lambda_function "lambda_function_1" "$ARCH-function1" "cold-$ARCH-function1" "$mydir" && \
	execute_lambda_function "lambda_function_2" "$ARCH-function2" "cold-$ARCH-function2" "$mydir" && \
	execute_lambda_function "lambda_function_3" "$ARCH-function3" "cold-$ARCH-function3" "$mydir"
done
