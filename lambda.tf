resource "aws_cloudwatch_log_group" "lambda-log-group" {
  name              = "UpdateCloudflareIps"
  count             = var.enabled ? 1 : 0
  retention_in_days = 7
}

resource "aws_iam_role" "iam_for_lambda" {
  count              = var.enabled ? 1 : 0
  name               = "lambda-cloudflare-role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_policy" "policy" {
  name        = "lambda-cloudflare-policy"
  count       = var.enabled ? 1 : 0
  description = "Allows cloudflare ip updating lambda to change security groups"
  policy      = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
      ],
      "Resource": [
          "arn:aws:logs:*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
          "iam:GetRolePolicy",
          "iam:ListGroupPolicies",
          "ec2:DescribeSecurityGroups",
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:RevokeSecurityGroupIngress"
      ],
      "Resource": [
          "*"
      ]
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "policy" {
  count      = var.enabled ? 1 : 0
  role       = aws_iam_role.iam_for_lambda[count.index].id
  policy_arn = aws_iam_policy.policy[count.index].arn
}

data "archive_file" "lambda_zip" {
  count       = var.enabled ? 1 : 0
  type        = "zip"
  source_file = "${path.module}/cloudflare-security-group.py"
  output_path = "${path.module}/lambda.zip"
}

resource "aws_lambda_function" "update-ips" {
  count            = var.enabled ? 1 : 0
  function_name    = "UpdateCloudflareIps"
  filename         = "${path.module}/lambda.zip"
  source_code_hash = data.archive_file.lambda_zip[count.index].output_base64sha256
  handler          = "cloudflare-security-group.lambda_handler"
  role             = aws_iam_role.iam_for_lambda[count.index].arn
  runtime          = "python3.12"
  timeout          = 60
  environment {
    variables = {
      SECURITY_GROUP_ID = var.security_group_id
    }
  }
}
