variable "aws_region" {
  description = "AWS region for the demo. The cost section prices us-east-1."
  type        = string
  default     = "us-east-1"

  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[0-9]$", var.aws_region))
    error_message = "aws_region must look like a commercial region name, for example us-east-1."
  }
}

variable "name_prefix" {
  description = "Short lowercase prefix for resource names."
  type        = string
  default     = "sapdemo"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{2,15}$", var.name_prefix))
    error_message = "name_prefix must be 3-16 characters, start with a letter, and contain only lowercase letters, digits, and hyphens."
  }
}

variable "environment" {
  description = "Value of the Environment tag."
  type        = string
  default     = "demo"

  validation {
    condition     = can(regex("^[a-z0-9-]{2,20}$", var.environment))
    error_message = "environment must be 2-20 characters of lowercase letters, digits, and hyphens."
  }
}

variable "vpc_cidr" {
  description = "Example IPv4 CIDR for the VPC. This is a design choice, not a network from an existing account."
  type        = string
  default     = "10.40.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0)) && tonumber(split("/", var.vpc_cidr)[1]) == 16
    error_message = "vpc_cidr must be an IPv4 /16."
  }
}

variable "availability_zones" {
  description = "Two availability zones in aws_region. The cost estimate counts two load-balancer public IPv4 addresses from this list."
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]

  validation {
    condition     = length(var.availability_zones) == 2 && length(distinct(var.availability_zones)) == 2
    error_message = "Provide exactly two distinct availability zones."
  }
}

variable "single_nat_gateway" {
  description = "Use one NAT gateway. Set false for one NAT gateway in each availability zone."
  type        = bool
  default     = true
}

variable "container_image" {
  description = "Image to run. The demo example uses a public nginx image so a task can start before sample-app is pushed."
  type        = string
  default     = "public.ecr.aws/nginx/nginx:1.27-alpine"
}

variable "container_port" {
  description = "Port the container listens on."
  type        = number
  default     = 80

  validation {
    condition     = var.container_port > 0 && var.container_port < 65536
    error_message = "container_port must be a TCP port."
  }
}

variable "container_user" {
  description = "User the container runs as. Empty keeps the image default. sample-app uses 101."
  type        = string
  default     = ""
}

variable "health_check_path" {
  description = "HTTP path the load balancer checks. The public nginx image answers /. sample-app answers /healthz."
  type        = string
  default     = "/"

  validation {
    condition     = startswith(var.health_check_path, "/")
    error_message = "health_check_path must start with /."
  }
}

variable "readonly_root_filesystem" {
  description = "Run the container with a read-only root filesystem. Leave false for the public nginx image."
  type        = bool
  default     = false
}

variable "ecs_cpu" {
  description = "Fargate CPU units. 256 is 0.25 vCPU."
  type        = number
  default     = 256

  validation {
    condition     = contains([256, 512, 1024, 2048, 4096], var.ecs_cpu)
    error_message = "ecs_cpu must be a Fargate CPU value."
  }
}

variable "ecs_memory" {
  description = "Fargate memory in MiB."
  type        = number
  default     = 512

  validation {
    condition = (
      (var.ecs_cpu == 256 && contains([512, 1024, 2048], var.ecs_memory)) ||
      (var.ecs_cpu == 512 && contains([1024, 2048, 3072, 4096], var.ecs_memory)) ||
      (var.ecs_cpu == 1024 && var.ecs_memory >= 2048 && var.ecs_memory <= 8192 && var.ecs_memory % 1024 == 0) ||
      (var.ecs_cpu == 2048 && var.ecs_memory >= 4096 && var.ecs_memory <= 16384 && var.ecs_memory % 1024 == 0) ||
      (var.ecs_cpu == 4096 && var.ecs_memory >= 8192 && var.ecs_memory <= 30720 && var.ecs_memory % 1024 == 0)
    )
    error_message = "ecs_memory must be a valid Fargate pair for ecs_cpu."
  }
}

variable "cpu_architecture" {
  description = "Fargate CPU architecture. ARM64 matches the cost section."
  type        = string
  default     = "ARM64"

  validation {
    condition     = contains(["ARM64", "X86_64"], var.cpu_architecture)
    error_message = "cpu_architecture must be ARM64 or X86_64."
  }
}

variable "ecs_desired_count" {
  description = "Number of Fargate tasks."
  type        = number
  default     = 1

  validation {
    condition     = var.ecs_desired_count >= 1 && var.ecs_desired_count <= 10
    error_message = "ecs_desired_count must be from 1 to 10."
  }
}

variable "log_retention_days" {
  description = "CloudWatch retention for application logs."
  type        = number
  default     = 365

  validation {
    condition = contains(
      [1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653],
      var.log_retention_days,
    )
    error_message = "log_retention_days must be a CloudWatch Logs retention value."
  }
}

variable "log_expiration_days" {
  description = "Days before S3 access logs and flow logs expire."
  type        = number
  default     = 90

  validation {
    condition     = var.log_expiration_days >= 1 && var.log_expiration_days <= 3650
    error_message = "log_expiration_days must be from 1 to 3650."
  }
}

variable "enable_deletion_protection" {
  description = "Protect the load balancer from deletion. Leave false so teardown can remove a demo."
  type        = bool
  default     = false
}

variable "force_destroy_buckets" {
  description = "Delete log buckets on destroy even if they still contain objects."
  type        = bool
  default     = true
}

variable "acm_certificate_arn" {
  description = "Optional ACM certificate ARN for HTTPS. Empty keeps HTTP. Do not generate a private key in this stack."
  type        = string
  default     = ""
}

variable "budget_limit_usd" {
  description = "Monthly account budget in USD. A chosen ceiling, not a measured bill. The demo example is 100 because the idle list-price estimate is about 68."
  type        = string
  default     = "100"

  validation {
    condition     = can(tonumber(var.budget_limit_usd)) && tonumber(var.budget_limit_usd) > 0
    error_message = "budget_limit_usd must be a positive number."
  }
}

variable "alert_email" {
  description = "Inbox for budget notices and alarm subscriptions. example.com does not receive mail. Replace it before any real apply."
  type        = string
  default     = "budget-alerts@example.com"

  validation {
    condition     = can(regex("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$", var.alert_email))
    error_message = "alert_email must be an email address."
  }
}
