variable "name" {
  description = "Name of Lambda function"
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9-_]{1,64}$", var.name))
    error_message = "Function name must be 1-64 characters: letters, digits, hyphens, underscores."
  }
}

variable "env" {
  description = "Target environment"
  type        = string
}


variable "package_type" {
  description = "Lambda deployment package type"
  type        = string
  default     = "Zip"

  validation {
    condition     = contains(["Zip", "Image"], var.package_type)
    error_message = "Package type must be 'Zip' or 'Image'."
  }
}


variable "description" {
  description = "Meaningful description for Lambda function"
  type        = string
  default     = null
}


variable "runtime" {
  description = "Lambda function runtime. Required when package_type is 'Zip'. Not used with 'Image'."
  type        = string
  default     = null

  validation {
    condition     = var.package_type == "Image" || var.runtime != null
    error_message = "Runtime is required when package_type is 'Zip'."
  }

  validation {
    condition = var.runtime == null || contains([
      "nodejs18.x", "nodejs20.x", "nodejs22.x",
      "python3.9", "python3.10", "python3.11", "python3.12", "python3.13",
      "java8.al2", "java11", "java17", "java21",
      "dotnet6", "dotnet8",
      "ruby3.2", "ruby3.3",
      "provided.al2", "provided.al2023",
    ], var.runtime)
    error_message = "Invalid runtime. See https://docs.aws.amazon.com/lambda/latest/dg/lambda-runtimes.html for supported runtimes."
  }
}


variable "architecture" {
  description = "Instruction set architectures for processors. Use arm64 for Graviton (20% cheaper)"
  type        = string
  default     = "arm64"

  validation {
    condition     = contains(["x86_64", "arm64"], var.architecture)
    error_message = "Architecture must be x86_64 or arm64."
  }
}


variable "source_path" {
  description = "Path to Lambda function source code directory. Required when package_type is 'Zip'."
  type        = string
  default     = null

  validation {
    condition     = var.package_type == "Image" || var.source_path != null
    error_message = "source_path is required when package_type is 'Zip'."
  }
}


variable "handler" {
  description = "Lambda function entrypoint. Required when package_type is 'Zip'. Not used with 'Image'."
  type        = string
  default     = null

  validation {
    condition     = var.package_type == "Image" || var.handler != null
    error_message = "handler is required when package_type is 'Zip'."
  }
}


variable "environment_variables" {
  description = "Non-sensitive environment variables"
  type        = map(string)
  default     = {}
}


variable "memory_mb" {
  description = "Memory in MB (also scales CPU proportionally)"
  type        = number
  default     = 256

  validation {
    condition     = var.memory_mb >= 128 && var.memory_mb <= 10240
    error_message = "Memory must be between 128 and 10240 MB."
  }
}


variable "reserved_concurrent_executions" {
  description = "Reserved concurrency (blast radius limiter). Use -1 for unreserved."
  type        = number
  default     = -1

  validation {
    condition     = var.reserved_concurrent_executions == -1 || var.reserved_concurrent_executions >= 0
    error_message = "Reserved concurrent executions must be -1 (unreserved) or >= 0."
  }
}


variable "timeout" {
  description = "Function timeout in seconds"
  type        = number
  default     = 30

  validation {
    condition     = var.timeout >= 1 && var.timeout <= 900
    error_message = "Timeout must be between 1 and 900 seconds."
  }
}


variable "iam_policy_arns" {
  description = "Additional IAM policy ARNs for the Lambda execution role"
  type        = list(string)
  default     = []
}


variable "iam_policies" {
  description = "Additional IAM policy statements for the Lambda execution role"
  type = list(object({
    sid       = string
    effect    = string
    actions   = list(string)
    resources = list(string)
  }))
  default = []

  validation {
    condition     = alltrue([for s in var.iam_policies : contains(["Allow", "Deny"], s.effect)])
    error_message = "Effect must be 'Allow' or 'Deny'."
  }
}


variable "vpc" {
  description = "VPC configuration. Only use if function needs private resource access."
  type = object({
    subnet_ids         = list(string)
    security_group_ids = list(string)
  })
  default = null
}


variable "image_uri" {
  description = "ECR image URI for the Lambda function. Required when package_type is 'Image'."
  type        = string
  default     = null

  validation {
    condition     = var.package_type == "Zip" || var.image_uri != null
    error_message = "image_uri is required when package_type is 'Image'."
  }

  validation {
    condition     = var.image_uri == null || can(regex("^\\d+\\.dkr\\.ecr\\.[a-z0-9-]+\\.amazonaws\\.com/.+", var.image_uri))
    error_message = "image_uri must be a valid ECR URI: <account>.dkr.ecr.<region>.amazonaws.com/<repo>:<tag>."
  }
}


