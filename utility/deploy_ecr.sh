#!/bin/bash

cd `dirname $0`/..

# Allow users to set the arch
if [[ -z "$1" && -z "$ARCH" ]]; then
	ARCH=$(uname -m)
elif [ -n "$1" ]; then
	ARCH=$1
fi
case $ARCH in
	x86_64|amd64)
		ARCH='amd64'
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
if ! docker buildx ls | grep -q '^mybuilder'; then
	docker buildx create --name mybuilder --driver-opt network=host --use
	docker buildx inspect --bootstrap
fi
if [ -z "$(docker images $IMAGE:$ARCH -q)" ]; then
	docker buildx build -t $IMAGE:$ARCH --platform linux/$ARCH --load .
fi
docker tag $IMAGE:$ARCH $ECR/$IMAGE:$ARCH
docker push $ECR/$IMAGE:$ARCH
