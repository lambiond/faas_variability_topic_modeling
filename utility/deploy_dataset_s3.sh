#!/bin/bash

# Allow users to set the region
if [[ -z "$1" && -z "$REGION" ]]; then
	REGION='us-east-2'
elif [ -n "$1" ]; then
	REGION=$1
fi

# Default to below if user doesn't provide an input
if [[ -z "$2" && -z "$MY_BUCKET" ]]; then
	MY_BUCKET="s3://topic-modeling-$REGION"
elif [ -n "$2" ]; then
	MY_BUCKET="$2"
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
training_data="data/news_train.csv"
if [ -f "$training_data.xz" ]; then
	unxz $training_data.xz
fi
aws s3 cp $training_data $MY_BUCKET --region $REGION
