variable "name_prefix" {
  description = "Short prefix used in role names."
  type        = string
}

variable "account_id" {
  description = "Account ID used in the assume-role condition."
  type        = string
}

variable "region" {
  description = "Region used in the assume-role condition and the KMS via-service condition."
  type        = string
}

variable "partition" {
  description = "AWS partition, for example aws."
  type        = string
}

variable "app_log_group_arn" {
  description = "ARN of the application log group, without a stream suffix."
  type        = string
}

variable "ecr_repository_arn" {
  description = "ARN of the private ECR repository the execution role may pull from."
  type        = string
}

variable "kms_key_arn" {
  description = "Customer managed key used for the log group and the ECR repository."
  type        = string
}

variable "tags" {
  description = "Tags applied to the roles."
  type        = map(string)
  default     = {}
}
