import boto3
import os
import json

from botocore.config import Config

def lambda_handler(event, context):
    tag_key = os.environ['TAG_KEY']
    tag_value = os.environ['TAG_VALUE']

    client = boto3.client('autoscaling')

    asg_list = client.describe_auto_scaling_groups()['AutoScalingGroups']
    
    for asg in asg_list: 

        for tag in asg['Tags']:
            if tag['Key'] == tag_key and tag['Value'] == tag_value:
                res = client.update_auto_scaling_group(
                    AutoScalingGroupName=asg['AutoScalingGroupName'],
                    DesiredCapacity=0,
                    MinSize=0
                )

                print(res)

    return {
        'statusCode': 200,
        'body': 'ASG Stopped'
    }