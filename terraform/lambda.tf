data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/../lambda/index.py"
  output_path = "${path.module}/lambda_function.zip"
}

resource "aws_lambda_function" "health_check" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "${var.environment}-health-check-function"
  role            = aws_iam_role.lambda_execution.arn
  handler         = "index.lambda_handler"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  runtime         = var.lambda_runtime
  memory_size     = var.lambda_memory
  timeout         = var.lambda_timeout

  vpc_config {
    subnet_ids         = [aws_subnet.private_a.id, aws_subnet.private_b.id]
    security_group_ids = [aws_security_group.lambda.id]
  }

  environment {
    variables = {
      DYNAMODB_TABLE = aws_dynamodb_table.requests.name
    }
  }

  tags = {
    Name = "${var.environment}-health-check-function"
  }
}

resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/${var.environment}-health-check-function"
  retention_in_days = 7

  tags = {
    Name = "${var.environment}-health-check-logs"
  }
}
