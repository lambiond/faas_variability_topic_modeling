#!/bin/bash

cd `dirname $0`/..

# Allow users to set the arch
if [[ -z "$1" && -z "$ARCH" ]]; then
	ARCH=`uname -m`
elif [ -z "$ARCH" ]; then
	ARCH=$1
fi

# Allow users to set the region
if [[ -z "$2" && -z "$REGION" ]]; then
	REGION="us-east-2"
elif [ -z "$REGION" ]; then
	REGION="$2"
fi

# This is the default project lambda function name
if [[ -z "$3" && -z "$IMAGE" ]]; then
	IMAGE="topic-modeling-$ARCH"
elif [ -z "$IMAGE" ]; then
	IMAGE=$3
fi

# Extract Account ID
id=`aws sts get-caller-identity | sed -n 's|.*Account.*"\([0-9]\+\)".*|\1|p'`

# My container registry portal
ECR=$id.dkr.ecr.$REGION.amazonaws.com
unset id

# Create ECR repo (this step will fail if it exists but we will assume that all is well)
aws ecr create-repository --repository-name $IMAGE --region $REGION 2> /dev/null

# Build/deploy Docker image
sudo docker build -t $ECR/$IMAGE .
aws ecr get-login-password --region $REGION | sudo docker login --username AWS --password-stdin $ECR
sudo docker push $ECR/$IMAGE:latest
