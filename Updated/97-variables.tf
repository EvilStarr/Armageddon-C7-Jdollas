# Variables -- whole-project input variables.
# Defaults match the current hardcoded values in the .tf files, so applying
# with no overrides reproduces the existing infrastructure exactly.
# Override via terraform.tfvars, -var flags, or TF_VAR_ environment variables.

# ---------------------------------------------------------------------------
# Provider / region
# ---------------------------------------------------------------------------

variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}

# ---------------------------------------------------------------------------
# Naming / project prefix
# ---------------------------------------------------------------------------

variable "project_prefix" {
  description = "Prefix used for naming Cognito and other resources"
  type        = string
  default     = "jdollas"
}

variable "api_gateway_name" {
  description = "Name of the API Gateway REST API"
  type        = string
  default     = "jdollas-API"
}

variable "waf_name" {
  description = "Name of the WAFv2 Web ACL"
  type        = string
  default     = "jdollas_waf"
}

# ---------------------------------------------------------------------------
# Lambda
# ---------------------------------------------------------------------------

variable "python_lambda_function_name" {
  description = "Name of the Python Lambda function"
  type        = string
  default     = "python_lambda_one"
}

variable "node_lambda_function_name" {
  description = "Name of the Node Lambda function"
  type        = string
  default     = "node_lambda_one"
}

variable "python_lambda_runtime" {
  description = "Runtime for the Python Lambda function"
  type        = string
  default     = "python3.11"
}

variable "node_lambda_runtime" {
  description = "Runtime for the Node Lambda function"
  type        = string
  default     = "nodejs24.x"
}

variable "lambda_log_retention_days" {
  description = "CloudWatch log retention (in days) for Lambda function logs"
  type        = number
  default     = 3
}

# ---------------------------------------------------------------------------
# API Gateway stage
# ---------------------------------------------------------------------------

variable "api_stage_name" {
  description = "Name of the API Gateway deployment stage"
  type        = string
  default     = "prod"
}

# ---------------------------------------------------------------------------
# Cognito
# ---------------------------------------------------------------------------

variable "callback_urls" {
  description = "Allowed OAuth callback URLs for the Cognito user pool client"
  type        = list(string)
  default     = ["https://localhost/callback"]
}

variable "logout_urls" {
  description = "Allowed OAuth logout URLs for the Cognito user pool client"
  type        = list(string)
  default     = ["http://localhost/callback"]
}

variable "allowed_oauth_flows" {
  description = "OAuth flows allowed for the Cognito user pool client"
  type        = list(string)
  default     = ["code"]
}

variable "base_oauth_scopes" {
  description = "Base OAuth scopes (excluding resource-server scopes) for the Cognito user pool client"
  type        = list(string)
  default     = ["email", "openid", "profile"]
}

variable "access_token_validity_minutes" {
  description = "Validity period (minutes) for Cognito access tokens"
  type        = number
  default     = 60
}

variable "id_token_validity_minutes" {
  description = "Validity period (minutes) for Cognito ID tokens"
  type        = number
  default     = 60
}

variable "refresh_token_validity_days" {
  description = "Validity period (days) for Cognito refresh tokens"
  type        = number
  default     = 30
}

variable "auth_session_validity_minutes" {
  description = "Validity period (minutes) for the Cognito auth session. AWS hard limit: must be between 3 and 15."
  type        = number
  default     = 15

  validation {
    condition     = var.auth_session_validity_minutes >= 3 && var.auth_session_validity_minutes <= 15
    error_message = "auth_session_validity_minutes must be between 3 and 15 (AWS Cognito hard limit)."
  }
}

variable "resource_server_identifier" {
  description = "Identifier for the Cognito resource server"
  type        = string
  default     = "api_rest"
}

variable "resource_server_name" {
  description = "Display name for the Cognito resource server"
  type        = string
  default     = "rbac_rest_api"
}

variable "admin_group_precedence" {
  description = "Precedence value for the admin Cognito user group (lower number = higher priority)"
  type        = number
  default     = 1
}

variable "user_group_precedence" {
  description = "Precedence value for the user Cognito user group (lower number = higher priority)"
  type        = number
  default     = 2
}

# ---------------------------------------------------------------------------
# WAF
# ---------------------------------------------------------------------------

variable "waf_blocked_country_codes" {
  description = "ISO country codes to block at the WAF geo-match rule"
  type        = list(string)
  default     = ["CO", "AR", "BR"]
}

variable "waf_rate_limit" {
  description = "Max requests per evaluation window per IP before WAF blocks the source"
  type        = number
  default     = 10
}

variable "waf_rate_limit_window_seconds" {
  description = "Evaluation window (seconds) for the WAF rate-based rule"
  type        = number
  default     = 60
}
