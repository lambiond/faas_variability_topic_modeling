#!/bin/bash

cd `dirname $0`

# Check if awscli is installed
./install_awscli.sh

# My container registry portal
id=`aws sts get-caller-identity | jq -r '.["Account"]'`
MY_ECR=$id.dkr.ecr.us-east-2.amazonaws.com
unset id

# This is the default project lambda function name
if [ "`uname -m`" == 'x86_64' ]; then
	MY_FUNCTION='tcss562_term_project'
else
	MY_FUNCTION='tcss562_term_project_arm'
fi

# Create ECR repo (this step will fail if it exists but we will assume that all is well)
aws ecr create-repository --repository-name $MY_FUNCTION 2> /dev/null

# Build/deploy Docker image
docker build -t $MY_ECR/$MY_FUNCTION .
aws ecr get-login-password --region us-east-2 | docker login --username AWS --password-stdin $MY_ECR
docker push $MY_ECR/$MY_FUNCTION:latest

# Deploy lambda
aws lambda update-function-code --function-name $MY_FUNCTION --image-uri $MY_ECR/$MY_FUNCTION:latest
