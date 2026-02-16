resource "aws_iam_role" "lambda_execution" {
  name = "${var.environment}-health-check-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })

  tags = {
    Name = "${var.environment}-health-check-lambda-role"
  }
}

resource "aws_iam_role_policy" "lambda_dynamodb" {
  name = "${var.environment}-lambda-dynamodb-policy"
  role = aws_iam_role.lambda_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "dynamodb:PutItem"
      ]
      Resource = aws_dynamodb_table.requests.arn
    }]
  })
}

resource "aws_iam_role_policy" "lambda_logs" {
  name = "${var.environment}-lambda-logs-policy"
  role = aws_iam_role.lambda_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ]
      Resource = "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${var.environment}-health-check-function:*"
    }]
  })
}

data "aws_caller_identity" "current" {}
