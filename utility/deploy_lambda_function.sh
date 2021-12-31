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
}

# Allow users to set the arch
if [[ -z "$1" && -z "$ARCH" ]]; then
	case $(uname -m) in
		x86_64)
			ARCH='x86_64'
			;;
		aarch64)
			ARCH='arm64'
			;;
	esac
elif [ -z "$ARCH" ]; then
	ARCH="$1"
fi

# Allow users to set the region
if [[ -z "$2" && -z "$REGION" ]]; then
	REGION="us-east-2"
elif [ -z "$REGION" ]; then
	REGION="$2"
fi

# This is the default project Lambda function name
if [[ -z "$3" && -z "$FUNCTION" ]]; then
	FUNCTION="topic-modeling-$ARCH"
elif [ -z "$FUNCTION" ]; then
	FUNCTION="$3"
fi

# The ECR name
if [[ -z "$4" && -z "$IMAGE" ]]; then
	IMAGE="topic-modeling"
elif [ -z "$IMAGE" ]; then
	IMAGE="$4"
fi

# My container registry portal
id=`aws sts get-caller-identity | sed -n 's|.*Account.*"\([0-9]\+\)".*|\1|p'`
ECR=$id.dkr.ecr.$REGION.amazonaws.com
unset id

# Create Lambda function only if it does not exist
aws lambda get-function --function-name $FUNCTION --region $REGION &> /dev/null \
	&& exit

# Deploy Lambda
create_role
aws lambda create-function \
	--function-name $FUNCTION \
	--role "$ROLE" \
	--code ImageUri=$ECR/$IMAGE:latest \
	--timeout 900 \
	--memory-size 2048 \
	--package-type Image \
	--architectures $ARCH \
	--region $REGION
