import json
import uuid
import boto3
import os
from datetime import datetime

dynamodb = boto3.resource('dynamodb')
table_name = os.environ.get('DYNAMODB_TABLE')

def lambda_handler(event, context):
    # Input validation
    try:
        body = json.loads(event.get('body', '{}'))
    except:
        body = {}
    
    if 'payload' not in body:
        return {
            'statusCode': 400,
            'body': json.dumps({'error': 'Missing required field: payload'})
        }
    
    # Log to CloudWatch
    print(f"Health check request received: {json.dumps(event)}")
    
    # Save to DynamoDB
    table = dynamodb.Table(table_name)
    item_id = str(uuid.uuid4())
    
    table.put_item(
        Item={
            'id': item_id,
            'timestamp': datetime.utcnow().isoformat(),
            'payload': body['payload'],
            'request_data': json.dumps(event)
        }
    )
    
    return {
        'statusCode': 200,
        'body': json.dumps({
            'status': 'healthy',
            'message': 'Request processed and saved.',
            'id': item_id
        })
    }
