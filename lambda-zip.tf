# ---------------------------------------------
# Lambda Function — Zip Package Deployment
# ---------------------------------------------
data "archive_file" "main" {
  type        = "zip"
  source_dir  = var.source_path
  output_path = "${path.module}/.builds/${var.name}.zip"

  lifecycle {
    enabled = var.package_type == "Zip"
  }
}


resource "aws_lambda_function" "zip" {
  function_name = var.name
  description   = var.description

  package_type     = "Zip"
  filename         = data.archive_file.main.output_path
  source_code_hash = data.archive_file.main.output_base64sha256
  handler          = var.handler
  runtime          = var.runtime

  architectures = [var.architecture]

  memory_size = var.memory_mb
  timeout     = var.timeout

  reserved_concurrent_executions = var.reserved_concurrent_executions

  role = aws_iam_role.main.arn

  layers = var.layers

  dynamic "environment" {
    for_each = length(var.environment_variables) > 0 ? [1] : []

    content {
      variables = var.environment_variables
    }
  }

  ephemeral_storage {
    size = var.ephemeral_storage_mb
  }


  dynamic "file_system_config" {
    for_each = var.efs != null ? ["enabled"] : []

    content {
      arn              = var.efs.arn
      local_mount_path = var.efs.local_mount_path
    }
  }

  dynamic "vpc_config" {
    for_each = var.vpc != null ? ["enabled"] : []

    content {
      subnet_ids         = var.vpc.subnet_ids
      security_group_ids = var.vpc.security_group_ids
    }
  }

  dynamic "snap_start" {
    for_each = var.snap_start ? ["enabled"] : []

    content {
      apply_on = "PublishedVersions"
    }
  }

  dynamic "dead_letter_config" {
    for_each = var.dead_letter_target_arn != null ? [1] : []
    content {
      target_arn = var.dead_letter_target_arn
    }
  }

  logging_config {
    log_format            = var.logs.format
    log_group             = aws_cloudwatch_log_group.main.name
    system_log_level      = var.logs.format == "JSON" ? var.logs.system_log_level : null
    application_log_level = var.logs.format == "JSON" ? var.logs.application_log_level : null
  }

  tracing_config {
    mode = var.tracing_mode
  }

  tags = merge(local.tags,
    {
      Name = var.name
      Type = "Lambda"
    }
  )

  depends_on = [
    aws_iam_role_policy_attachment.base,
    aws_cloudwatch_log_group.main,
  ]

  lifecycle {
    enabled = var.package_type == "Zip"
  }
}
