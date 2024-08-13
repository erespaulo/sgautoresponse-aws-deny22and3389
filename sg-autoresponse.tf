provider "aws" {
  region = "us-east-1"

  default_tags {
   tags = {
     CentroDeCusto = "XPTO"
     PROJETO     = "unallocated"
     TERRAFORM  = "true"
     PRODUTO  = "unallocated"
   }
 }
}

variable "notification_email_address" {
  description = "This is the email address that will receive change notifications."
  type        = string
}

variable "vpc_id" {
  description = "The ID of the VPC where the security group will be created."
  type        = string
}

variable "namezip" {
  description = "Name of the ZIP file in the bucket."
  type        = string
  default     = "lambda_function_payload.zip"  
}

variable "namebucket" {
  description = "Name of the Bucket where the file will be located."
  type        = string
}

resource "aws_iam_role" "security_group_change_auto_response_role" {
  name = "role-sgautoresponse-dev"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  ]

  inline_policy {
    name = "pol-sgautoresponse-dev"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Sid = "AllowSecurityGroupActions"
          Effect = "Allow"
          Action = ["ec2:RevokeSecurityGroupIngress"]
          Resource = ["*"]
        },
        {
          Sid = "AllowSnsActions"
          Effect = "Allow"
          Action = ["sns:Publish"]
          Resource = aws_sns_topic.sns_topic_for_cloudwatch_event.arn
        }
      ]
    })
  }
}

resource "aws_lambda_function" "security_group_change_auto_response" {
  s3_bucket       = var.namebucket
  s3_key          = var.namezip
  function_name   = "lbd-sgautoresponse-dev"
  role            = aws_iam_role.security_group_change_auto_response_role.arn
  handler         = "index.lambda_handler"
  runtime         = "python3.12"
  description     = "Responds to security group changes"
  memory_size     = 1024
  timeout         = 60
  publish         = true

  environment {
    variables = {
      sns_topic_arn     = aws_sns_topic.sns_topic_for_cloudwatch_event.arn
    }
  }
}


resource "random_string" "id" {
  length  = 8
  special = false
}

resource "aws_lambda_permission" "security_group_change_auto_response_permission" {
  statement_id  = "AllowExecutionFromCloudWatch${random_string.id.result}"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.security_group_change_auto_response.function_name
  principal     = "events.amazonaws.com"
}


resource "aws_cloudwatch_event_rule" "triggered_rule_for_security_group_change_auto_response" {
  name        = "evtrule-sgautoresponse-dev"
  description = "Responds to security group change events"
  event_pattern = jsonencode({
    detail = {
      eventSource = ["ec2.amazonaws.com"]
      eventName   = [
        "AuthorizeSecurityGroupIngress",
        "AuthorizeSecurityGroupEgress",
        "RevokeSecurityGroupEgress",
        "RevokeSecurityGroupIngress",
        "CreateSecurityGroup",
        "DeleteSecurityGroup"
      ]
    }
  })
}

resource "aws_cloudwatch_event_target" "security_group_change_auto_response_target" {
  rule      = aws_cloudwatch_event_rule.triggered_rule_for_security_group_change_auto_response.name
  target_id = "TargetFunctionV1"
  arn       = aws_lambda_function.security_group_change_auto_response.arn
}

resource "aws_sns_topic" "sns_topic_for_cloudwatch_event" {
  name = "BroadcastsMessageToSubscribers"
}

resource "aws_sns_topic_subscription" "sns_topic_subscription_for_cloudwatch_event" {
  topic_arn = aws_sns_topic.sns_topic_for_cloudwatch_event.arn
  protocol  = "email"
  endpoint  = var.notification_email_address

  count = var.notification_email_address != "" ? 1 : 0
}

resource "aws_lambda_permission" "allow_cloudwatch_to_invoke_lambda" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.security_group_change_auto_response.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.triggered_rule_for_security_group_change_auto_response.arn
}
