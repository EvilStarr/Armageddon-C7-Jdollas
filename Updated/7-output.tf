output "python_sample_url" {
  value = "${aws_api_gateway_stage.prod.invoke_url}${aws_api_gateway_stage.prod.stage_name}"
}
output "node_sample_url" {
  value = "${aws_api_gateway_stage.prod.invoke_url}${aws_api_gateway_stage.prod.stage_name}"
}

output "api_url" {
  value = aws_api_gateway_stage.prod.invoke_url
}
# Outputs -- for cognito 

output "cognito_user_pool_id" {
  value = aws_cognito_user_pool.user_pool.id
}

output "cognito_user_pool_client_id" {
  value = aws_cognito_user_pool_client.user_pool_client.id
}

output "cognito_user_pool_client_secret" {
  value       = aws_cognito_user_pool_client.user_pool_client.client_secret
  description = "do not use in real environments, this is just for testing purposes."
  sensitive   = true
}

output "cognito_user_pool_client_callback_urls" {
  value = aws_cognito_user_pool_client.user_pool_client.callback_urls
}

output "admin_user_pool_group_name" {
  value = aws_cognito_user_group.admin_group.name
}

output "user_user_pool_group_name" {
  value = aws_cognito_user_group.user_group.name
}
# Locals -- centralized config values for Cognito resources.
# Pulling these out makes it easy to tweak naming, URLs, and token lifetimes
# in one place instead of hunting through 5-cognito.tf.