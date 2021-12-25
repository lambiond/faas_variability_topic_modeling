#!/bin/bash

# Allow users to set the arch
[ -z "$1" ] && ARCH=`uname -m` || ARCH=$1

# Allow users to set the region
[ -z "$2" ] && REGION="us-east-2" || REGION="$2"

# Default to below if user doesn't provide an input
[ -z "$3" ] && MY_BUCKET="s3://topic-modeling-$REGION" || MY_BUCKET="$3"

cd `dirname $0`

# Check if awscli is installed
./install_awscli.sh

# Create S3 bucket only if it doesn't exist
if ! aws s3api head-bucket --bucket `basename $MY_BUCKET` --region $REGION 2> /dev/null; then
	aws s3 mb $MY_BUCKET --region $REGION || exit $?
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