variable "image_config" {
  description = "Container image configuration overrides. Only used when package_type is 'Image'."
  type = object({
    command           = optional(list(string))
    entry_point       = optional(list(string))
    working_directory = optional(string)
  })
  default = null

  validation {
    condition     = var.image_config == null || var.package_type == "Image"
    error_message = "image_config can only be set when package_type is 'Image'."
  }
}


variable "layers" {
  description = "Lambda Layer ARNs to attach. Only supported with package_type 'Zip'."
  type        = list(string)
  default     = []

  validation {
    condition     = length(var.layers) <= 5
    error_message = "Lambda supports a maximum of 5 layers."
  }

  validation {
    condition     = length(var.layers) == 0 || var.package_type == "Zip"
    error_message = "Layers are not supported when package_type is 'Image'."
  }
}


variable "ephemeral_storage_mb" {
  description = "Size of ephemeral storage (/tmp folder) in MB"
  type        = number
  default     = 512

  validation {
    condition     = var.ephemeral_storage_mb >= 512 && var.ephemeral_storage_mb <= 10240
    error_message = "Ephemeral storage must be between 512 and 10240 MB."
  }
}


variable "efs" {
  description = "Configuration for EFS that will be attached to Lambda. Requires vpc to be set."
  type = object({
    arn              = string
    local_mount_path = string
  })
  default = null

  validation {
    condition     = var.efs == null || can(regex("^/mnt/", var.efs.local_mount_path))
    error_message = "EFS local_mount_path must start with '/mnt/'."
  }

  validation {
    condition     = var.efs == null || var.vpc != null
    error_message = "EFS requires VPC configuration. Set the 'vpc' variable when using 'efs'."
  }
}


variable "dead_letter_target_arn" {
  description = "ARN of SQS queue or SNS topic for failed async invocations"
  type        = string
  default     = null

  validation {
    condition     = var.dead_letter_target_arn == null || can(regex("^arn:aws[a-zA-Z-]*:(sqs|sns):", var.dead_letter_target_arn))
    error_message = "Dead letter target must be an SQS queue or SNS topic ARN."
  }
}


variable "logs" {
  description = "Logs configuration"
  type = object({
    retention_days        = optional(number, 14)
    format                = optional(string, "JSON")
    kms_key_id            = optional(string)
    log_group_class       = optional(string)
    skip_destroy          = optional(bool, false)
    system_log_level      = optional(string, "INFO")
    application_log_level = optional(string, "INFO")
  })
  default = {}

  validation {
    condition     = contains(["JSON", "Text"], var.logs.format)
    error_message = "Log format must be 'JSON' or 'Text'."
  }

  validation {
    condition     = contains(["DEBUG", "INFO", "WARN"], var.logs.system_log_level)
    error_message = "System log level must be 'DEBUG', 'INFO', or 'WARN'."
  }

  validation {
    condition     = contains(["TRACE", "DEBUG", "INFO", "WARN", "ERROR", "FATAL"], var.logs.application_log_level)
    error_message = "Application log level must be one of: TRACE, DEBUG, INFO, WARN, ERROR, FATAL."
  }

  validation {
    condition = contains([
      0, 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180,
      365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653,
    ], var.logs.retention_days)
    error_message = "Retention days must be a value supported by CloudWatch: 0, 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, or 3653."
  }

  validation {
    condition     = var.logs.log_group_class == null || contains(["STANDARD", "INFREQUENT_ACCESS"], var.logs.log_group_class)
    error_message = "Log group class must be 'STANDARD' or 'INFREQUENT_ACCESS'."
  }
}


variable "snap_start" {
  description = "Enable SnapStart to eliminate cold starts (supported for Java, Python, .NET). Only supported with package_type 'Zip'."
  type        = bool
  default     = false

  validation {
    condition     = var.snap_start == false || var.package_type == "Zip"
    error_message = "SnapStart is only supported when package_type is 'Zip'."
  }
}


variable "tracing_mode" {
  description = "X-Ray tracing mode"
  type        = string

  validation {
    condition     = contains(["Active", "PassThrough"], var.tracing_mode)
    error_message = "Tracing mode must be 'Active' or 'PassThrough'."
  }
}


variable "use_name_prefix" {
  description = "Use name_prefix instead of a fixed name for the resources this module creates, so AWS appends a unique suffix"
  type        = bool
  default     = false
}


variable "include_default_tags" {
  description = "Whether or not to attach default tags specified in module"
  type        = bool
  default     = true
}


variable "tags" {
  description = "Tags to attach to Lambda function and the related resources"
  type        = map(string)
  default     = {}
}
