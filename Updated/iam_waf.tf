##############################################################
# Lambda Execution Role for WAF Bedrock Analyzer
##############################################################

resource "aws_iam_role" "waf_lambda_role" {
  name               = "waf-bedrock-analyzer-role"
  assume_role_policy = data.aws_iam_policy_document.waf_lambda_assume_role.json
}

data "aws_iam_policy_document" "waf_lambda_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

##############################################################
# Lambda Policy
##############################################################

resource "aws_iam_policy" "waf_lambda_policy" {
  name = "waf-bedrock-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # CloudWatch Logging
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      },
      # Read WAF Logs
      {
        Effect   = "Allow"
        Action   = ["logs:FilterLogEvents"]
        Resource = aws_cloudwatch_log_group.waf_logs.arn
      },
      # DynamoDB
      {
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:Query",
          "dynamodb:Scan"
        ]
        Resource = aws_dynamodb_table.waf_events.arn
      },
      # Bedrock
      {
        Effect   = "Allow"
        Action   = ["bedrock:InvokeModel"]
        Resource = local.bedrock_model_arn
      }
    ]
  })
}

##############################################################
# Attach Policy to Role  (this attachment did not exist before —
# the policy was defined but never actually applied to anything)
##############################################################

resource "aws_iam_role_policy_attachment" "waf_lambda_attach" {
  role       = aws_iam_role.waf_lambda_role.name
  policy_arn = aws_iam_policy.waf_lambda_policy.arn
}
