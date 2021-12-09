#!/bin/bash

cd `dirname $0`

# Check if awscli is installed
./install_awscli.sh

# This is the default project lambda function name
if [[ -z "$1" && "`uname -m`" == 'x86_64' ]]; then
	MY_FUNCTION='tcss562_term_project'
elif [ -z "$1" ]; then
	MY_FUNCTION='tcss562_term_project_arm'
else
	MY_FUNCTION=$1
fi

# Set region
if [ -z "$2" ]; then
	MY_REGION='us-east-2'
else
	MY_REGION=$2
fi

# Set dockerfile
if [ -z "$3" ]; then
	DOCKERFILE='Dockerfile'
else
	DOCKERFILE=$3
fi

# Extract Account ID
id=`aws sts get-caller-identity | sed -n 's|.*Account.*"\([0-9]\+\)".*|\1|p'`

# My container registry portal
MY_ECR=$id.dkr.ecr.$MY_REGION.amazonaws.com
unset id

# Create ECR repo (this step will fail if it exists but we will assume that all is well)
aws ecr create-repository --repository-name $MY_FUNCTION --region $MY_REGION 2> /dev/null

# Build/deploy Docker image
docker build -f $DOCKERFILE -t $MY_ECR/$MY_FUNCTION .
aws ecr get-login-password --region $MY_REGION | docker login --username AWS --password-stdin $MY_ECR
docker push $MY_ECR/$MY_FUNCTION:latest

# Deploy lambda
aws lambda update-function-code --function-name $MY_FUNCTION --image-uri $MY_ECR/$MY_FUNCTION:latest --region $MY_REGION
