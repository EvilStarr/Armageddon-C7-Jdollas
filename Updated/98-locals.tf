# Locals -- whole-project local values.
# Most of these now derive from variables.tf so a single override
# (tfvars / -var / TF_VAR_*) propagates everywhere it's used.
# Computed/derived values (concatenations, interpolations) stay as locals
# since they aren't meant to be overridden directly.

locals {
  # ---------------------------------------------------------------------
  # Naming
  # ---------------------------------------------------------------------
  user_pool_name        = "${var.project_prefix}-user-pool"
  user_pool_client_name = "${var.project_prefix}-user-pool-client"

  # ---------------------------------------------------------------------
  # Lambda
  # ---------------------------------------------------------------------
  python_lambda_function_name = var.python_lambda_function_name
  node_lambda_function_name   = var.node_lambda_function_name

  # ---------------------------------------------------------------------
  # Cognito -- resource server
  # ---------------------------------------------------------------------
  resource_server_identifier = var.resource_server_identifier
  resource_server_name       = var.resource_server_name

  # ---------------------------------------------------------------------
  # Cognito -- OAuth client config
  # ---------------------------------------------------------------------
  callback_urls       = var.callback_urls
  logout_urls         = var.logout_urls
  allowed_oauth_flows = var.allowed_oauth_flows
  base_oauth_scopes   = var.base_oauth_scopes

  # ---------------------------------------------------------------------
  # Cognito -- token validity (paired with token_validity_units block)
  # ---------------------------------------------------------------------
  access_token_validity_minutes = var.access_token_validity_minutes
  id_token_validity_minutes     = var.id_token_validity_minutes
  refresh_token_validity_days   = var.refresh_token_validity_days
  auth_session_validity_minutes = var.auth_session_validity_minutes # AWS hard limit: 3-15, enforced via validation block in variables.tf

  # ---------------------------------------------------------------------
  # Cognito -- group precedence (lower number = higher priority)
  # ---------------------------------------------------------------------
  admin_group_precedence = var.admin_group_precedence
  user_group_precedence  = var.user_group_precedence
}


 