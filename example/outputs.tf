output "function_name" {
  description = "Name of the Lambda function"
  value       = module.lambda.function_name
}


output "arn" {
  description = "ARN of the Lambda function"
  value       = module.lambda.arn
}


output "invoke_arn" {
  description = "ARN to invoke the Lambda function"
  value       = module.lambda.invoke_arn
}
