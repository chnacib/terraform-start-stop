import boto3
import os

def lambda_handler(event, context):
    tag_key = os.environ['TAG_KEY']
    tag_value = os.environ['TAG_VALUE']

    ec2_client = boto3.client('ec2')

    instances = ec2_client.describe_instances(Filters=[
        {
            'Name': f"tag:{tag_key}",
            'Values': [tag_value]
        }
    ])

    print(instances)

    for reservation in instances['Reservations']:
        for instance in reservation['Instances']:
            ec2_client.start_instances(InstanceIds=[instance['InstanceId']])

    return {
        'statusCode': 200,
        'body': 'EC2 instances with the specified tag are started.'
    }