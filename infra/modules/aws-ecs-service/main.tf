resource "aws_ecs_cluster" "this" {
  name = "${var.env}-cluster"

  tags = {
    Environment = var.env
  }
}

resource "aws_iam_role" "task_execution" {
  name = "${var.env}-${var.name}-task-exec-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_exec_policy" {
  role       = aws_iam_role.task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_cloudwatch_log_group" "logs" {
  name              = "/ecs/${var.env}/${var.name}"
  retention_in_days = 14

  tags = {
    Environment = var.env
  }
}

resource "aws_ecs_task_definition" "this" {
  family                   = "${var.env}-${var.name}"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"

  cpu                      = var.cpu
  memory                   = var.memory
  execution_role_arn       = aws_iam_role.task_execution.arn

  container_definitions = jsonencode([
    {
      name      = var.name
      image     = var.image
      essential = true
      portMappings = [
        {
          containerPort = var.port
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.logs.name
          awslogs-region        = var.region
          awslogs-stream-prefix = var.name
        }
      }
    }
  ])
}

resource "aws_ecs_service" "this" {
  name            = "${var.env}-${var.name}"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.this.arn

  launch_type     = "FARGATE"
  desired_count   = var.replicas

  network_configuration {
    subnets          = var.subnets
    security_groups  = concat(
      [var.primary_sg],       # from network module (mandatory)
      var.extra_sgs           # optional additional SGs
    )
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = var.target_group_arn
    container_name   = var.name
    container_port   = var.port
  }

  propagate_tags = "SERVICE"

  tags = {
    Environment = var.env
  }
}

