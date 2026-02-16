resource "aws_apigatewayv2_api" "main" {
  name          = "${var.environment}-health-check-api"
  protocol_type = "HTTP"

  tags = {
    Name = "${var.environment}-health-check-api"
  }
}

resource "aws_apigatewayv2_model" "health_request" {
  api_id       = aws_apigatewayv2_api.main.id
  name         = "HealthRequest"
  content_type = "application/json"

  schema = jsonencode({
    type = "object"
    required = ["payload"]
    properties = {
      payload = {
        type = "string"
      }
    }
  })
}

resource "aws_apigatewayv2_stage" "main" {
  api_id      = aws_apigatewayv2_api.main.id
  name        = "$default"
  auto_deploy = true

  default_route_settings {
    throttling_rate_limit  = var.api_throttle_rate_limit
    throttling_burst_limit = var.api_throttle_burst_limit
  }

  tags = {
    Name = "${var.environment}-health-check-api-stage"
  }
}

resource "aws_apigatewayv2_integration" "lambda" {
  api_id           = aws_apigatewayv2_api.main.id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.health_check.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "health_get" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "GET /health"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

resource "aws_apigatewayv2_route" "health_post" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "POST /health"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.health_check.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.main.execution_arn}/*/*/health"
}
