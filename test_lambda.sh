#!/bin/bash

execute_function() {
	json={"\"function_name\"":"\"lambda_function_$1\""}
	output=curl -s -H "Content-Type: application/json" -X POST -d $json "https://urwkt891se.execute-api.us-east-2.amazonaws.com/prod"
	echo $output | jq
}

execute_function 1
execute_function 2
execute_function 3
