# Health Check Lambda Function

Python Lambda function that validates input, logs to CloudWatch, and saves to DynamoDB.

## Requirements
- Python 3.11
- boto3

## Environment Variables
- `DYNAMODB_TABLE`: Name of the DynamoDB table
