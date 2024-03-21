import boto3
import os

def lambda_handler(event, context):
    tag_key = os.environ['TAG_KEY']
    tag_value = os.environ['TAG_VALUE']

    rds_client = boto3.client('rds')

    #instances
    all_instances = rds_client.describe_db_instances()['DBInstances']

    print(all_instances)

    instances_to_stop = [instance for instance in all_instances if any(tag['Key'] == tag_key and tag['Value'] == tag_value for tag in instance.get('TagList', []))]

    print(instances_to_stop)

    for instance in instances_to_stop:
        if "aurora" in instance['Engine']:
            continue

        if instance['DBInstanceStatus'] == "available":
            rds_client.stop_db_instance(DBInstanceIdentifier=instance['DBInstanceIdentifier'])

    #clusters
    all_clusters = rds_client.describe_db_clusters()['DBClusters']
    
    print(all_clusters)

    clusters_to_stop = [cluster for cluster in all_clusters if any(tag['Key'] == tag_key and tag['Value'] == tag_value for tag in cluster.get('TagList', []))]
    
    print(clusters_to_stop)

    for cluster in clusters_to_stop:
        rds_client.stop_db_cluster(DBClusterIdentifier=cluster['DBClusterIdentifier'])

    return {
        'statusCode': 200,
        'body': 'RDS instances and clusters with the specified tag are stopped.'
    }
