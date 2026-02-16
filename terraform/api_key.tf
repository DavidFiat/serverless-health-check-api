resource "aws_apigatewayv2_authorizer" "api_key" {
  api_id           = aws_apigatewayv2_api.main.id
  authorizer_type  = "REQUEST"
  name             = "${var.environment}-api-key-authorizer"
  identity_sources = ["$request.header.x-api-key"]
}

resource "aws_api_gateway_api_key" "main" {
  name = "${var.environment}-health-check-api-key"
  
  tags = {
    Name = "${var.environment}-health-check-api-key"
  }
}

resource "aws_api_gateway_usage_plan" "main" {
  name = "${var.environment}-health-check-usage-plan"

  api_stages {
    api_id = aws_apigatewayv2_api.main.id
    stage  = aws_apigatewayv2_stage.main.name
  }

  quota_settings {
    limit  = 10000
    period = "DAY"
  }

  throttle_settings {
    rate_limit  = var.api_throttle_rate_limit
    burst_limit = var.api_throttle_burst_limit
  }

  tags = {
    Name = "${var.environment}-health-check-usage-plan"
  }
}

resource "aws_api_gateway_usage_plan_key" "main" {
  key_id        = aws_api_gateway_api_key.main.id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.main.id
}
