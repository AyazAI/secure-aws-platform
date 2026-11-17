data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

locals {
  tags = {
    Project     = "secure-aws-platform"
    Owner       = "AyazAI"
    ManagedBy   = "terraform"
    Environment = var.environment
  }

  # Names are fixed here so IAM ARNs do not depend on resources that depend on the roles.
  log_group_name      = "/aws/ecs/${var.name_prefix}"
  ecr_repository_name = var.name_prefix
  log_group_arn       = "arn:${data.aws_partition.current.partition}:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:${local.log_group_name}"
  ecr_repository_arn  = "arn:${data.aws_partition.current.partition}:ecr:${var.aws_region}:${data.aws_caller_identity.current.account_id}:repository/${local.ecr_repository_name}"
}

module "kms" {
  source = "./modules/kms"

  name_prefix = var.name_prefix
  description = "Encrypts application logs, flow logs, the container repository, and alarm notifications."
  account_id  = data.aws_caller_identity.current.account_id
  region      = var.aws_region
  partition   = data.aws_partition.current.partition
  tags        = local.tags
}

module "vpc" {
  source = "./modules/vpc"

  name_prefix         = var.name_prefix
  vpc_cidr            = var.vpc_cidr
  availability_zones  = var.availability_zones
  app_port            = var.container_port
  enable_https        = var.acm_certificate_arn != ""
  single_nat_gateway  = var.single_nat_gateway
  region              = var.aws_region
  account_id          = data.aws_caller_identity.current.account_id
  kms_key_arn         = module.kms.key_arn
  log_expiration_days = var.log_expiration_days
  force_destroy       = var.force_destroy_buckets
  tags                = local.tags
}

module "alb" {
  source = "./modules/alb"

  name_prefix                = var.name_prefix
  vpc_id                     = module.vpc.vpc_id
  public_subnet_ids          = module.vpc.public_subnet_ids
  alb_security_group_id      = module.vpc.alb_security_group_id
  app_port                   = var.container_port
  health_check_path          = var.health_check_path
  acm_certificate_arn        = var.acm_certificate_arn
  account_id                 = data.aws_caller_identity.current.account_id
  enable_deletion_protection = var.enable_deletion_protection
  log_expiration_days        = var.log_expiration_days
  force_destroy              = var.force_destroy_buckets
  tags                       = local.tags
}

module "iam" {
  source = "./modules/iam"

  name_prefix        = var.name_prefix
  account_id         = data.aws_caller_identity.current.account_id
  region             = var.aws_region
  partition          = data.aws_partition.current.partition
  app_log_group_arn  = local.log_group_arn
  ecr_repository_arn = local.ecr_repository_arn
  kms_key_arn        = module.kms.key_arn
  tags               = local.tags
}

module "ecs" {
  source = "./modules/ecs"

  name_prefix              = var.name_prefix
  region                   = var.aws_region
  log_group_name           = local.log_group_name
  ecr_repository_name      = local.ecr_repository_name
  kms_key_arn              = module.kms.key_arn
  private_subnet_ids       = module.vpc.private_subnet_ids
  ecs_security_group_id    = module.vpc.ecs_security_group_id
  execution_role_arn       = module.iam.execution_role_arn
  task_role_arn            = module.iam.task_role_arn
  target_group_arn         = module.alb.target_group_arn
  container_image          = var.container_image
  container_port           = var.container_port
  container_user           = var.container_user
  readonly_root_filesystem = var.readonly_root_filesystem
  cpu                      = var.ecs_cpu
  memory                   = var.ecs_memory
  cpu_architecture         = var.cpu_architecture
  desired_count            = var.ecs_desired_count
  log_retention_days       = var.log_retention_days
  tags                     = local.tags

  depends_on = [module.alb]
}

module "monitoring" {
  source = "./modules/monitoring"

  name_prefix             = var.name_prefix
  region                  = var.aws_region
  account_id              = data.aws_caller_identity.current.account_id
  kms_key_arn             = module.kms.key_arn
  alert_email             = var.alert_email
  alb_arn_suffix          = module.alb.alb_arn_suffix
  target_group_arn_suffix = module.alb.target_group_arn_suffix
  ecs_cluster_name        = module.ecs.cluster_name
  ecs_service_name        = module.ecs.service_name
  ecs_desired_count       = var.ecs_desired_count
  tags                    = local.tags
}

module "budget" {
  source = "./modules/budget"

  name_prefix = var.name_prefix
  limit_usd   = var.budget_limit_usd
  alert_email = var.alert_email
}
