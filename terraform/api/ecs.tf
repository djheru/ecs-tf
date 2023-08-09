resource "aws_ecs_cluster" "ecs_cluster" {
  name = "${var.app_name}-ecs-cluster"
}

resource "aws_ecs_service" "ecs_service" {
  name                               = "${var.app_name}-service"
  cluster                            = aws_ecs_cluster.ecs_cluster.id
  task_definition                    = aws_ecs_task_definition.ecs_main_task.arn
  desired_count                      = 1
  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 200
  launch_type                        = "FARGATE"
  scheduling_strategy                = "REPLICA"

  network_configuration {
    subnets         = module.vpc.private_subnets
    security_groups = [aws_security_group.ecs_services_sg.id]
  }

  load_balancer {
    target_group_arn = aws_alb_target_group.ecs_target_group.arn
    container_name   = var.app_name
    container_port   = var.container_port
  }
}

resource "aws_ecs_task_definition" "ecs_main_task" {
  family                   = "${var.app_name}-task"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.cpu
  memory                   = var.memory

  container_definitions = jsonencode([{
    name      = var.app_name
    image     = "${aws_ecr_repository.ecs_ecr_repository.repository_url}:latest"
    essential = true

    portMappings = [{
      containerPort = var.container_port
      hostPort      = var.container_port
    }]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = var.log_group_name
        awslogs-region        = var.region
        awslogs-stream-prefix = "${var.app_name}-logs"
      }
    }

    environment = [
      {
        name  = "PGHOST"
        value = module.db.db_instance_address
      },
      {
        name  = "PGPORT"
        value = format("%d", module.db.db_instance_port)
      },
      {
        name  = "PGDATABASE"
        value = module.db.db_instance_name
      },
      {
        name  = "LOG_LEVEL"
        value = "log,debug,error,warn,verbose"
      },
      {
        name  = "AWS_REGION",
        value = "us-east-1"
      },
      {
        name  = "COMMAND",
        value = "/app/scripts/terraform_apply.sh"
      },
      {
        name  = "DELETE_COMMAND",
        value = "/app/scripts/terraform_destroy.sh"
      },
      {
        name  = "CONTAINER_NAME",
        value = "iac_container"
      },
      {
        name  = "ECS_CLUSTER",
        value = "polaris-iac-cluster"
      },
      {
        name  = "IAC_TASK_DEFINITION",
        value = "iac_task"
      },
      {
        name  = "SECURITY_GROUPS",
        value = "sg-0461c533906198b33"
      },
      {
        name  = "VPC_SUBNETS",
        value = "subnet-0ece2a8767f8070cd"
      },
      {
        name  = "NO_COLOR",
        value = "true"
      },
      {
        name  = "NAME"
        value = "polaris-api"
      }
    ]

    secrets = [
      {
        name      = "PGUSER"
        valueFrom = "${module.db.db_instance_master_user_secret_arn}:username::"
      },
      {
        name      = "PGPASSWORD"
        valueFrom = "${module.db.db_instance_master_user_secret_arn}:password::"
      }
    ]
  }])
}

resource "aws_cloudwatch_log_group" "ecs_service_log_group" {
  name = var.log_group_name
}

resource "aws_ecr_repository" "ecs_ecr_repository" {
  name                 = var.app_name
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}
