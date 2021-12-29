#!/bin/bash

cd `dirname $0`/utility

# Install docker and docker-compose
./install_docker.sh
# Install AWS CLI 
# (boto3 is another option, the scripts can be updated in the future to use only python)
./install_awscli.sh
# Deploy Docker image using ecr
./deploy_ecr.sh
# Deploy dataset for training and testing into an S3 bucket
./deploy_dataset_s3.sh
# Deploy all lambda functions for warm and cold starts
./deploy_lambda_function.sh
