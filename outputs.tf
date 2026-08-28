output "function_name" {
  description = "Name of the Lambda function"
  value       = local.lambda.function_name
}

output "arn" {
  description = "ARN of the Lambda function"
  value       = local.lambda.arn
}

output "invoke_arn" {
  description = "ARN to invoke the Lambda function (for API Gateway integration)"
  value       = local.lambda.invoke_arn
}

output "qualified_arn" {
  description = "ARN with version suffix"
  value       = local.lambda.qualified_arn
}

output "version" {
  description = "Latest published version of the Lambda function"
  value       = local.lambda.version
}

output "last_modified" {
  description = "Date the Lambda function was last modified"
  value       = local.lambda.last_modified
}


output "role_arn" {
  description = "ARN of the Lambda execution IAM role"
  value       = aws_iam_role.main.arn
}

output "role_name" {
  description = "Name of the Lambda execution IAM role"
  value       = aws_iam_role.main.name
}


output "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch log group"
  value       = aws_cloudwatch_log_group.main.name
}

output "cloudwatch_log_group_arn" {
  description = "ARN of the CloudWatch log group"
  value       = aws_cloudwatch_log_group.main.arn
}
