data "archive_file" "waf_bedrock_zip" {
  type        = "zip"
  source_file = "./python/waf_bedrock_analyzer.py"
  output_path = "${path.module}/waf_bedrock_analyzer.zip"
}

resource "aws_lambda_function" "waf_bedrock" {
  function_name = "waf-bedrock-analyzer"
  role          = aws_iam_role.waf_lambda_role.arn
  filename      = data.archive_file.waf_bedrock_zip.output_path
  runtime       = "python3.11"
  handler       = "waf_bedrock_analyzer.lambda_handler"
  timeout       = 30
  memory_size   = 256

  environment {
    variables = {
      WAF_LOG_GROUP     = aws_cloudwatch_log_group.waf_logs.name
      DYNAMODB_TABLE    = aws_dynamodb_table.waf_events.name
      BEDROCK_MODEL_ID  = local.bedrock_model_id
      LOOKBACK_MINUTES  = "10"
    }
  }

  depends_on = [aws_cloudwatch_log_group.lambda_logs]
}
