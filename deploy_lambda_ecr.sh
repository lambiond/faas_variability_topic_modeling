#!/bin/bash

# This is the default project lambda function name
MY_ECR=574778148684.dkr.ecr.us-east-2.amazonaws.com
if [ "`uname -m`" == 'x86_64' ]; then
	MY_FUNCTION='tcss562_term_project'
else
	MY_FUNCTION='tcss562_term_project_arm'
fi

cd `dirname $0`

# Check if awscli is installed
./install_awscli.sh

# Build/deploy Docker image
docker build -t $MY_ECR/$MY_FUNCTION .
aws ecr get-login-password --region us-east-2 | docker login --username AWS --password-stdin $MY_ECR
docker push $MY_ECR/$MY_FUNCTION:latest

# Deploy lambda
aws lambda update-function-code --function-name $MY_FUNCTION --image-uri $MY_ECR/$MY_FUNCTION:latest
