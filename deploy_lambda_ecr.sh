#!/bin/bash

cd `dirname $0`

# Check if awscli is installed
./install_awscli.sh

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

# Set dockerfile
if [ -z "$3" ]; then
	DOCKERFILE='Dockerfile'
else
	DOCKERFILE=$3
fi

# This is the default project lambda function name
if [ -z "$4" ]; then
	FUNCTION="topic-modeling-$REGION-$ARCH"
else
	FUNCTION=$4
fi

# Extract Account ID
id=`aws sts get-caller-identity | sed -n 's|.*Account.*"\([0-9]\+\)".*|\1|p'`

# My container registry portal
ECR=$id.dkr.ecr.$REGION.amazonaws.com
unset id

# Create ECR repo (this step will fail if it exists but we will assume that all is well)
aws ecr create-repository --repository-name $FUNCTION --region $REGION 2> /dev/null

# Build/deploy Docker image
docker build -f $DOCKERFILE -t $ECR/$FUNCTION .
aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $ECR
docker push $ECR/$FUNCTION:latest

# Deploy lambda
#aws lambda update-function-code --function-name $FUNCTION --image-uri $ECR/$FUNCTION:latest --region $REGION
