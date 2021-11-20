#!/bin/bash

# This is the default project lambda function name
MY_ECR=574778148684.dkr.ecr.us-east-2.amazonaws.com

cd `dirname $0`

if [ "`uname -m`" == 'x86_64' ]; then
	DOCKERFILE='Dockerfile_x86'
	MY_FUNCTION='tcss562_term_project'
else
	DOCKERFILE='Dockerfile_arm'
	MY_FUNCTION='tcss562_term_project_arm'
fi

# Build/deploy Docker image
aws ecr get-login-password --region us-east-2 | docker login --username AWS --password-stdin $MY_ECR
docker build -f $DOCKERFILE -t $MY_FUNCTION .
docker tag $MY_FUNCTION:latest $MY_ECR/$MY_FUNCTION:latest
docker push $MY_ECR/$MY_FUNCTION:latest

# Deploy lambda
aws lambda update-function-code --function-name $MY_FUNCTION --image-uri $MY_ECR/$MY_FUNCTION:latest
