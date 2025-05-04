provider "aws" {
  region = "ap-south-1"
}

# ECR Repository for Docker images
resource "aws_ecr_repository" "app" {
  name         = "react-app"
  force_delete = true
}

# ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = "react-app-cluster"
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/react-app"
  retention_in_days = 1  # Minimum retention for free tier
}

# ECS Task Definition
resource "aws_ecs_task_definition" "app" {
  family                   = "react-app"
  requires_compatibilities = ["FARGATE"]
  network_mode            = "awsvpc"
  cpu                     = 256  # Minimum CPU for Fargate
  memory                  = 512  # Minimum memory for Fargate
  execution_role_arn      = aws_iam_role.ecs_execution_role.arn

  container_definitions = jsonencode([
    {
      name  = "react-app"
      image = "${aws_ecr_repository.app.repository_url}:latest"
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
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
    }
  ])
}

# IAM Role for ECS
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

# Network Configuration
resource "aws_default_vpc" "default" {}

resource "aws_default_subnet" "default_az1" {
  availability_zone = "ap-south-1a"
}

# Security Group for ECS Tasks
resource "aws_security_group" "ecs_tasks" {
  name        = "react-app-ecs-sg"
  description = "Allow inbound traffic for ECS tasks"
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

# ECS Service
resource "aws_ecs_service" "app" {
  name            = "react-app"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [aws_default_subnet.default_az1.id]
    assign_public_ip = true
    security_groups  = [aws_security_group.ecs_tasks.id]
  }
}

# S3 bucket for artifacts
resource "aws_s3_bucket" "artifacts" {
  bucket_prefix = "react-app-artifacts"
  force_destroy = true
}

# CodePipeline role
resource "aws_iam_role" "codepipeline_role" {
  name = "react-app-codepipeline-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "codepipeline.amazonaws.com"
        }
      }
    ]
  })
}

# CodePipeline policy
resource "aws_iam_role_policy" "codepipeline_policy" {
  name = "react-app-codepipeline-policy"
  role = aws_iam_role.codepipeline_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:*",
          "ecr:*",
          "ecs:*",
          "codebuild:*",
          "codestar-connections:*"
        ]
        Resource = "*"
      }
    ]
  })
}

# Add CodeBuild Role and Policy
resource "aws_iam_role" "codebuild_role" {
  name = "react-app-codebuild-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "codebuild.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "codebuild_policy" {
  role = aws_iam_role.codebuild_role.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Resource = ["*"]
        Action = [
          "logs:*",
          "ecr:*",
          "s3:*",
          "ecs:*"
        ]
      }
    ]
  })
}

# Add CodeBuild Project
resource "aws_codebuild_project" "app_build" {
  name         = "react-app-build"
  description  = "Builds React app Docker image"
  service_role = aws_iam_role.codebuild_role.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                      = "aws/codebuild/amazonlinux2-x86_64-standard:4.0"
    type                       = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode            = true

    environment_variable {
      name  = "ECR_REPOSITORY_URI"
      value = aws_ecr_repository.app.repository_url
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = "buildspec.yml"
  }
}

# GitHub connection
resource "aws_codestarconnections_connection" "github" {
  name          = "react-app-github"
  provider_type = "GitHub"
}

# CodePipeline
resource "aws_codepipeline" "app_pipeline" {
  name     = "react-app-pipeline"
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    location = aws_s3_bucket.artifacts.bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        ConnectionArn    = aws_codestarconnections_connection.github.arn
        FullRepositoryId = "mc-aravind/my-app"
        BranchName      = "docker-container-ecr"  # Updated branch name
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]
      version         = "1"

      configuration = {
        ProjectName = aws_codebuild_project.app_build.name
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "ECS"
      input_artifacts = ["build_output"]
      version         = "1"

      configuration = {
        ClusterName = aws_ecs_cluster.main.name
        ServiceName = aws_ecs_service.app.name
      }
    }
  }
}

# Outputs
output "repository_url" {
  value = aws_ecr_repository.app.repository_url
}

output "task_public_ip" {
  value = "Find the public IP in AWS Console: ECS > Clusters > react-app-cluster > Tasks"
}

# Add pipeline URL output
output "pipeline_url" {
  value = "https://ap-south-1.console.aws.amazon.com/codesuite/codepipeline/pipelines/${aws_codepipeline.app_pipeline.name}/view"
}

# Add connection ARN output
output "connection_url" {
  value = "https://ap-south-1.console.aws.amazon.com/codesuite/settings/connections"
}