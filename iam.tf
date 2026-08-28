# ---------------------------------------------
# Execution Role Assumed By The Lambda Function
# ---------------------------------------------
data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}


# Execution role assumed by the Lambda function at invocation time
resource "aws_iam_role" "main" {
  name        = var.use_name_prefix ? null : var.name
  name_prefix = var.use_name_prefix ? "${var.name}-" : null

  assume_role_policy = data.aws_iam_policy_document.assume_role.json

  tags = merge(local.tags,
    {
      Name = var.name
      Type = "IAM Role"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}


# ---------------------------------------------
# Base Execution Policy (VPC Or Basic)
# ---------------------------------------------
# If Lambda attached to VPC, the role also needs ENI management permissions
resource "aws_iam_role_policy_attachment" "base" {
  role = aws_iam_role.main.name
  policy_arn = (
    var.vpc != null
    ? "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
    : "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  )
}


# ---------------------------------------------
# X-Ray Tracing Policy (Active Tracing Only)
# ---------------------------------------------
resource "aws_iam_role_policy_attachment" "xray" {
  role       = aws_iam_role.main.name
  policy_arn = "arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess"

  lifecycle {
    enabled = var.tracing_mode == "Active"
  }
}


# ---------------------------------------------
# Attach Caller-Supplied Managed Policies
# ---------------------------------------------
resource "aws_iam_role_policy_attachment" "additional" {
  for_each = toset(var.iam_policy_arns)

  role       = aws_iam_role.main.name
  policy_arn = each.value
}


# ---------------------------------------------
# Inline Custom Policy From Provided Statements
# ---------------------------------------------
data "aws_iam_policy_document" "additional" {
  dynamic "statement" {
    for_each = var.iam_policies

    content {
      sid       = statement.value.sid
      effect    = statement.value.effect
      actions   = statement.value.actions
      resources = statement.value.resources
    }
  }

  lifecycle {
    enabled = length(var.iam_policies) > 0
  }
}


resource "aws_iam_policy" "additional" {
  name        = var.use_name_prefix ? null : "${var.name}-additional"
  name_prefix = var.use_name_prefix ? "${var.name}-additional-" : null
  policy      = data.aws_iam_policy_document.additional.json

  tags = merge(local.tags,
    {
      Name = "${var.name}-additional"
      Type = "IAM Policy"
    }
  )

  lifecycle {
    create_before_destroy = true
    enabled               = length(var.iam_policies) > 0
  }
}


resource "aws_iam_role_policy_attachment" "additional_custom" {
  role       = aws_iam_role.main.name
  policy_arn = aws_iam_policy.additional.arn

  lifecycle {
    enabled = length(var.iam_policies) > 0
  }
}
