#!/bin/bash

echo "use deploy_lambda_ecr.sh instead"
exit

# This is the default project lambda function name
MY_FUNCTION=tcss562_term_project
MY_VENV=virtualenv/bin/activate
MY_ZIP=my-deployment-package.zip
MY_BUCKET="s3://tcss562-term-project-group3"

# Check for required packages to make lambdazip
sudo apt update && sudo apt install -y python3.8-venv zip

cd `dirname $0`

# If zip file exists, remove and replace with updated version
if [ -f my-deployment-package.zip ]; then
	rm my-deployment-package.zip
fi

# Create a virtual environment for python dependencies if it doesn't already exist
if [ ! -d virtualenv ]; then
	python3 -m venv virtualenv
fi
source $MY_VENV
# Install packages in virtualenv
pip install pandas gensim nltk
deactivate

# Package dependencies
pushd virtualenv/lib/python3.8/site-packages
zip -r ../../../../$MY_ZIP .
popd
# Package code
zip -g $MY_ZIP app.py
zip -g $MY_ZIP basic_code/topic_model.py
#zip -g $MY_ZIP data/*

# Deploy lambda function via s3 bucket
#aws s3 mb `basename $MY_BUCKET`
aws s3 cp $MY_ZIP $MY_BUCKET
aws lambda update-function-code --function-name $MY_FUNCTION --s3-bucket `basename $MY_BUCKET` --s3-key $MY_ZIP --publish
