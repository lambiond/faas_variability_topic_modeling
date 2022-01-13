#!/bin/bash
which aws > /dev/null && exit
cd /tmp
if ! which unzip > /dev/null; then
	sudo apt update
	sudo apt install -y unzip
fi
curl "https://awscli.amazonaws.com/awscli-exe-linux-`uname -m`.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
printf "\n\nEnter in credentials when prompted, generate in the AWS Console under 'Security credentials' -> 'Access keys'\n\n"
aws configure
aws_config=~/.aws/config
if [ ! -f $aws_config ] || ! grep -q 'cli_binary_format=raw-in-base64-out' $aws_config; then
	echo 'cli_binary_format=raw-in-base64-out' >> $aws_config
fi
