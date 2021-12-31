# Define function directory
ARG FUNCTION_DIR="/function"

# There is an issue in bullseye and qemu which prevents compilation
#FROM python:slim-bullseye as build-image
FROM python:slim-buster as build-image
ARG DEBIAN_FRONTEND=noninteractive

# Install aws-lambda-cpp build dependencies
RUN apt-get update && \
	apt-get install -y \
	g++ \
	make \
	cmake \
	unzip \
	libcurl4-openssl-dev

# Include global arg in this stage of the build
ARG FUNCTION_DIR

# Create function directory
RUN mkdir -p ${FUNCTION_DIR}

# Install the runtime interface client and other app requirements
COPY requirements.txt .
RUN pip install -r requirements.txt --target ${FUNCTION_DIR}

# Copy function code
COPY app.py ${FUNCTION_DIR}
COPY cloud_code ${FUNCTION_DIR}

# Multi-stage build: grab a fresh copy of the base image
#FROM python:slim-bullseye
FROM python:slim-buster

# Include global arg in this stage of the build
ARG FUNCTION_DIR
# Set NLTK_DATA environment variable
ENV NLTK_DATA=${FUNCTION_DIR}/nltk_data

# Set working directory to function root directory
WORKDIR ${FUNCTION_DIR}

# Copy in the build image dependencies
COPY --from=build-image ${FUNCTION_DIR} ${FUNCTION_DIR}

COPY nltk_data ${NLTK_DATA}

ENTRYPOINT [ "/usr/local/bin/python", "-m", "awslambdaric" ]
CMD [ "app.handler" ]
