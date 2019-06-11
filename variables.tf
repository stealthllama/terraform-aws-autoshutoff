variable "shutoff_tag_name" {
  default = "tag:AutoShutOff"
}

variable "shutoff_tag_value" {
  default = "true"
}

variable "aws_region" {
  default = "us-east-1"
}

variable "shutoff_time" {
  description = "Crontab expression for when to run the function."
  default     = "cron(00 05 * * ? *)"
}

variable "name" {
  default = "AutoShutoffLambda"
}

variable "tags" {
  description = "A map of tags to add to all resources"
  default     = {}
}
