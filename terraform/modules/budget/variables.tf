variable "name_prefix" {
  description = "Short prefix used in the budget name."
  type        = string
}

variable "limit_usd" {
  description = "Monthly account cost ceiling in USD. This is a chosen limit, not a price quote."
  type        = string
}

variable "alert_email" {
  description = "Email address that receives budget notifications."
  type        = string
}
