variable "name_prefix" {
  description = "Short prefix used in the key alias."
  type        = string
}

variable "description" {
  description = "Description stored on the customer managed key."
  type        = string
}

variable "account_id" {
  description = "Account that owns the key. Used only in the key policy."
  type        = string
}

variable "region" {
  description = "Region the key and the services that use it live in."
  type        = string
}

variable "partition" {
  description = "AWS partition, for example aws."
  type        = string
}

variable "deletion_window_in_days" {
  description = "Days before a scheduled key deletion finishes. The minimum is 7."
  type        = number
  default     = 7
}

variable "tags" {
  description = "Tags applied to the key."
  type        = map(string)
  default     = {}
}
