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

# This is the default docker image name
IMAGE="topic-modeling"

# My container registry portal
id=`aws sts get-caller-identity | sed -n 's|.*Account.*"\([0-9]\+\)".*|\1|p'`
ECR=$id.dkr.ecr.$REGION.amazonaws.com
unset id

# Create ECR repo (this step will fail if it exists but we will assume that all is well)
aws ecr create-repository --repository-name $IMAGE --image-scanning-configuration scanOnPush=true --region $REGION 2> /dev/null

# Build/deploy Docker image
aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $ECR
docker buildx create --name mybuilder --driver-opt network=host --use
docker buildx inspect --bootstrap
docker buildx build -t $ECR/$IMAGE --platform linux/amd64,linux/arm64 --push .
docker buildx rm mybuilder
