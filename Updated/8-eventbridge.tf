##############################################################
# EventBridge Schedule
#
# Every 5 minutes check for Cognito tokens that
# were issued but never used.
##############################################################

resource "aws_cloudwatch_event_rule" "unused_token_check" {

  name = "unused-token-check"

  description = "Checks for unused Cognito tokens every 5 minutes."

  schedule_expression = "rate(5 minutes)"

  state = "ENABLED"

  tags = {

    Name        = "Unused Token Schedule"
    Environment = "Lab"
    Project     = "Lambda"

  }

}

##############################################################
# EventBridge Target
##############################################################

resource "aws_cloudwatch_event_target" "unused_token_target" {

  rule = aws_cloudwatch_event_rule.unused_token_check.name

  arn = aws_lambda_function.unused_token_detector.arn

}

##############################################################
# Allow EventBridge to Invoke Lambda
##############################################################

resource "aws_lambda_permission" "allow_eventbridge" {

  statement_id = "AllowExecutionFromEventBridge"

  action = "lambda:InvokeFunction"

  function_name = aws_lambda_function.unused_token_detector.function_name

  principal = "events.amazonaws.com"

  source_arn = aws_cloudwatch_event_rule.unused_token_check.arn

}