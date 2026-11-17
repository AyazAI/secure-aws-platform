variable "name_prefix" {
  description = "Short prefix used in resource names."
  type        = string
}

variable "region" {
  description = "Region written into the awslogs driver."
  type        = string
}

variable "log_group_name" {
  description = "CloudWatch log group name. The root module builds the matching ARN for IAM."
  type        = string
}

variable "ecr_repository_name" {
  description = "ECR repository name. The root module builds the matching ARN for IAM."
  type        = string
}

variable "kms_key_arn" {
  description = "Customer managed key for the log group and the ECR repository."
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnets for the service."
  type        = list(string)
}

variable "ecs_security_group_id" {
  description = "Security group attached to the tasks."
  type        = string
}

variable "execution_role_arn" {
  description = "Task execution role ARN."
  type        = string
}

variable "task_role_arn" {
  description = "Task role ARN."
  type        = string
}

variable "target_group_arn" {
  description = "Target group the service registers tasks with."
  type        = string
}

variable "container_image" {
  description = "Image URI to run."
  type        = string
}

variable "container_port" {
  description = "Port the container listens on."
  type        = number
}

variable "container_user" {
  description = "User the container runs as. Empty string keeps the image default."
  type        = string
  default     = ""
}

variable "readonly_root_filesystem" {
  description = "Start the container with a read-only root filesystem and writable tmp volumes."
  type        = bool
}

variable "cpu" {
  description = "Fargate CPU units."
  type        = number
}

variable "memory" {
  description = "Fargate memory in MiB."
  type        = number
}

variable "cpu_architecture" {
  description = "Fargate CPU architecture. ARM64 is the priced default."
  type        = string
}

variable "desired_count" {
  description = "Number of tasks."
  type        = number
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days."
  type        = number
}

variable "tags" {
  description = "Tags applied to resources in this module."
  type        = map(string)
  default     = {}
}
