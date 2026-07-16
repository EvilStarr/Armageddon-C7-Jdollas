
# Cognito user pool -- this is where you manage your users and their authentication. You can create a user pool with different settings like password policies, multi-factor authentication, etc. You can also create app clients for your user pool which are used to authenticate users and get tokens. The app client id is what you use in your frontend to authenticate users and get tokens to access the api gateway.

resource "aws_cognito_user_pool" "user_pool" {
  name                     = local.user_pool_name
  auto_verified_attributes = ["email"] # this will automatically verify the user's email when they sign up, you can also use phone number or other attributes

  software_token_mfa_configuration {
    enabled = true
  }

  password_policy {
    minimum_length    = 8
    require_uppercase = true
    require_lowercase = true
    require_numbers   = true
    require_symbols   = true
  }
  # Enforce MFA for all users -- this is just an example, you can also enforce MFA for specific groups or users
  mfa_configuration = "ON"

  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 2
    }
  }
}

resource "aws_cognito_user_pool_client" "user_pool_client" {
  name                                 = local.user_pool_client_name
  user_pool_id                         = aws_cognito_user_pool.user_pool.id
  generate_secret                      = false               # this is required for the api gateway authorizer to work, if you have a secret then you need to use the client credentials flow which is not supported by api gateway authorizer
  callback_urls                        = local.callback_urls # this is required for the user pool client to work, you can use any url here since we're not actually using the callback urlsin this example, but it needs to be a valid url
  logout_urls                          = local.logout_urls
  allowed_oauth_flows                  = local.allowed_oauth_flows
  allowed_oauth_flows_user_pool_client = true
  auth_session_validity                = local.auth_session_validity_minutes # in minutes, AWS hard limit 3-15
  allowed_oauth_scopes = concat(
    local.base_oauth_scopes,
    [
      "${aws_cognito_resource_server.resource.identifier}/admin_scope",
      "${aws_cognito_resource_server.resource.identifier}/user_scope",
    ]
  )

  supported_identity_providers = ["COGNITO"]
  explicit_auth_flows = [
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH",
    "ALLOW_USER_SRP_AUTH",
  ]

  prevent_user_existence_errors = "ENABLED" # this is a security best practice to prevent user enumeration attacks

  access_token_validity  = local.access_token_validity_minutes # in minutes
  id_token_validity      = local.id_token_validity_minutes     # in minutes
  refresh_token_validity = local.refresh_token_validity_days   # in days

  token_validity_units {
    access_token  = "minutes"
    id_token      = "minutes"
    refresh_token = "days"
  }
}


resource "aws_cognito_resource_server" "resource" {
  identifier   = local.resource_server_identifier
  name         = local.resource_server_name
  user_pool_id = aws_cognito_user_pool.user_pool.id

  scope {
    scope_name        = "admin_scope"
    scope_description = "admin scope description"
  }

  scope {
    scope_name        = "user_scope"
    scope_description = "user scope description"
  }
}

resource "aws_cognito_user_group" "admin_group" {
  name         = "admin"
  description  = "Admin group"
  role_arn     = aws_iam_role.admin_role.arn
  user_pool_id = aws_cognito_user_pool.user_pool.id
  precedence   = local.admin_group_precedence
}

resource "aws_cognito_user_group" "user_group" {
  name         = "user"
  description  = "User group"
  precedence   = local.user_group_precedence
  role_arn     = aws_iam_role.user_role.arn
  user_pool_id = aws_cognito_user_pool.user_pool.id
}