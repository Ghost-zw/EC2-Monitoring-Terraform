import json
import boto3
import os

sns = boto3.client('sns')

def lambda_handler(event, context):
    sns.publish(
        TopicArn=os.environ['SNS_TOPIC'],
        Message=json.dumps(event),
        Subject="EC2 Alerts"
    )