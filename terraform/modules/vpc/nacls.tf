resource "aws_network_acl" "public" {
  vpc_id     = aws_vpc.this.id
  subnet_ids = [for subnet in aws_subnet.public : subnet.id]
  tags       = merge(var.tags, { Name = "${var.name_prefix}-public" })
}

# The public subnet is the load balancer tier. Port 80 is the demo listener.
#tfsec:ignore:aws-ec2-no-public-ingress-acl
resource "aws_network_acl_rule" "public_in_http" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = 100
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 80
  to_port        = 80
}

# Port 443 is the public HTTPS listener when a certificate ARN is set.
#tfsec:ignore:aws-ec2-no-public-ingress-acl
resource "aws_network_acl_rule" "public_in_https" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = 110
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 443
  to_port        = 443
}

# Return traffic for a stateless NACL. 3389 is excluded below.
#tfsec:ignore:aws-ec2-no-public-ingress-acl
resource "aws_network_acl_rule" "public_in_ephemeral_low" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = 120
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 1024
  to_port        = 3388
}

# Return traffic for a stateless NACL. 3389 is excluded above.
#tfsec:ignore:aws-ec2-no-public-ingress-acl
resource "aws_network_acl_rule" "public_in_ephemeral_high" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = 121
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 3390
  to_port        = 65535
}

# Path MTU discovery from any peer. The type and code are fixed.
#tfsec:ignore:aws-ec2-no-public-ingress-acl
resource "aws_network_acl_rule" "public_in_pmtu" {
  #checkov:skip=CKV_AWS_352:ICMP type 3 code 4 is path MTU discovery, not all ports.
  network_acl_id = aws_network_acl.public.id
  rule_number    = 130
  egress         = false
  protocol       = "icmp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  icmp_type      = 3
  icmp_code      = 4
}

resource "aws_network_acl_rule" "public_out_http" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = 100
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 80
  to_port        = 80
}

resource "aws_network_acl_rule" "public_out_https" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = 110
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 443
  to_port        = 443
}

resource "aws_network_acl_rule" "public_out_app" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = 120
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = var.vpc_cidr
  from_port      = var.app_port
  to_port        = var.app_port
}

resource "aws_network_acl_rule" "public_out_ephemeral" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = 130
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 1024
  to_port        = 65535
}

resource "aws_network_acl" "private" {
  vpc_id     = aws_vpc.this.id
  subnet_ids = [for subnet in aws_subnet.private : subnet.id]
  tags       = merge(var.tags, { Name = "${var.name_prefix}-private" })
}

resource "aws_network_acl_rule" "private_in_app" {
  network_acl_id = aws_network_acl.private.id
  rule_number    = 100
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = var.vpc_cidr
  from_port      = var.app_port
  to_port        = var.app_port
}

# Return traffic for NAT egress. Security groups still allow only 443, DNS, and S3.
#tfsec:ignore:aws-ec2-no-public-ingress-acl
resource "aws_network_acl_rule" "private_in_ephemeral_low" {
  network_acl_id = aws_network_acl.private.id
  rule_number    = 110
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 1024
  to_port        = 3388
}

# Return traffic for NAT egress. Port 3389 is not included.
#tfsec:ignore:aws-ec2-no-public-ingress-acl
resource "aws_network_acl_rule" "private_in_ephemeral_high" {
  network_acl_id = aws_network_acl.private.id
  rule_number    = 111
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 3390
  to_port        = 65535
}

resource "aws_network_acl_rule" "private_in_dns_udp" {
  network_acl_id = aws_network_acl.private.id
  rule_number    = 120
  egress         = false
  protocol       = "udp"
  rule_action    = "allow"
  cidr_block     = var.vpc_cidr
  from_port      = 53
  to_port        = 53
}

resource "aws_network_acl_rule" "private_in_dns_tcp" {
  network_acl_id = aws_network_acl.private.id
  rule_number    = 130
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = var.vpc_cidr
  from_port      = 53
  to_port        = 53
}

# Path MTU discovery from any peer. The type and code are fixed.
#tfsec:ignore:aws-ec2-no-public-ingress-acl
resource "aws_network_acl_rule" "private_in_pmtu" {
  #checkov:skip=CKV_AWS_352:ICMP type 3 code 4 is path MTU discovery, not all ports.
  network_acl_id = aws_network_acl.private.id
  rule_number    = 140
  egress         = false
  protocol       = "icmp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  icmp_type      = 3
  icmp_code      = 4
}

resource "aws_network_acl_rule" "private_out_https" {
  network_acl_id = aws_network_acl.private.id
  rule_number    = 100
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 443
  to_port        = 443
}

resource "aws_network_acl_rule" "private_out_ephemeral" {
  network_acl_id = aws_network_acl.private.id
  rule_number    = 110
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = var.vpc_cidr
  from_port      = 1024
  to_port        = 65535
}

resource "aws_network_acl_rule" "private_out_dns_udp" {
  network_acl_id = aws_network_acl.private.id
  rule_number    = 120
  egress         = true
  protocol       = "udp"
  rule_action    = "allow"
  cidr_block     = var.vpc_cidr
  from_port      = 53
  to_port        = 53
}

resource "aws_network_acl_rule" "private_out_dns_tcp" {
  network_acl_id = aws_network_acl.private.id
  rule_number    = 130
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = var.vpc_cidr
  from_port      = 53
  to_port        = 53
}
