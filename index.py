import boto3
import os


def lambda_handler(event, context):
    tag = os.getenv('SHUTOFF_TAG')

    ec2 = boto3.resource('ec2')

    filters = [
        {
            'Name': 'tag:Environment',
            'Values': [tag]
        },
        {
            'Name': 'instance-state-name',
            'Values': ['pending', 'running']
        }
    ]

    for instance in ec2.instances.filter(Filters=filters):
        instance.stop()
