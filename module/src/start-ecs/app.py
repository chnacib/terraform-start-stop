import boto3
import os
import json

from botocore.config import Config

def lambda_handler(event, context):
    tag_key = os.environ['TAG_KEY']
    tag_value = os.environ['TAG_VALUE']

    client = boto3.client('ecs')

    cluster_list = client.list_clusters()['clusterArns']

    for cluster in cluster_list: 
        service_list = client.list_services(
            cluster=cluster,
            maxResults=100,
            launchType='FARGATE',
        )['serviceArns']

        for service in service_list:
            service_info = client.describe_services(
                cluster=cluster,
                services=[service],
                include=['TAGS']
            )['services'][0]

            if 'tags' in service_info:
                for tag in service_info['tags']:
                    if tag['key'] == tag_key and tag['value'] == tag_value:
                        res = client.update_service(
                            cluster=cluster,
                            service=service,
                            desiredCount=1,
                        )

                        print(res)


    return {
        'statusCode': 200,
        'body': 'ECS Started'
    }