provider "aws"{
    region = "us-east-1"
}

/* SNS Topic */

resource "aws_sns_topic" "alerts" {
    name = "ec2-alerts-topic-v2"
}

/* Email subsciption */

resource "aws_sns_topic_subscription" "email" {
    topic_arn = aws_sns_topic.alerts.arn
    protocol = "email"
    endpoint = var.email
}

/* IAM Role of Lambda */
resource "aws_iam_role" "lambda_role" {
    name = "lambda-ec2-role"

    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [{
            Action = "sts:AssumeRole"
            Effect = "Allow"
            Principal = {
                Service = "lambda.amazonaws.com"
            }
        }]
    })
}

/* IAM Policy */
resource "aws_iam_role_policy" "lambda_policy" {
    role = aws_iam_role.lambda_role.id

    policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Action = ["logs:*"]
                Effect = "Allow"
                Resource = "*"
            },
            {
                Action = ["sns:Publish"]
                Effect = "Allow"
                Resource = aws_sns_topic.alerts.arn
            }
        ]
    })
  
}

/* Lmabda Function */
resource "aws_lambda_function" "monitor" {
    function_name = "ec2-monitor"

    filename         = data.archive_file.lambda_zip.output_path
    handler = "lambda.lambda_handler"
    runtime = "python3.9"
    role = aws_iam_role.lambda_role.arn

    source_code_hash = data.archive_file.lambda_zip.output_base64sha256

    environment {
        variables = {
            SNS_TOPIC = aws_sns_topic.alerts.arn

        }
    }
}

/* Eventbridge Rule */
resource "aws_cloudwatch_event_rule" "ec2_rule" {
    name = "ec2-state-change"

    event_pattern = jsonencode({
        source = ["aws.ec2"],
        "detail-type" = ["EC2 Instance State-change Notification"]
    })
  
}

/* Connect Rule to Lambda */
resource "aws_cloudwatch_event_target" "lambda_target" {
    rule = aws_cloudwatch_event_rule.ec2_rule.name
    arn = aws_lambda_function.monitor.arn
  
}

/* Permission */
resource "aws_lambda_permission" "allow_events" {
    statement_id = "AllowEventBridge"
    action = "lambda:InvokeFunction"
    function_name = aws_lambda_function.monitor.function_name
    principal = "events.amazonaws.com"
    source_arn = aws_cloudwatch_event_rule.ec2_rule.arn  
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "lambda/lambda.py"
  output_path = "lambda/lambda.zip"
}