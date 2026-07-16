# https://spacelift.io/blog/terraform-api-gateway
# the api container itself
resource "aws_api_gateway_rest_api" "api" {
  name = "jdollas-API"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

# path segments -- parent is the path node the resource sits under so foo.com/user/profile would have foo.com/user as its parent and foo.com/user has foo.com as its parent
resource "aws_api_gateway_resource" "python" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "python"
}
resource "aws_api_gateway_resource" "node" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "node"
}

# because we're using lambda and lambda returns a full http response, we don't need a method_response or integration_response
resource "aws_api_gateway_method" "python_method" {
  rest_api_id          = aws_api_gateway_rest_api.api.id
  resource_id          = aws_api_gateway_resource.python.id
  http_method          = "GET"
  authorization        = "COGNITO_USER_POOLS"
  authorizer_id        = aws_api_gateway_authorizer.cognito_authorizer.id
  authorization_scopes = ["aws.cognito.signin.user.user_scope"]

}

resource "aws_api_gateway_method" "node_method" {
  rest_api_id          = aws_api_gateway_rest_api.api.id
  resource_id          = aws_api_gateway_resource.node.id
  http_method          = "GET"
  authorization        = "COGNITO_USER_POOLS"
  authorizer_id        = aws_api_gateway_authorizer.cognito_authorizer.id
  authorization_scopes = ["aws.cognito.signin.user.user_scope", "aws.cognito.signin.user.admin_scope"]
}

# lambda integration -- this is what connects the api gateway to the lambda function. It specifies the type of integration (AWS_PROXY for lambda), the uri of the lambda function, and the http method to use when invoking the lambda function. The integration_http_method must be POST for lambda functions because that's how lambda expects to be invoked. The uri is the invoke arn of the lambda function which is different from the function arn. The invoke arn includes the region, account id, and function name, while the function arn only includes the region and account id.
resource "aws_api_gateway_integration" "python_integration" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.python.id
  http_method             = aws_api_gateway_method.python_method.http_method
  integration_http_method = "POST" # this must be post -- In this method, Lambda requires that the POST request be used to invoke any Lambda function.
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.python_lambda.invoke_arn
}

resource "aws_api_gateway_integration" "node_integration" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.node.id
  http_method             = aws_api_gateway_method.node_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.node_lambda.invoke_arn
}

# The Depolyment resource is what actually makes the API live. It takes all the resources, methods, integrations, etc and deploys them to a stage. You can have multiple stages for different environments (prod, staging, dev) or different versions of your API (v1, v2, etc) 

resource "aws_api_gateway_deployment" "api_deployment" {
  rest_api_id = aws_api_gateway_rest_api.api.id

  lifecycle {
    create_before_destroy = true
  }


  depends_on = [
    aws_api_gateway_integration.node_integration,
    aws_api_gateway_integration.python_integration
  ]
}

resource "aws_api_gateway_stage" "prod" {
  deployment_id = aws_api_gateway_deployment.api_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.api.id
  stage_name    = "prod"
}


resource "aws_api_gateway_authorizer" "cognito_authorizer" {
  name            = "CognitoAuthorizer"
  rest_api_id     = aws_api_gateway_rest_api.api.id
  authorizer_uri  = "arn:aws:apigateway:${data.aws_region.current.region}:cognito-idp:authorizer/${aws_cognito_user_pool.user_pool.id}"
  identity_source = "method.request.header.Authorization"
  type            = "COGNITO_USER_POOLS"
  provider_arns   = [aws_cognito_user_pool.user_pool.arn]
}