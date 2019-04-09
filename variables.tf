variable "shutoff_tag" {}

variable "env_name" {
  default = "AutoShutoff"
}

variable "aws_region" {
  default = "us-east-1"
}

variable "shutoff_time" {
  description = "Crontab expression for when to run the function."
  default     = "cron(00 05 * * ? *)"
}
