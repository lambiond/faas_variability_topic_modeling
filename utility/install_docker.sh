#!/bin/bash

# Install Docker if not already installed
which docker > /dev/null && exit

sudo apt-get update && sudo apt-get install -y \
	apt-transport-https \
	ca-certificates \
	curl \
	gnupg-agent \
	software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
case $(uname -m) in
	x86_64)
		arch='amd64'
		;;
	aarch64)
		arch='amd64'
		;;
	*)
		echo "ERROR: arch not supported by this script"
		exit 1
		;;
esac
sudo add-apt-repository \
	"deb [arch=$arch] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt-get update && sudo apt-get install -y \
	docker-ce docker-ce-cli containerd.io
if ! sudo docker run --rm hello-world; then
	echo 'ERROR: failed to run hello-world demo image'
	exit 1
fi
sudo docker rmi hello-world:latest
# Setup so that Docker can be run without sudo
sudo usermod -aG docker `whoami`
