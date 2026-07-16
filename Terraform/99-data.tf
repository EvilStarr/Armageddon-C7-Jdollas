# lambda function
## use terraform to zip the file
data "archive_file" "python_lambda_zip" {
  type        = "zip"
  source_file = "./lambda-python.py" # ← was ../
  output_path = "${path.module}/python.zip"
}

data "archive_file" "node_lambda_zip" {
  type        = "zip"
  source_file = "./lambda-node.js" # ← was ../
  output_path = "${path.module}/node.zip"
}

data "aws_iam_policy_document" "waf_log_policy_doc" {
  version = "2012-10-17"
  statement {
    effect = "Allow"
    principals {
      identifiers = ["delivery.logs.amazonaws.com"]
      type        = "Service"
    }
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["${aws_cloudwatch_log_group.waf_log_group.arn}:*"]
    # apply this policy to all log groups in my account
    # condition {
    #   test     = "ArnLike"
    #   values   = ["arn:aws:logs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:*"]
    #   variable = "aws:SourceArn"
    # }
    # apply to only log groups that start with aws-waf-logs-week34...with the below the logs weren't writing
    # condition {
    #   test     = "ArnLike"
    #   values   = ["${aws_cloudwatch_log_group.waf_log_group.arn}:*"]
    #   variable = "aws:SourceArn"
    # }
    # only allow when the source account is equal to my account
    condition {
      test     = "StringEquals"
      values   = [tostring(data.aws_caller_identity.current.account_id)]
      variable = "aws:SourceAccount"
    }
  }
}

data "aws_region" "current" {}

data "aws_caller_identity" "current" {}
# resource "aws_dynamodb_table" "basic-dynamodb-table" {
#   name           = "token-tracking"
#   billing_mode   = "PROVISIONED"
#   read_capacity  = 20
#   write_capacity = 20
#   hash_key       = "token_id"

#   attribute {
#     name = "UserId"
#     type = "S"
#   }

#   attribute {
#     name = "GameTitle"
#     type = "S"
#   }

#   attribute {
#     name = "TopScore"
#     type = "N"
#   }

#   ttl {
#     attribute_name = "TimeToExist"
#     enabled        = true
#   }

#   global_secondary_index {
#     name               = "GameTitleIndex"
#     hash_key           = "GameTitle"
#     write_capacity     = 10
#     read_capacity      = 10
#     projection_type    = "INCLUDE"
#     non_key_attributes = ["UserId"]
#   }

#   tags = {
#     Name        = "dynamodb-table-1"
#     Environment = "production"
#   }
# }

data "aws_iam_policy_document" "group_assume_role_doc" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cognito-idp.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}