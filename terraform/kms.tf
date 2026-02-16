resource "aws_kms_key" "dynamodb" {
  description             = "${var.environment} DynamoDB encryption key"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = {
    Name = "${var.environment}-dynamodb-key"
  }
}

resource "aws_kms_alias" "dynamodb" {
  name          = "alias/${var.environment}-dynamodb-key"
  target_key_id = aws_kms_key.dynamodb.key_id
}
