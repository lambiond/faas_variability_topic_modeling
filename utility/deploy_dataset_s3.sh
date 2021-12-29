#!/bin/bash

# Allow users to set the arch
if [[ -z "$1" && -z "$ARCH" ]]; then
	ARCH=$(uname -m)
elif [ -z "$ARCH" ]; then
	ARCH=$1
fi
ARCH=$(echo $ARCH | tr '_' '-')

# Allow users to set the region
if [[ -z "$2" && -z "$REGION" ]]; then
	REGION='us-east-2'
elif [ -z "$REGION" ]; then
	REGION=$2
fi

# Default to below if user doesn't provide an input
if [[ -z "$3" && -z "$MY_BUCKET" ]]; then
	MY_BUCKET="s3://topic-modeling-$REGION-$ARCH"
elif [ -z "$MY_BUCKET" ]; then
	MY_BUCKET="$3"
fi

cd `dirname $0`/..

# Create S3 bucket only if it doesn't exist
if ! aws s3api head-bucket --bucket `basename $MY_BUCKET` --region $REGION 2> /dev/null; then
	aws s3 mb "$MY_BUCKET" --region $REGION || exit $?
	# Block all public access
	aws s3api put-public-access-block \
    	--bucket `basename $MY_BUCKET` \
    	--public-access-block-configuration \
		"BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true" \
		--region $REGION
fi
#aws s3 cp data/news_test.csv $MY_BUCKET --region $REGION 
aws s3 cp data/news_test_smaller.csv $MY_BUCKET --region $REGION 
#aws s3 cp data/news_test_smallest.csv $MY_BUCKET --region $REGION 
if [ -f "data/news_train.csv.xz" ]; then
	unxz data/news_train.csv.xz
fi
aws s3 cp data/news_train.csv $MY_BUCKET --region $REGION 