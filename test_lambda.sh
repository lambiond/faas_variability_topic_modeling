#!/bin/bash

json={"\"function_name\"":"\"lambda_function_1\""}

output=curl -s -H "Content-Type: application/json" -X POST -d $json "https://urwkt891se.execute-api.us-east-2.amazonaws.com/prod"
#output=$(aws lambda invoke --invocation-type RequestResponse --function-name tcss562_term_project --region us-east-2 --payload $json /dev/stdout | head -n 1 | head -c -2)
echo $output | jq
