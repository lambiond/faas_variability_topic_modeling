#!/bin/bash

# Allow users to set the arch
if [ -z "$1" ]; then
	ARCH=`uname -m`
else
	ARCH=$1
fi

# Allow users to set the region
if [ -z "$2" ]; then
	REGION="us-east-2"
else
	REGION="$2"
fi

# Default to below if user doesn't provide an input
if [ -z "$3" ]; then
	MY_BUCKET="s3://$REGION-$ARCH-topic-modeling"
else
	MY_BUCKET="$3"
fi

cd `dirname $0`

# Check if awscli is installed
./install_awscli.sh

# Create s3 bucket if it doesn't exist
if ! aws s3api head-bucket --bucket `basename $MY_BUCKET` --region $REGION 2> /dev/null; then
	aws s3 mb $MY_BUCKET --region $REGION || exit $?
fi
aws s3 cp data/news_test.csv $MY_BUCKET --region $REGION 
aws s3 cp data/news_test_smaller.csv $MY_BUCKET --region $REGION 
aws s3 cp data/news_test_smallest.csv $MY_BUCKET --region $REGION 
if [ -f "data/news_train.csv.xz" ]; then
	unxz data/news_train.csv.xz
fi
aws s3 cp data/news_train.csv $MY_BUCKET --region $REGION 
