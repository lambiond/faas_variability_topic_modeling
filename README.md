# Topic Modeling pipeline
These steps were executed on Ubuntu 20.04 (x86_64)
## Setup
* Run the `setup.sh` script to install docker, awscli, deploy training and testing datasets to S3, deploy a docker image to ECR, and deploy lambda functions.
## Test
* Execute the `test/test_lambda_<region>_<arch>.sh` script to test Lambda functions in an infinite loop
## External Tools
Serverless Application Analytics Framework (SAAF) was used for collection of data, see https://github.com/wlloyduw/SAAF
