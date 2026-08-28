# ---------------------------------------------
# CloudWatch Log Group For Function Logs
# ---------------------------------------------
# Pre-create the log group so we control retention and encryption
# (Lambda auto-creates one with infinite retention if you don't)
resource "aws_cloudwatch_log_group" "main" {
  name = "/aws/lambda/${var.name}"

  kms_key_id        = var.logs.kms_key_id
  retention_in_days = var.logs.retention_days
  log_group_class   = var.logs.log_group_class

  skip_destroy = var.logs.skip_destroy

  tags = merge(local.tags,
    {
      Name = "/aws/lambda/${var.name}"
      Type = "CloudWatch Log Group"
    }
  )
}
