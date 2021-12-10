# Setup steps
These steps were executed on Ubuntu 20.04 x86_64 filesystem
1. Install docker as described here, https://docs.docker.com/engine/install/ubuntu/
2. Install AWS CLI using the `install_awscli.sh` script in this repo. Note that the script require a *Access Key ID* and *Secret Key* which can be generated in the AWS console.
3. Execute the `deploy_lambda_ecr.sh` script to build a docker image and push it to AWS ECR
4. Create an AWS Lambda function,
    * Select "**Container image**"
    * Set a **Function name** (e.g. tcss562_term_project)
    * "**Browse images**" and select the image generated from the deploy_lambda_ecr.sh script
    * Select "**Create function**"
5. Select **Configuration** tab, under **General configuration** select Edit
    * Enter *2048 MB* for the Memory and *15 min* for the Timeout
6. Under the **Configuration** tab, select **Permissions**,
    * Click on the *Role name* in blue
7. When directed to the IAM console, select **Attach policies**
    * Seach for and attach **AmazonS3FullAccess** to allow the Lambda function to use S3 buckets
8. Execute the *test_lambda.sh* script (this will take ~25-30 minutes to complete but should display stats for each function when finished).
