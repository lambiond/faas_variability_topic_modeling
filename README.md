# Topic Modeling pipeline
These steps were executed on Ubuntu 20.04 (x86_64)
## Setup
Run the `setup.sh` script to install docker, awscli, deploy training and testing datasets to S3, deploy a docker image to ECR, and deploy lambda functions.
## Optional Setup
cronjobs can be setup to run daily at 12am (midnight)
```
# Configure system local time zone
sudo ln -sf /usr/share/zoneinfo/<path to correct local time> /etc/localtime
sudo service cron restart
sudo service cron status
# Edit (ubuntu) users crontab
crontab -e
# Insert the following lines
@daily cd /home/ubuntu/topic-modeling/test && python3 faas_runner.py -e experiments/topic-modeling.json --function topic-modeling-arm64
@daily cd /home/ubuntu/topic-modeling/test && python3 faas_runner.py -e experiments/topic-modeling.json --function topic-modeling-x86_64
# Verify crontab edit is successful
crontab -l
```
## Test
Execute the `faas_runner.py` script in the test directory, this is setup to run the NLP pipeline for 200 iterations.  Note that \<arch\> should be replaced with arm64 or x86_64.
```
cd test
python3 faas_runner.py -e experiments/topic-modeling.json --function topic-modeling-<arch>
```
## Utilized Tools
Serverless Application Analytics Framework (SAAF) was used for collection of data, see https://github.com/wlloyduw/SAAF
