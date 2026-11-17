data "aws_iam_policy_document" "this" {
  #checkov:skip=CKV_AWS_356:A KMS key policy uses Resource * because the key is the resource. The root statement is what keeps the key from being unmanageable.
  #checkov:skip=CKV_AWS_111:The root statement is the AWS-documented way to let IAM in this account administer the key. Service statements are limited by account conditions.
  #checkov:skip=CKV_AWS_109:kms:* on the account root is required so the key can be rotated and scheduled for deletion. It does not grant that access to the task role.
  statement {
    sid    = "EnableIamPolicies"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["arn:${var.partition}:iam::${var.account_id}:root"]
    }

    actions   = ["kms:*"]
    resources = ["*"]
  }

  statement {
    sid    = "AllowCloudWatchLogs"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["logs.${var.region}.amazonaws.com"]
    }

    actions = [
      "kms:Encrypt*",
      "kms:Decrypt*",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:Describe*",
    ]
    resources = ["*"]

    condition {
      test     = "ArnLike"
      variable = "kms:EncryptionContext:aws:logs:arn"
      values   = ["arn:${var.partition}:logs:${var.region}:${var.account_id}:log-group:*"]
    }
  }

  statement {
    sid    = "AllowFlowLogDelivery"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }

    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey",
    ]
    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [var.account_id]
    }
  }

  statement {
    sid    = "AllowEcr"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ecr.amazonaws.com"]
    }

    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey",
      "kms:CreateGrant",
      "kms:DescribeKey",
    ]
    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "kms:CallerAccount"
      values   = [var.account_id]
    }
  }

  statement {
    sid    = "AllowSnsAndCloudWatchAlarms"
    effect = "Allow"

    principals {
      type = "Service"
      identifiers = [
        "sns.amazonaws.com",
        "cloudwatch.amazonaws.com",
      ]
    }

    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey*",
      "kms:DescribeKey",
    ]
    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [var.account_id]
    }
  }
}

resource "aws_kms_key" "this" {
  description             = var.description
  enable_key_rotation     = true
  deletion_window_in_days = var.deletion_window_in_days
  policy                  = data.aws_iam_policy_document.this.json
  tags                    = var.tags
}

resource "aws_kms_alias" "this" {
  name          = "alias/${var.name_prefix}-platform"
  target_key_id = aws_kms_key.this.key_id
}
