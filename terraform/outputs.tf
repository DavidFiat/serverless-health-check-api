output "api_endpoint" {
  description = "API Gateway endpoint URL"
  value       = aws_apigatewayv2_stage.main.invoke_url
}

output "dynamodb_table_name" {
  description = "DynamoDB table name"
  value       = aws_dynamodb_table.requests.name
}

output "lambda_function_name" {
  description = "Lambda function name"
  value       = aws_lambda_function.health_check.function_name
}
