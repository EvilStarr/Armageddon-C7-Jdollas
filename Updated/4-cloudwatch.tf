# aws will create a log group for you if one isnt specified. the problem is it won't be deleted when you run terraform destory
# Lambda looks for /aws/lambda/<function-name>
#If it exists → it uses it
#If not → it creates it (if permissions allow)
# I think aws now let's you choose the name of the log group
resource "aws_cloudwatch_log_group" "python_lambda_logs" {
  name              = "/aws/lambda/${local.python_lambda_function_name}"
  retention_in_days = 3
}
resource "aws_cloudwatch_log_group" "node_lambda_logs" {
  name              = "/aws/lambda/${local.node_lambda_function_name}"
  retention_in_days = 3
}
