#!/bin/bash

# Docker uses amd64->x86_64 and arm64->aarch64
case $(uname -m) in
	x86_64)
		ARCH='amd64'
		;;
	aarch64)
		ARCH='arm64'
		;;
	*)
		echo "ERROR: arch not supported by this script"
		exit 1
		;;
esac

# buildx release to compile a docker image for both x86_64 and arm64
BUILDX_VERSION='v0.7.1'
BUILDX_PATH="$HOME/.docker/cli-plugins/docker-buildx"

# Install Docker if not already installed
if ! which docker > /dev/null; then
	sudo apt-get update && sudo apt-get install -y \
		apt-transport-https \
		ca-certificates \
		curl \
		gnupg-agent \
		software-properties-common
	curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
	sudo add-apt-repository \
		"deb [arch=$ARCH] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
	sudo apt-get update && sudo apt-get install -y \
		docker-ce docker-ce-cli containerd.io
	# Test docker install using hello-world test image
	if ! sudo docker run --rm hello-world; then
		echo 'ERROR: failed to run hello-world demo image'
		exit 1
	fi
	sudo docker rmi hello-world:latest
	# Setup so that Docker can be run without sudo
	sudo usermod -aG docker $USER
fi

# Install biuldx
mkdir -p "$(dirname $BUILDX_PATH)"
wget "https://github.com/docker/buildx/releases/download/$BUILDX_VERSION/buildx-$BUILDX_VERSION.linux-$ARCH" -O "$BUILDX_PATH"
chmod +x "$BUILDX_PATH"
# Setup an alias "docker buildx install"->"docker build"
docker buildx install
