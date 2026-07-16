# lambda policies
# for now we only need the basic lambda policy
# if we wanted more permissions we would create an inline policy for the role or an aws_iam_role_poilcy_resource or an aws_iam_policy with an aws_iam_role_policy_attachment
resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role" "group_role" {
  name               = "group_role"
  assume_role_policy = data.aws_iam_policy_document.group_assume_role_doc.json
}

data "aws_iam_policy_document" "cognito_assume_role_doc" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = ["cognito-identity.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "cognito-identity.amazonaws.com:aud"
      values   = [] # populate with your identity pool ID if using one
    }
  }
}

resource "aws_iam_role" "admin_role" {
  name               = "cognito-admin-role"
  assume_role_policy = data.aws_iam_policy_document.cognito_assume_role_doc.json
}

resource "aws_iam_role" "user_role" {
  name               = "cognito-user-role"
  assume_role_policy = data.aws_iam_policy_document.cognito_assume_role_doc.json
}
#new stuff from theo services json

