variable "name_prefix" {
  description = "Short prefix used in resource names."
  type        = string
}

variable "vpc_cidr" {
  description = "IPv4 CIDR for the VPC. It must be a /16 so the module can carve /24 subnets."
  type        = string
}

variable "availability_zones" {
  description = "Exactly two availability zones. Index 0 is where the single NAT gateway is placed when single_nat_gateway is true."
  type        = list(string)
}

variable "app_port" {
  description = "Container port the load balancer may forward to."
  type        = number
}

variable "enable_https" {
  description = "Open port 443 on the load balancer security group. Set true only when an ACM certificate is attached."
  type        = bool
}

variable "single_nat_gateway" {
  description = "Use one NAT gateway in the first public subnet. Set false for one NAT gateway in each availability zone."
  type        = bool
}

variable "region" {
  description = "Region used in the S3 gateway endpoint service name."
  type        = string
}

variable "account_id" {
  description = "Account ID used in the flow-log bucket policy."
  type        = string
}

variable "kms_key_arn" {
  description = "Customer managed key that encrypts the flow-log bucket."
  type        = string
}

variable "log_expiration_days" {
  description = "Days before current flow-log objects expire."
  type        = number
}

variable "force_destroy" {
  description = "Allow Terraform to delete the flow-log bucket even when it still has objects."
  type        = bool
}

variable "tags" {
  description = "Tags applied to resources in this module."
  type        = map(string)
  default     = {}
}
