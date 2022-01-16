#!/bin/bash

REGIONS=('us-east-2' 'ap-northeast-1' 'eu-central-1')
ARCHS=('x86_64' 'arm64')

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
	for arch in ${ARCHS[*]}; do
		# Deploy Docker image using ecr
		./deploy_ecr.sh $arch $region
		# Deploy all lambda functions for arm64 and x86_64
		./deploy_lambda_function.sh $arch $region
		# Create S3 buckets for both arm64 and x86_64
		./make_s3_bucket.sh $arch $region
	done
done
