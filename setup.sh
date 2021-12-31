#!/bin/bash

REGIONS=('us-east-2' 'us-west-2')

cd `dirname $0`/utility

# Install docker and docker-compose
./install_docker.sh
# Install AWS CLI 
# (boto3 is another option, the scripts can be updated in the future to use only python)
./install_awscli.sh
# Deploy functions in each region of interest
for region in ${REGIONS[*]}; do
	# Deploy dataset for training and testing into an S3 bucket
	./deploy_dataset_s3.sh $region
	# Deploy Docker image using ecr
	./deploy_ecr.sh amd64 $region
	./deploy_ecr.sh arm64 $region
	# Deploy all lambda functions for arm64 and x86_64
	./deploy_lambda_function.sh x86_64 $region
	./deploy_lambda_function.sh arm64 $region
	# Create S3 buckets for both arm64 and x86_64
	./make_s3_bucket.sh x86_64 $region
	./make_s3_bucket.sh arm64 $region
done
