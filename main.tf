provider "aws" {
  region = "${var.aws_region}"
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/index.py"
  output_path = "${path.module}/autoshutoff.zip"
}

resource "aws_iam_role" "autoshutoff_role" {
  name = "${var.env_name}-AutoShutoffRole"

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

resource "aws_iam_role_policy" "autoshutoff_execution_role" {
  name = "${var.env_name}-AutoShutoff-ExecutionRole"
  role = "${aws_iam_role.autoshutoff_role.id}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "ec2:DescribeInstances",
        "ec2:StopInstances"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_lambda_function" "autoshutoff" {
  function_name    = "${var.env_name}-AutoShutoff"
  filename         = "${data.archive_file.lambda_zip.output_path}"
  source_code_hash = "${data.archive_file.lambda_zip.output_base64sha256}"
  role             = "${aws_iam_role.autoshutoff_role.arn}"
  handler          = "index.lambda_handler"
  runtime          = "python3.7"

  environment {
    variables {
      SHUTOFF_TAG = "${var.shutoff_tag}"
    }
  }
}

resource "aws_cloudwatch_event_rule" "autoshutoff_schedule" {
  name                = "AutoShutoff-Schedule"
  schedule_expression = "${var.shutoff_time}"
}

resource "aws_cloudwatch_event_target" "autoshutoff_nightly" {
  rule      = "${aws_cloudwatch_event_rule.autoshutoff_schedule.name}"
  target_id = "autoshutoff"
  arn       = "${aws_lambda_function.autoshutoff.arn}"
}

resource "aws_lambda_permission" "allow_cloudwatch_to_call_autoshutoff" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.autoshutoff.function_name}"
  principal     = "events.amazonaws.com"
  source_arn    = "${aws_cloudwatch_event_rule.autoshutoff_schedule.arn}"
}
