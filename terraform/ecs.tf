resource "aws_ecs_cluster" "main" {
  name = "react-app-cluster"
}

resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/react-app"
  retention_in_days = 7  # Adjust retention period as needed
}

resource "aws_ecs_task_definition" "app" {
  family                   = "react-app"
  requires_compatibilities = ["FARGATE"]
  network_mode            = "awsvpc"
  cpu                     = 256  # 0.25 vCPU
  memory                  = 512  # 0.5 GB
  execution_role_arn      = aws_iam_role.ecs_execution_role.arn

  container_definitions = jsonencode([
    {
      name         = "react-app"
      image        = "${aws_ecr_repository.app.repository_url}:latest"
      essential    = true
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
          protocol      = "tcp"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs.name
          "awslogs-region"        = "ap-south-1"
          "awslogs-stream-prefix" = "ecs"
        }
      }
      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost:80/ || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }
    }
  ])
}

resource "aws_iam_role" "ecs_execution_role" {
  name = "ecs-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_execution_role_policy" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_lb" "app" {
  name               = "react-app-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb.id]
  subnets           = [aws_default_subnet.default_az1.id, aws_default_subnet.default_az2.id]
}

resource "aws_lb_target_group" "app" {
  name        = "react-app-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_default_vpc.default.id
  target_type = "ip"

  health_check {
    path                = "/"
    healthy_threshold   = 2
    unhealthy_threshold = 10
    timeout             = 60
    interval            = 300
    matcher             = "200,302,401,403,404"
  }
}

resource "aws_lb_listener" "app" {
  load_balancer_arn = aws_lb.app.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

resource "aws_security_group" "lb" {
  name        = "react-app-lb-sg"
  description = "Security group for ALB"
  vpc_id      = aws_default_vpc.default.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_default_vpc" "default" {
}

resource "aws_default_subnet" "default_az1" {
  availability_zone = "ap-south-1a"
}

resource "aws_default_subnet" "default_az2" {
  availability_zone = "ap-south-1b"
}

resource "aws_ecs_service" "app" {
  name            = "react-app"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [aws_default_subnet.default_az1.id, aws_default_subnet.default_az2.id]
    assign_public_ip = true
    security_groups  = [aws_security_group.ecs_tasks.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.app.arn
    container_name   = "react-app"
    container_port   = 80
  }
}

resource "aws_security_group" "ecs_tasks" {
  name        = "react-app-ecs-tasks-sg"
  description = "Security group for ECS tasks"
  vpc_id      = aws_default_vpc.default.id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.lb.id]  # Allow traffic from ALB only
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

output "task_public_ip" {
  value = "Wait for the task to start, then find the public IP in the AWS Console under ECS > Tasks"
}