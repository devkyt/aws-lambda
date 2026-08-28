locals {
  app    = "whatever"
  env    = "experiment"
  region = "eu-central-1"

  tags = {
    Team   = "Research and Development"
    Office = "Hamburg"
  }
}



terraform {
  backend "s3" {
    bucket = "terraform-experiments-state"
    region = "eu-central-1"
    key    = "lambda/whatever/terraform.tfstate"
  }
}


provider "aws" {
  region = local.region
}


module "lambda" {
  source = "git@github.com:devkyt/aws-lambda.git?ref=main&depth=1"

  name = "${local.app}-${local.env}"
  env  = local.env

  runtime     = "python3.13"
  handler     = "main.handler"
  source_path = "${path.module}/app"

  memory_mb = 256
  timeout   = 30

  environment_variables = {
    ENV = local.env
  }

  # Optional: VPC access for private resources
  # vpc = {
  #   subnet_ids         = ["subnet-0123456789abcdef0", "subnet-0123456789abcdef1"]
  #   security_group_ids = ["sg-0123456789abcdef0"]
  # }

  # Optional: EFS mount (requires vpc)
  # efs = {
  #   arn              = "arn:aws:elasticfilesystem:eu-central-1:123456789012:access-point/fsap-0123456789abcdef0"
  #   local_mount_path = "/mnt/data"
  # }

  # Optional: dead letter queue for failed async invocations
  # dead_letter_target_arn = "arn:aws:sqs:eu-central-1:123456789012:whatever-dlq"

  # Optional: additional IAM permissions
  # iam_policy_arns = [
  #   "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
  # ]

  logs = {
    retention_days = 7
  }

  tracing_mode = "PassThrough"

  tags = local.tags
}
