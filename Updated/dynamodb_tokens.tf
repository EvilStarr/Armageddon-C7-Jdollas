# ##############################################################
# # Token Tracking Table
# # Records one item per Cognito login. token_id = "<sub>#<iat>"
# # `used` flips to true the first time the token is presented
# # to python_lambda / node_lambda through API Gateway.
# ##############################################################

# resource "aws_dynamodb_table" "token_tracking" {
#   name         = "token-tracking"
#   billing_mode = "PAY_PER_REQUEST"
#   hash_key     = "token_id"

#   attribute {
#     name = "token_id"
#     type = "S"
#   }

#   ttl {
#     attribute_name = "expires_at"
#     enabled        = true
#   }

#   tags = {
#     Name        = "token-tracking"
#     Environment = "production"
#   }
# }
