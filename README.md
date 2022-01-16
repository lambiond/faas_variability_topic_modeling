# Topic Modeling pipeline
These steps were executed on Ubuntu 20.04 (x86_64)
## Setup
Run the `setup.sh` script to install docker, awscli, deploy training and testing datasets to S3, deploy a docker image to ECR, and deploy lambda functions.
## Optional Setup
cronjobs can be setup to run daily at 12am.
```
# Configure system local time zone
sudo ln -sf /usr/share/zoneinfo/<path to correct local time> /etc/localtime
sudo service cron restart
sudo service cron status
# Edit (ubuntu) users crontab
crontab -e
# Insert the following lines
0 0 * * * /home/ubuntu/tcss562_topic_modeling/test/test_lambda.sh <arch> <region> <iterations>
# Verify crontab edit is successful
crontab -l
```
## Test
Execute the `test_lambda.sh` script in the test directory.
```
./test/test_lambda.sh <arch> <region> <iterations>
```
## Utilized Tools
Serverless Application Analytics Framework (SAAF) was used for collection of data, see https://github.com/wlloyduw/SAAF
