#!/bin/bash
which aws > /dev/null && exit
pushd /tmp
if ! which unzip > /dev/null; then
	sudo apt update
	sudo apt install -y unzip
fi
curl "https://awscli.amazonaws.com/awscli-exe-linux-`uname -m`.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
