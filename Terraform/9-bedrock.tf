##############################################################
# Bedrock Configuration
#
# This lab does not create a Bedrock model.
# The Lambda invokes an existing Bedrock foundation model.
#
# Bedrock model access must already be enabled in the AWS console
# for the selected model and region.
##############################################################

locals {
  bedrock_model_id = "anthropic.claude-3-haiku-20240307-v1:0"
}

##############################################################
# Optional: Bedrock Model ARN
#
# Used by IAM if you want to scope bedrock:InvokeModel
# to one model instead of using Resource = "*".
##############################################################

locals {
  bedrock_model_arn = "arn:aws:bedrock:${var.aws_region}::foundation-model/${local.bedrock_model_id}"
}



# environment {

#   variables = {

#     WAF_LOG_GROUP = aws_cloudwatch_log_group.waf_logs.name

#   }

# }

