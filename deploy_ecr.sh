#!/bin/bash

cd `dirname $0`

# Check if awscli is installed
./install_awscli.sh

# Allow users to set the arch
[ -z "$1" ] && ARCH=`uname -m` || ARCH=$1

# Allow users to set the region
[ -z "$2" ] && REGION="us-east-2" || REGION="$2"

# Set dockerfile
[ -z "$3" ] && DOCKERFILE='Dockerfile' || DOCKERFILE=$3

# This is the default project lambda function name
[ -z "$4" ] && IMAGE="topic-modeling-$ARCH" || IMAGE=$4

# Extract Account ID
id=`aws sts get-caller-identity | sed -n 's|.*Account.*"\([0-9]\+\)".*|\1|p'`

# My container registry portal
ECR=$id.dkr.ecr.$REGION.amazonaws.com
unset id

# Create ECR repo (this step will fail if it exists but we will assume that all is well)
aws ecr create-repository --repository-name $IMAGE --region $REGION 2> /dev/null

# Build/deploy Docker image
docker build -f $DOCKERFILE -t $ECR/$IMAGE .
aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $ECR
docker push $ECR/$IMAGE:latest
