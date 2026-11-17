# This bucket is the flow-log archive.
#tfsec:ignore:aws-s3-enable-bucket-logging
resource "aws_s3_bucket" "flow" {
  #checkov:skip=CKV_AWS_18:This bucket is the flow-log archive. A second access-log bucket would store logs of logs and is not part of this demo.
  #checkov:skip=CKV_AWS_144:Cross-region replication is intentionally off. This stack is single-region.
  #checkov:skip=CKV2_AWS_62:Flow logs are reviewed in the bucket. Event notifications would need a consumer this demo does not run.
  bucket_prefix = "${var.name_prefix}-flow-"
  force_destroy = var.force_destroy
  tags          = merge(var.tags, { Name = "${var.name_prefix}-flow" })
}

resource "aws_s3_bucket_public_access_block" "flow" {
  bucket = aws_s3_bucket.flow.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "flow" {
  bucket = aws_s3_bucket.flow.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_versioning" "flow" {
  bucket = aws_s3_bucket.flow.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "flow" {
  bucket = aws_s3_bucket.flow.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = var.kms_key_arn
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "flow" {
  bucket = aws_s3_bucket.flow.id

  rule {
    id     = "expire-flow-logs"
    status = "Enabled"

    filter {
      prefix = ""
    }

    expiration {
      days = var.log_expiration_days
    }

    noncurrent_version_expiration {
      noncurrent_days = 30
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

data "aws_iam_policy_document" "flow" {
  statement {
    sid    = "DenyInsecureTransport"
    effect = "Deny"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions   = ["s3:*"]
    resources = [aws_s3_bucket.flow.arn, "${aws_s3_bucket.flow.arn}/*"]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }

  statement {
    sid    = "AWSLogDeliveryAclCheck"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }

    actions   = ["s3:GetBucketAcl"]
    resources = [aws_s3_bucket.flow.arn]

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [var.account_id]
    }
  }

  statement {
    sid    = "AWSLogDeliveryWrite"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }

    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.flow.arn}/AWSLogs/${var.account_id}/*"]

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [var.account_id]
    }
  }
}

resource "aws_s3_bucket_policy" "flow" {
  bucket = aws_s3_bucket.flow.id
  policy = data.aws_iam_policy_document.flow.json

  depends_on = [aws_s3_bucket_public_access_block.flow]
}

resource "aws_flow_log" "this" {
  log_destination          = aws_s3_bucket.flow.arn
  log_destination_type     = "s3"
  traffic_type             = "ALL"
  vpc_id                   = aws_vpc.this.id
  max_aggregation_interval = 60
  tags                     = merge(var.tags, { Name = "${var.name_prefix}-flow" })

  destination_options {
    file_format                = "plain-text"
    hive_compatible_partitions = false
    per_hour_partition         = true
  }

  depends_on = [aws_s3_bucket_policy.flow]
}
