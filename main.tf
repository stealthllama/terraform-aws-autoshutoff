provider "aws" {
  region  = "${var.aws_region}"
  version = "2.12"
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/index.py"
  output_path = "${path.module}/autoshutoff.zip"
}

resource "aws_iam_role" "autoshutoff_role" {
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

  tags = "${merge(map("Name", format("%s-IamRole", var.name)), var.tags)}"
}

resource "aws_iam_role_policy" "autoshutoff_execution_role" {
  name_prefix = "${var.name}-IamRolePolicy-"
  role        = "${aws_iam_role.autoshutoff_role.id}"

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
  function_name    = "${var.name}"
  filename         = "${data.archive_file.lambda_zip.output_path}"
  source_code_hash = "${data.archive_file.lambda_zip.output_base64sha256}"
  role             = "${aws_iam_role.autoshutoff_role.arn}"
  handler          = "index.lambda_handler"
  runtime          = "python3.7"

  environment {
    variables {
      SHUTOFF_TAG_NAME  = "${var.shutoff_tag_name}"
      SHUTOFF_TAG_VALUE = "${var.shutoff_tag_value}"
    }
  }
}

resource "aws_cloudwatch_event_rule" "autoshutoff_schedule" {
  schedule_expression = "${var.shutoff_time}"
  tags                = "${merge(map("Name", format("%s-Schedule", var.name)), var.tags)}"
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
