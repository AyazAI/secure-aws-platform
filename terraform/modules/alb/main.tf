# This bucket is the access-log destination.
#tfsec:ignore:aws-s3-enable-bucket-logging
resource "aws_s3_bucket" "logs" {
  #checkov:skip=CKV_AWS_18:This bucket stores load balancer access logs. A nested access-log bucket is not part of this demo.
  #checkov:skip=CKV_AWS_144:Cross-region replication is intentionally off. This stack is single-region.
  #checkov:skip=CKV_AWS_145:Application Load Balancer access logs cannot be delivered to a bucket encrypted with a customer managed key. SSE-S3 is the supported mode.
  #checkov:skip=CKV2_AWS_62:Access logs are the record. Event notifications would need a consumer this demo does not run.
  bucket_prefix = "${var.name_prefix}-alb-logs-"
  force_destroy = var.force_destroy
  tags          = merge(var.tags, { Name = "${var.name_prefix}-alb-logs" })
}

resource "aws_s3_bucket_public_access_block" "logs" {
  bucket = aws_s3_bucket.logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "logs" {
  bucket = aws_s3_bucket.logs.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_versioning" "logs" {
  bucket = aws_s3_bucket.logs.id

  versioning_configuration {
    status = "Enabled"
  }
}

# ALB access-log delivery supports SSE-S3, not a customer managed key.
#tfsec:ignore:aws-s3-encryption-customer-key
resource "aws_s3_bucket_server_side_encryption_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id

  rule {
    id     = "expire-alb-logs"
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

data "aws_iam_policy_document" "logs" {
  statement {
    sid    = "DenyInsecureTransport"
    effect = "Deny"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions   = ["s3:*"]
    resources = [aws_s3_bucket.logs.arn, "${aws_s3_bucket.logs.arn}/*"]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }

  statement {
    sid    = "AllowAlbLogDelivery"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["logdelivery.elasticloadbalancing.amazonaws.com"]
    }

    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.logs.arn}/alb/AWSLogs/${var.account_id}/*"]

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [var.account_id]
    }
  }
}

resource "aws_s3_bucket_policy" "logs" {
  bucket = aws_s3_bucket.logs.id
  policy = data.aws_iam_policy_document.logs.json

  depends_on = [aws_s3_bucket_public_access_block.logs]
}

# The load balancer is the public entry point. Tasks have no public IP.
#tfsec:ignore:aws-elb-alb-not-public
resource "aws_lb" "this" {
  #checkov:skip=CKV_AWS_150:Deletion protection is a variable so a demo can be destroyed. Set enable_deletion_protection to true for a longer-lived stack.
  #checkov:skip=CKV2_AWS_20:HTTP is not redirected until acm_certificate_arn is set. This repository does not create a private key or a certificate.
  #checkov:skip=CKV2_AWS_28:AWS WAF is not attached. A web ACL is a separate product charge and is left out of this small demo on purpose.
  name                       = "${var.name_prefix}-alb"
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [var.alb_security_group_id]
  subnets                    = var.public_subnet_ids
  drop_invalid_header_fields = true
  desync_mitigation_mode     = "defensive"
  enable_deletion_protection = var.enable_deletion_protection
  enable_http2               = true
  idle_timeout               = 60
  tags                       = var.tags

  access_logs {
    bucket  = aws_s3_bucket.logs.id
    prefix  = "alb"
    enabled = true
  }

  depends_on = [aws_s3_bucket_policy.logs]
}

resource "aws_lb_target_group" "this" {
  #checkov:skip=CKV_AWS_378:TLS ends at the load balancer. Targets are tasks in private subnets and speak HTTP on the container port.
  name                 = "${var.name_prefix}-app"
  port                 = var.app_port
  protocol             = "HTTP"
  target_type          = "ip"
  vpc_id               = var.vpc_id
  deregistration_delay = 30
  tags                 = var.tags

  health_check {
    enabled             = true
    path                = var.health_check_path
    protocol            = "HTTP"
    matcher             = "200-399"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

# HTTP is the demo listener until an ACM certificate ARN is supplied.
#tfsec:ignore:aws-elb-http-not-used
resource "aws_lb_listener" "http" {
  #checkov:skip=CKV_AWS_2:The demo listener is HTTP until acm_certificate_arn is set. No certificate is stored in this repository.
  #checkov:skip=CKV_AWS_103:This listener is not TLS. The HTTPS listener, when a certificate ARN is set, uses ELBSecurityPolicy-TLS13-1-2-2021-06.
  count = var.acm_certificate_arn == "" ? 1 : 0

  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"
  tags              = var.tags

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }
}

# This listener only redirects to the HTTPS listener.
#tfsec:ignore:aws-elb-http-not-used
resource "aws_lb_listener" "http_redirect" {
  #checkov:skip=CKV_AWS_2:Port 80 only redirects to HTTPS when an ACM certificate is configured.
  #checkov:skip=CKV_AWS_103:This listener redirects. TLS is terminated by the HTTPS listener.
  count = var.acm_certificate_arn == "" ? 0 : 1

  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"
  tags              = var.tags

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener" "https" {
  count = var.acm_certificate_arn == "" ? 0 : 1

  load_balancer_arn = aws_lb.this.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = var.acm_certificate_arn
  tags              = var.tags

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }
}
