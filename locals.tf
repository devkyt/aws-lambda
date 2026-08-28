locals {
  lambda = var.package_type == "Zip" ? aws_lambda_function.zip : aws_lambda_function.image

  default_tags = var.include_default_tags ? {
    Lambda      = var.name
    Environment = var.env
    Env         = var.env
    Terraform   = "true"
    ManagedBy   = "Terraform"
  } : {}

  tags = merge(local.default_tags, var.tags)
}
