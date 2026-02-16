# Main Terraform configuration
# This file serves as the entry point for the infrastructure

# All resources are defined in separate files:
# - provider.tf: AWS provider configuration
# - variables.tf: Input variables
# - dynamodb.tf: DynamoDB table
# - iam.tf: IAM roles and policies
# - lambda.tf: Lambda function
# - api_gateway.tf: API Gateway configuration
# - outputs.tf: Output values
