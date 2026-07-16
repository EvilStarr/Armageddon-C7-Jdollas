# lambda role
resource "aws_iam_role" "lambda_execution_role" {
  name               = "lambda_one_exec_role"
  assume_role_policy = data.aws_iam_policy_document.assume_role_doc.json
}

# assume role policy for lambda role
# your execution role needs this to specify that the lambda service can assume it
data "aws_iam_policy_document" "assume_role_doc" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}


resource "aws_lambda_function" "unused_token_detector" {
  function_name = "unused_token_detector"
  role          = aws_iam_role.lambda_execution_role.arn
  filename      = data.archive_file.unused_token_detector_zip.output_path
  runtime       = "python3.11"
  handler       = "unused_token_detector.lambda_handler"
  package_type  = "Zip"

  environment {
    variables = {
      WAF_LOG_GROUP   = aws_cloudwatch_log_group.waf_logs.name
      USER_POOL_ID    = aws_cognito_user_pool.user_pool.id  # so the function knows which pool to inspect
    }
  }

  depends_on = [aws_cloudwatch_log_group.unused_token_detector_logs]
}

data "archive_file" "unused_token_detector_zip" {
  type        = "zip"
  source_file = "./scripts/detection.py" # create this file with your token-checking logic
  output_path = "${path.module}/unused_token_detector.zip"
}

resource "aws_cloudwatch_log_group" "unused_token_detector_logs" {
  name              = "/aws/lambda/unused_token_detector"
  retention_in_days = 3
}

# Permissions for API Gateway to invoke the lambda functions
resource "aws_lambda_permission" "api_python" {
  statement_id  = "AllowAPIGWInvokePythonLambda"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.python_lambda.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.api.execution_arn}/*"
}

resource "aws_lambda_permission" "api_node" {
  statement_id  = "AllowAPIGWInvokeNodeLambda"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.node_lambda.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.api.execution_arn}/*"
}

resource "aws_lambda_function" "python_lambda" {
  function_name = local.python_lambda_function_name
  role          = aws_iam_role.lambda_execution_role.arn
  filename      = data.archive_file.python_lambda_zip.output_path
  runtime       = "python3.11"
  handler       = "lambda-python.lambda_handler" # filename.handler_function_name
  package_type  = "Zip"                          # defaults to zip
  # default memory size is 128MB

  depends_on = [aws_cloudwatch_log_group.python_lambda_logs] # this way we won't create the lambda before the log group bc that would allow aws to create the log group
}

resource "aws_lambda_function" "node_lambda" {
  function_name = local.node_lambda_function_name
  role          = aws_iam_role.lambda_execution_role.arn
  filename      = data.archive_file.node_lambda_zip.output_path
  runtime       = "nodejs24.x"
  handler       = "lambda-node.handler" # filename.handler_function_name
  package_type  = "Zip"                 # defaults to zip
  # default memory size is 128MB

  depends_on = [aws_cloudwatch_log_group.python_lambda_logs] # this way we won't create the lambda before the log group bc that would allow aws to create the log group
}