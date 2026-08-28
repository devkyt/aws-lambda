# AWS Lambda

OpenTofu module for Lambda function deployment. You can find how to use it in [example](./example/) folder
and in the [Examples](#examples) section below.

## Table of Contents

- [Requirements](#requirements)
- [Inputs](#inputs)
- [Outputs](#outputs)
- [Examples](#examples)
  - [Basic Zip Function](#basic-zip-function)
  - [Container Image Function](#container-image-function)
  - [Container Image with Overrides](#container-image-with-overrides)
  - [VPC and EFS](#vpc-and-efs)
  - [Additional IAM Permissions](#additional-iam-permissions)
  - [Dead Letter Queue](#dead-letter-queue)
  - [SnapStart for Java](#snapstart-for-java)
  - [Custom Logging](#custom-logging)

## Requirements

| Name | Version |
|------|---------|
| OpenTofu | >= 1.11 |
| AWS provider | ~> 6.0  |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `name` | Name of Lambda function | `string` | - | yes |
| `env` | Target environment | `string` | - | yes |
| `package_type` | Lambda deployment package type | `string` | `"Zip"` | no |
| `description` | Meaningful description for Lambda function | `string` | `null` | no |
| `runtime` | Lambda function runtime. Required when package_type is 'Zip' | `string` | `null` | yes (Zip) |
| `architecture` | Instruction set architecture. Use arm64 for Graviton (20% cheaper) | `string` | `"arm64"` | no |
| `source_path` | Path to Lambda function source code directory. Required when package_type is 'Zip' | `string` | `null` | yes (Zip) |
| `handler` | Lambda function entrypoint. Required when package_type is 'Zip' | `string` | `null` | yes (Zip) |
| `image_uri` | ECR image URI. Required when package_type is 'Image' | `string` | `null` | yes (Image) |
| `image_config` | Container image configuration overrides | `object` | `null` | no |
| `environment_variables` | Non-sensitive environment variables | `map(string)` | `{}` | no |
| `memory_mb` | Memory in MB (also scales CPU proportionally) | `number` | `256` | no |
| `reserved_concurrent_executions` | Reserved concurrency (blast radius limiter). Use -1 for unreserved | `number` | `-1` | no |
| `timeout` | Function timeout in seconds | `number` | `30` | no |
| `iam_policy_arns` | Additional IAM policy ARNs for the Lambda execution role | `list(string)` | `[]` | no |
| `iam_policies` | Additional IAM policy statements for the Lambda execution role | `list(object)` | `[]` | no |
| `vpc` | VPC configuration. Only use if function needs private resource access | `object` | `null` | no |
| `layers` | Lambda Layer ARNs to attach. Only supported with Zip | `list(string)` | `[]` | no |
| `ephemeral_storage_mb` | Size of ephemeral storage (/tmp folder) in MB | `number` | `512` | no |
| `efs` | EFS configuration. Requires vpc to be set | `object` | `null` | no |
| `dead_letter_target_arn` | ARN of SQS queue or SNS topic for failed async invocations | `string` | `null` | no |
| `logs` | Logs configuration | `object` | `{}` | no |
| `snap_start` | Enable SnapStart to eliminate cold starts. Only supported with Zip | `bool` | `false` | no |
| `tracing_mode` | X-Ray tracing mode | `string` | - | yes |
| `use_name_prefix` | Use name_prefix instead of a fixed name for created resources, so AWS appends a unique suffix | `bool` | `false` | no |
| `include_default_tags` | Whether or not to attach default tags specified in module | `bool` | `true` | no |
| `tags` | Tags to attach to Lambda function and the related resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| `function_name` | Name of the Lambda function |
| `arn` | ARN of the Lambda function |
| `invoke_arn` | ARN to invoke the Lambda function (for API Gateway integration) |
| `qualified_arn` | ARN with version suffix |
| `version` | Latest published version of the Lambda function |
| `last_modified` | Date the Lambda function was last modified |
| `role_arn` | ARN of the Lambda execution IAM role |
| `role_name` | Name of the Lambda execution IAM role |
| `cloudwatch_log_group_name` | Name of the CloudWatch log group |
| `cloudwatch_log_group_arn` | ARN of the CloudWatch log group |

## Examples

### Basic Zip Function

A minimal Lambda function deployed from a local source directory.

```hcl
module "lambda" {
  source = "git@github.com:devkyt/aws-lambda.git?ref=main&depth=1"

  name = "whatever-lambda"
  env  = "experiment"

  runtime     = "python3.13"
  handler     = "main.handler"
  source_path = "${path.module}/src"

  tracing_mode = "PassThrough"
}
```

### Container Image Function

Deploying a Lambda function from a container image stored in ECR. When pulling
from a private ECR repository, the Lambda execution role needs permission to
access it. Use `iam_policies` to grant ECR pull access.

```hcl
module "lambda" {
  source = "git@github.com:devkyt/aws-lambda.git?ref=main&depth=1"

  name = "whatever-lambda"
  env  = "experiment"

  package_type = "Image"
  image_uri    = "123456789012.dkr.ecr.eu-central-1.amazonaws.com/whatever:latest"

  iam_policies = [
    {
      sid    = "AllowECRAuth"
      effect = "Allow"
      actions = [
        "ecr:GetAuthorizationToken",
      ]
      resources = ["*"]
    },
    {
      sid    = "AllowECRPull"
      effect = "Allow"
      actions = [
        "ecr:BatchGetImage",
        "ecr:GetDownloadUrlForLayer",
      ]
      resources = ["arn:aws:ecr:eu-central-1:123456789012:repository/whatever"]
    }
  ]

  tracing_mode = "PassThrough"
}
```

### Container Image with Overrides

Overriding the container entrypoint, command and working directory.

```hcl
module "lambda" {
  source = "git@github.com:devkyt/aws-lambda.git?ref=main&depth=1"

  name = "whatever-lambda"
  env  = "experiment"

  package_type = "Image"
  image_uri    = "123456789012.dkr.ecr.eu-central-1.amazonaws.com/whatever:latest"

  image_config = {
    entry_point       = ["/usr/local/bin/python"]
    command           = ["worker.handler"]
    working_directory = "/app"
  }

  memory_mb = 1024
  timeout   = 300

  tracing_mode = "Active"
}
```

### VPC and EFS

Running a Lambda function inside a VPC with an EFS mount for persistent storage.

```hcl
module "lambda" {
  source = "git@github.com:devkyt/aws-lambda.git?ref=main&depth=1"

  name = "whatever-lambda"
  env  = "experiment"

  runtime     = "nodejs20.x"
  handler     = "index.handler"
  source_path = "${path.module}/src"

  vpc = {
    subnet_ids         = ["subnet-0123456789abcdef0", "subnet-0123456789abcdef1"]
    security_group_ids = ["sg-0123456789abcdef0"]
  }

  efs = {
    arn              = "arn:aws:elasticfilesystem:eu-central-1:123456789012:access-point/fsap-0123456789abcdef0"
    local_mount_path = "/mnt/data"
  }

  tracing_mode = "Active"
}
```

### Additional IAM Permissions

Attaching extra IAM policies and inline policy statements for S3 and DynamoDB access.

```hcl
module "lambda" {
  source = "git@github.com:devkyt/aws-lambda.git?ref=main&depth=1"

  name = "whatever-lambda"
  env  = "experiment"

  runtime     = "python3.13"
  handler     = "main.handler"
  source_path = "${path.module}/src"

  iam_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
  ]

  iam_policies = [
    {
      sid       = "DynamoDBReadWrite"
      effect    = "Allow"
      actions   = ["dynamodb:GetItem", "dynamodb:PutItem", "dynamodb:Query"]
      resources = ["arn:aws:dynamodb:eu-central-1:123456789012:table/whatever"]
    }
  ]

  tracing_mode = "PassThrough"
}
```

### Dead Letter Queue

Sending failed async invocations to an SQS dead letter queue.

```hcl
module "lambda" {
  source = "git@github.com:devkyt/aws-lambda.git?ref=main&depth=1"

  name = "whatever-lambda"
  env  = "experiment"

  runtime     = "python3.13"
  handler     = "main.handler"
  source_path = "${path.module}/src"

  dead_letter_target_arn = "arn:aws:sqs:eu-central-1:123456789012:whatever-dlq"

  tracing_mode = "PassThrough"
}
```

### SnapStart for Java

Eliminating cold starts for a Java function using SnapStart.

```hcl
module "lambda" {
  source = "git@github.com:devkyt/aws-lambda.git?ref=main&depth=1"

  name = "whatever-lambda"
  env  = "experiment"

  runtime     = "java21"
  handler     = "com.piedpiper.Handler::handleRequest"
  source_path = "${path.module}/build/libs"

  snap_start = true
  memory_mb  = 512
  timeout    = 60

  tracing_mode = "Active"
}
```

### Custom Logging

Configuring CloudWatch log retention, format, and log levels.

```hcl
module "lambda" {
  source = "git@github.com:devkyt/aws-lambda.git?ref=main&depth=1"

  name = "whatever-lambda"
  env  = "experiment"

  runtime     = "nodejs22.x"
  handler     = "index.handler"
  source_path = "${path.module}/src"

  logs = {
    retention_days        = 30
    format                = "JSON"
    system_log_level      = "WARN"
    application_log_level = "INFO"
    log_group_class       = "INFREQUENT_ACCESS"
  }

  tracing_mode = "PassThrough"
}
```

## License

Licensed under the Apache License, Version 2.0.

Copyright 2026 Kyrylo Tykhanskyi.
