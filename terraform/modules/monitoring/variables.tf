variable "name_prefix" {
  description = "Short prefix used in alarm and topic names."
  type        = string
}

variable "region" {
  description = "Region written into the dashboard widgets."
  type        = string
}

variable "account_id" {
  description = "Account ID used in the SNS topic policy."
  type        = string
}

variable "kms_key_arn" {
  description = "Customer managed key that encrypts the alarm topic."
  type        = string
}

variable "alert_email" {
  description = "Email address that receives alarm notifications after it confirms the subscription."
  type        = string
}

variable "alb_arn_suffix" {
  description = "Load balancer ARN suffix for CloudWatch dimensions."
  type        = string
}

variable "target_group_arn_suffix" {
  description = "Target group ARN suffix for CloudWatch dimensions."
  type        = string
}

variable "ecs_cluster_name" {
  description = "ECS cluster name for CloudWatch dimensions."
  type        = string
}

variable "ecs_service_name" {
  description = "ECS service name for CloudWatch dimensions."
  type        = string
}

variable "ecs_desired_count" {
  description = "Task count the running-task alarm treats as the minimum."
  type        = number
}

variable "tags" {
  description = "Tags applied to the topic."
  type        = map(string)
  default     = {}
}
