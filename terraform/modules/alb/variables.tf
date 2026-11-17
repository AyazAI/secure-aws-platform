variable "name_prefix" {
  description = "Short prefix used in resource names."
  type        = string
}

variable "vpc_id" {
  description = "VPC that holds the target group."
  type        = string
}

variable "public_subnet_ids" {
  description = "Public subnets for the load balancer. Two are required."
  type        = list(string)
}

variable "alb_security_group_id" {
  description = "Security group attached to the load balancer."
  type        = string
}

variable "app_port" {
  description = "Port the target group forwards to."
  type        = number
}

variable "health_check_path" {
  description = "HTTP path the load balancer uses for target health."
  type        = string
}

variable "acm_certificate_arn" {
  description = "ACM certificate ARN. Empty string keeps a clear-text HTTP listener."
  type        = string
  default     = ""
}

variable "account_id" {
  description = "Account ID used in the access-log bucket policy."
  type        = string
}

variable "enable_deletion_protection" {
  description = "Block deletion of the load balancer. Leave false when the stack must be easy to tear down."
  type        = bool
}

variable "log_expiration_days" {
  description = "Days before current access-log objects expire."
  type        = number
}

variable "force_destroy" {
  description = "Allow Terraform to delete the access-log bucket even when it still has objects."
  type        = bool
}

variable "tags" {
  description = "Tags applied to resources in this module."
  type        = map(string)
  default     = {}
}
