#!/bin/bash

# Default to below if user doesn't provide an input
if [ -z "$1" ]; then
	MY_BUCKET="s3://tcss562-term-project-group3"
else
	MY_BUCKET="$1"
fi

cd `dirname $0`

# Check if awscli is installed
./install_awscli.sh

#aws s3 mb `basename $MY_BUCKET`
aws s3 cp data/news_test.csv $MY_BUCKET
aws s3 cp data/news_train.csv $MY_BUCKET
