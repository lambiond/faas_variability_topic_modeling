import logging
import boto3
from botocore.exceptions import ClientError
import os

_s3_client = boto3.client('s3')
_s3_resource = boto3.resource('s3')

def s3_download(file_name, bucket, object_name=None):
    """Download a file to an S3 bucket

    :param file_name: File to download
    :param bucket: Bucket to download to
    :param object_name: S3 object name. If not specified then file_name is used
    :return: True if file was downloaded, else False
    """
    # If S3 object_name was not specified, use file_name
    if object_name is None:
        object_name = os.path.basename(file_name)

    # Upload the file
    try:
        response = _s3_client.download_file(bucket, object_name, file_name)
    except ClientError as e:
        logging.error(e)
        return False
    return True


def s3_upload_file(file_name, bucket, object_name=None):
    """Upload a file to an S3 bucket

    :param file_name: File to upload
    :param bucket: Bucket to upload to
    :param object_name: S3 object name. If not specified then file_name is used
    :return: True if file was uploaded, else False
    """
    # If S3 object_name was not specified, use file_name
    if object_name is None:
        object_name = os.path.basename(file_name)

    # Upload the file
    try:
        response = _s3_client.upload_file(file_name, bucket, object_name)
    except ClientError as e:
        logging.error(e)
        return False
    return True


def s3_upload_object(buffer_object, bucket, object_name):
    """Upload a file to an S3 bucket

    :param buffer_object: buffer object to upload
    :param bucket: Bucket to upload to
    :param object_name: S3 object name.
    :return: True if file was uploaded, else False
    """
    try:
        _s3_resource.Object(bucket, object_name).put(Body=buffer_object)
    except ClientError as e:
        logging.error(e)
        return False
    return True
