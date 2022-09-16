module "vpc" {
  source = "../../modules/vpc"

  env = var.env
  public_subnet_cidr_blocks = var.public_subnet_cidr_blocks
  vpc_cidr_block = var.vpc_cidr_block
}

resource "aws_security_group" "allow_http_lb" {
  name        = "allow_http_lb"
  description = "Allow http inbound traffic"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description      = "HTTP from internet"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_http_lb"
  }
}

resource "aws_security_group_rule" "allow_http_lb_egress" {
  type                     = "egress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  security_group_id        = aws_security_group.allow_http_lb.id
  source_security_group_id = aws_security_group.ecs_container.id
}

resource "aws_security_group" "ecs_container" {
  name        = "ecs-container"
  description = "Allow http inbound traffic"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description     = "HTTP from ALB"
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = [aws_security_group.allow_http_lb.id]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "ecs-container"
  }
}

resource "aws_lb" "devops-ninja-lb" {
  name                       = "devops-ninja-lb-${var.env}"
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.allow_http_lb.id]
  subnets                    = module.vpc.public_subnet_ids
  enable_deletion_protection = false
}

resource "aws_lb_listener" "devops-ninja-lb-listener" {
  load_balancer_arn = aws_lb.devops-ninja-lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.devops-ninja_lb_tg.arn
  }
}

resource "aws_lb_target_group" "devops-ninja_lb_tg" {
  name        = "devops-${var.env}"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = module.vpc.vpc_id

  health_check {
    interval = 5
    timeout  = 2
    path     = "/healthcheck"
  }
}

resource "aws_ecs_cluster" "cluster" {
  name = "cluster-${var.env}"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_ecs_task_definition" "devops-ninja-task_definition" {
  count = var.release_version != "" ? 1 : 0
  family = "devops-ninja-task_definition"
  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn
  container_definitions = jsonencode([
    {
      name      = "devops-ninja"
      image     = "${var.image}"
      essential = true      
      logConfiguration = {
        "LogDriver" : "awslogs",
        "Options" : {awslogs-group : "/ecs/fargate-task-definition", awslogs-region: "us-east-1,", awslogs-stream-prefix: "logs"},
}
      
      portMappings = [
        {
          containerPort = 8000
          hostPort      = 8000
          protocol      = "tcp"
        }
      ]

    }
  ])

  requires_compatibilities = [
    "FARGATE"
  ]

  network_mode = "awsvpc"
  cpu          = "256"
  memory       = "512"
}


resource "aws_ecs_service" "devops-ninja-service" {
  count = var.release_version != "" ? 1 : 0
  name            = "devops-ninja-service"
  cluster         = aws_ecs_cluster.cluster.id
  task_definition = aws_ecs_task_definition.devops-ninja-task_definition[0].arn
  desired_count   = 3
  launch_type     = "FARGATE"

  load_balancer {
    target_group_arn = aws_lb_target_group.devops-ninja_lb_tg.arn
    container_name   = jsondecode(aws_ecs_task_definition.devops-ninja-task_definition[0].container_definitions)[0].name
    container_port   = 8000
  }

  network_configuration {
    subnets          = module.vpc.public_subnet_ids
    assign_public_ip = true
    security_groups  = [aws_security_group.ecs_container.id]
  }
}

resource "aws_cloudwatch_log_group" "logs" {
  name              = "logs-devops-ninja"
  retention_in_days = 7
  #tags              = "logs-devops-ninja"
}