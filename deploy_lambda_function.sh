#!/bin/bash
set -x
cd `dirname $0`

# Check if awscli is installed
./install_awscli.sh

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
		# TODO this should be revised to only allow access to necessary buckets
		aws iam attach-role-policy \
			--role-name "$FUNCTION-$REGION" \
			--policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess
	fi
	ROLE=$(aws iam get-role --role-name "$FUNCTION-$REGION" | awk '/Arn/ {print substr($2, 2, length($2)-3)}')
}

# Allow users to set the arch
if [ -z "$1" ]; then
	case $(uname -m) in
		x86_64)
			ARCH='x86_64'
			;;
		aarch64)
			ARCH='arm64'
			;;
	esac
else
	ARCH=$1
fi

# Allow users to set the region
[ -z "$2" ] && REGION="us-east-2" || REGION="$2"

# This is the default project Lambda function name
[ -z "$3" ] && FUNCTION="topic-modeling-$ARCH" || FUNCTION=$3

# The ECR name
[ -z "$4" ] && IMAGE="topic-modeling-$(uname -m)" || IMAGE=$4

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
