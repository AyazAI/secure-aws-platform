locals {
  container_base = {
    name                   = "app"
    image                  = var.container_image
    essential              = true
    readonlyRootFilesystem = var.readonly_root_filesystem
    privileged             = false
    portMappings = [{
      containerPort = var.container_port
      protocol      = "tcp"
    }]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = aws_cloudwatch_log_group.app.name
        awslogs-region        = var.region
        awslogs-stream-prefix = "app"
      }
    }
    linuxParameters = merge(
      { initProcessEnabled = true },
      var.readonly_root_filesystem ? { capabilities = { drop = ["ALL"] } } : {}
    )
  }

  writable_mounts = var.readonly_root_filesystem ? {
    tmp         = "/tmp"
    nginx-cache = "/var/cache/nginx"
    nginx-run   = "/var/run"
  } : {}

  container = merge(
    local.container_base,
    var.container_user == "" ? {} : { user = var.container_user },
    length(local.writable_mounts) == 0 ? {} : {
      mountPoints = [
        for name, path in local.writable_mounts : {
          sourceVolume  = name
          containerPath = path
          readOnly      = false
        }
      ]
    }
  )
}

resource "aws_ecr_repository" "app" {
  name                 = var.ecr_repository_name
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "KMS"
    kms_key         = var.kms_key_arn
  }

  tags = var.tags
}

resource "aws_ecr_lifecycle_policy" "app" {
  repository = aws_ecr_repository.app.name
  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep the last 10 images."
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 10
      }
      action = { type = "expire" }
    }]
  })
}

resource "aws_cloudwatch_log_group" "app" {
  name              = var.log_group_name
  retention_in_days = var.log_retention_days
  kms_key_id        = var.kms_key_arn
  tags              = var.tags
}

# Same reason as the Checkov skip above.
#tfsec:ignore:aws-ecs-enable-container-insight
resource "aws_ecs_cluster" "this" {
  #checkov:skip=CKV_AWS_65:Container Insights is off so this demo does not add that charge. Alarms and the dashboard use standard ECS service metrics.
  name = var.name_prefix
  tags = var.tags
}

resource "aws_ecs_task_definition" "app" {
  #checkov:skip=CKV_AWS_336:The demo image is public nginx, which writes a cache and a pid file. sample-app can set readonly_root_filesystem, which mounts tmp volumes.
  family                   = var.name_prefix
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = tostring(var.cpu)
  memory                   = tostring(var.memory)
  execution_role_arn       = var.execution_role_arn
  task_role_arn            = var.task_role_arn
  tags                     = var.tags

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = var.cpu_architecture
  }

  dynamic "volume" {
    for_each = local.writable_mounts
    content {
      name = volume.key
    }
  }

  container_definitions = jsonencode([local.container])
}

resource "aws_ecs_service" "this" {
  name             = var.name_prefix
  cluster          = aws_ecs_cluster.this.id
  task_definition  = aws_ecs_task_definition.app.arn
  desired_count    = var.desired_count
  launch_type      = "FARGATE"
  platform_version = "LATEST"

  enable_execute_command = false
  propagate_tags         = "SERVICE"

  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent         = 200
  health_check_grace_period_seconds  = 60

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [var.ecs_security_group_id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.target_group_arn
    container_name   = "app"
    container_port   = var.container_port
  }

  tags = var.tags
}
