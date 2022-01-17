#!/bin/bash

create_role() {
	# Create IAM role for Lambda functions
	if ! aws iam get-role --role-name "$FUNCTION-$REGION" &> /dev/null; then
		if ! aws iam create-role \
			--role-name "$FUNCTION-$REGION" \
			--assume-role-policy-document \
			'{"Version": "2012-10-17","Statement": [{ "Effect": "Allow", "Principal": {"Service": "lambda.amazonaws.com"}, "Action": "sts:AssumeRole"}]}'; then
			echo "ERROR: Failed to create IAM role for Lambda"
			exit 1
		fi
		# Attach role policy
		aws iam attach-role-policy \
			--role-name "$FUNCTION-$REGION" \
			--policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole
		# Allow access to all S3 buckets
		# TODO this should be revised to only allow access to necessary buckets
		aws iam attach-role-policy \
			--role-name "$FUNCTION-$REGION" \
			--policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess
	fi
	ROLE=$(aws iam get-role --role-name "$FUNCTION-$REGION" | awk '/Arn/ {print substr($2, 2, length($2)-3)}')
	sleep 10
}

create_lambda_function() {
	local timeout=$1
	local memorysize=$2
	# My container registry portal
	local id=`aws sts get-caller-identity | sed -n 's|.*Account.*"\([0-9]\+\)".*|\1|p'`
	local ecr=$id.dkr.ecr.$REGION.amazonaws.com
	local image="topic-modeling"
	case $ARCH in
		x86_64)
			image="$image:amd64"
			;;
		*)
			image="$image:$ARCH"
			;;
	esac

	aws lambda create-function \
		--function-name $FUNCTION \
		--role "$ROLE" \
		--code ImageUri=$ecr/$image \
		--timeout $timeout \
		--memory-size $memorysize \
		--package-type Image \
		--architectures $ARCH \
		--region $REGION
}

# Allow users to set the arch
if [[ -z "$1" && -z "$ARCH" ]]; then
	ARCH=$(uname -m)
elif [ -n "$1" ]; then
	ARCH="$1"
fi
case $ARCH in
	x86_64|amd64)
		ARCH='x86_64'
		;;
	aarch64|arm64)
		ARCH='arm64'
		;;
	*)
		echo "ERROR: $ARCH not supported"
		exit 1
		;;
esac

# Allow users to set the region
if [[ -z "$2" && -z "$REGION" ]]; then
	REGION="us-east-2"
elif [ -n "$2" ]; then
	REGION="$2"
fi

# This is the default project Lambda function name
if [[ -z "$3" && -z "$FUNCTION" ]]; then
	FUNCTION="topic-modeling-$ARCH"
elif [ -n "$3" ]; then
	FUNCTION="$3"
fi

# Create Lambda function only if it does not exist
if aws lambda get-function --function-name $FUNCTION --region $REGION &> /dev/null; then
	[ "$ARCH" == "x86_64" ] && arch='amd64' || arch=$ARCH
	image=$(docker images | awk "/$REGION.*topic-modeling.*$ARCH/"'{print $1":"$2}')
	if [ -z "$image" ]; then
		echo "ERROR: no image found for region and/or arch"
		exit 1
	fi
	aws lambda update-function-code --function-name $FUNCTION --image-uri $image --region $REGION
else
	# Deploy Lambda
	create_role
	create_lambda_function 600 2560
fi
