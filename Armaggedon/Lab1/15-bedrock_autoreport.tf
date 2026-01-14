############################################
# Bonus G - Bedrock Auto Incident Report Pipeline (SNS -> Lambda -> S3)
############################################

# Required data source for account ID (add this once in your file)
data "aws_caller_identity" "current" {}

# S3 Bucket for incident reports
resource "aws_s3_bucket" "bos_ir_reports_bucket01" {
  bucket = "${var.project_name}-ir-reports-${data.aws_caller_identity.current.account_id}"

  tags = {
    Name = "${var.project_name}-ir-reports-bucket01"
  }
}

# Block all public access
resource "aws_s3_bucket_public_access_block" "bos_ir_reports_pab01" {
  bucket                  = aws_s3_bucket.bos_ir_reports_bucket01.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# IAM Role for Lambda
resource "aws_iam_role" "bos_ir_lambda_role01" {
  name = "${var.project_name}-ir-lambda-role01"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" } # Fixed: quoted service
      Action    = "sts:AssumeRole"
    }]
  })
}

# Custom IAM Policy for Lambda permissions
resource "aws_iam_policy" "bos_ir_lambda_policy01" {
  name = "${var.project_name}-ir-lambda-policy01"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:StartQuery",
          "logs:GetQueryResults",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams",
          "logs:FilterLogEvents"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:DescribeAlarms",
          "cloudwatch:GetMetricData",
          "cloudwatch:GetMetricStatistics"
        ]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = ["ssm:GetParameter", "ssm:GetParameters", "ssm:GetParametersByPath"]
        Resource = "arn:aws:ssm:*:${data.aws_caller_identity.current.account_id}:parameter/lab/db/*"
      },
      {
        Effect   = "Allow"
        Action   = ["secretsmanager:GetSecretValue", "secretsmanager:DescribeSecret"]
        Resource = "arn:aws:secretsmanager:*:${data.aws_caller_identity.current.account_id}:secret:${var.project_name}/rds/mysql*"
      },
      {
        Effect = "Allow"
        Action = ["s3:PutObject", "s3:PutObjectAcl", "s3:GetObject", "s3:ListBucket"]
        Resource = [
          aws_s3_bucket.bos_ir_reports_bucket01.arn,
          "${aws_s3_bucket.bos_ir_reports_bucket01.arn}/*"
        ]
      },
      {
        Effect   = "Allow"
        Action   = ["bedrock:InvokeModel"]
        Resource = "*"
      }
    ]
  })
}

# Attach custom policy to role
resource "aws_iam_role_policy_attachment" "bos_ir_lambda_attach01" {
  role       = aws_iam_role.bos_ir_lambda_role01.name
  policy_arn = aws_iam_policy.bos_ir_lambda_policy01.arn
}

# Attach AWS managed basic execution role (for CloudWatch Logs)
resource "aws_iam_role_policy_attachment" "bos_ir_lambda_basiclogs01" {
  role       = aws_iam_role.bos_ir_lambda_role01.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Package your Lambda code properly (recommended)
data "archive_file" "bos_lambda_package" {
  type        = "zip"
  source_dir  = "${path.module}/lambda_ir_reporter" # Create this folder with your code
  output_path = "${path.module}/lambda_ir_reporter.zip"
}

# Lambda Function
resource "aws_lambda_function" "bos_ir_lambda01" {
  function_name = "${var.project_name}-ir-reporter01"
  role          = aws_iam_role.bos_ir_lambda_role01.arn
  handler       = "handler.lambda_handler" # Assumes your file is handler.py
  runtime       = "python3.11"
  timeout       = 60

  filename         = data.archive_file.bos_lambda_package.output_path
  source_code_hash = data.archive_file.bos_lambda_package.output_base64sha256

  environment {
    variables = {
      REPORT_BUCKET    = aws_s3_bucket.bos_ir_reports_bucket01.bucket
      APP_LOG_GROUP    = "/aws/ec2/${var.project_name}-rds-app"
      WAF_LOG_GROUP    = "aws-waf-logs-${var.project_name}-webacl01"
      SECRET_ID        = "${var.project_name}/rds/mysql"
      SSM_PARAM_PATH   = "/lab/db/"
      BEDROCK_MODEL_ID = "anthropic.claude-3-sonnet-20240229-v1:0" # Example - change to available model
      SNS_TOPIC_ARN    = aws_sns_topic.bos_sns_topic01.arn
    }
  }
}

# SNS Topic Subscription (triggers Lambda on alarm)
resource "aws_sns_topic_subscription" "bos_ir_lambda_sub01" {
  topic_arn = aws_sns_topic.bos_sns_topic01.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.bos_ir_lambda01.arn
}

# Allow SNS to invoke the Lambda
resource "aws_lambda_permission" "bos_allow_sns_invoke01" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.bos_ir_lambda01.function_name
  principal     = "sns.amazonaws.com" # Fixed: quoted
  source_arn    = aws_sns_topic.bos_sns_topic01.arn
}

# Output the report bucket name
output "bos_ir_reports_bucket" {
  value       = aws_s3_bucket.bos_ir_reports_bucket01.bucket
  description = "S3 bucket where auto-generated incident reports are stored"
}
