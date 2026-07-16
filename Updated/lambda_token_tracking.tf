# ##############################################################
# # Shared IAM role for both token-tracking Lambdas
# ##############################################################

# resource "aws_iam_role" "token_lambda_role" {
#   name               = "token-tracking-lambda-role"
#   assume_role_policy = data.aws_iam_policy_document.waf_lambda_assume_role.json
# }

# resource "aws_iam_role_policy_attachment" "token_lambda_basic" {
#   role       = aws_iam_role.token_lambda_role.name
#   policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
# }

# resource "aws_iam_role_policy" "token_lambda_dynamodb" {
#   name = "token-tracking-dynamodb-access"
#   role = aws_iam_role.token_lambda_role.id

#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Effect = "Allow"
#         Action = [
#           "dynamodb:PutItem",
#           "dynamodb:UpdateItem",
#           "dynamodb:GetItem",
#           "dynamodb:Scan",
#           "dynamodb:Query"
#         ]
#         Resource = aws_dynamodb_table.token_tracking.arn
#       }
#     ]
#   })
# }

# ##############################################################
# # Post Authentication trigger — logs every issued token
# ##############################################################

# data "archive_file" "token_issuance_logger_zip" {
#   type        = "zip"
#   source_file = "./token_issuance_logger.py"
#   output_path = "${path.module}/token_issuance_logger.zip"
# }

# resource "aws_lambda_function" "token_issuance_logger" {
#   function_name = "token_issuance_logger"
#   role          = aws_iam_role.token_lambda_role.arn
#   filename      = data.archive_file.token_issuance_logger_zip.output_path
#   runtime       = "python3.11"
#   handler       = "token_issuance_logger.lambda_handler"
#   timeout       = 5

#   environment {
#     variables = {
#       TOKEN_TABLE = aws_dynamodb_table.token_tracking.name
#     }
#   }
# }

# resource "aws_lambda_permission" "cognito_invoke_logger" {
#   statement_id  = "AllowCognitoInvokeTokenLogger"
#   action        = "lambda:InvokeFunction"
#   function_name = aws_lambda_function.token_issuance_logger.function_name
#   principal     = "cognito-idp.amazonaws.com"
#   source_arn    = aws_cognito_user_pool.user_pool.arn
# }

# ##############################################################
# # unused_token_detector — the piece eventbridge.tf was
# # already referencing but that never actually existed
# ##############################################################




