import boto3
import os


def lambda_handler(event, context):
    tag_name = os.getenv('SHUTOFF_TAG_NAME')
    tag_value = os.getenv('SHUTOFF_TAG_VALUE')

    ec2 = boto3.resource('ec2')

    filters = [
        {
            'Name': tag_name,
            'Values': [tag_value]
        },
        {
            'Name': 'instance-state-name',
            'Values': ['pending', 'running']
        }
    ]

    for instance in ec2.instances.filter(Filters=filters):
        instance.stop()
