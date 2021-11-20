#!/bin/bash

json={"\"function_name\"":"\"hello\""}

output=$(aws lambda invoke --invocation-type RequestResponse --function-name tcss562_term_project --region us-east-2 --payload $json /dev/stdout | head -n 1 | head -c -2)
echo $output | jq .
