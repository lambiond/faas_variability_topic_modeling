#!/bin/bash
TOPIC_ARN="$1"
MESSAGE="$2"
/usr/local/bin/aws sns publish --topic-arn "$TOPIC_ARN" --message "$MESSAGE"
