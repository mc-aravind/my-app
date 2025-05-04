# AWS ECS Deployment Guide

## Infrastructure Components
- ECS Cluster: react-app-cluster
- ECR Repository: react-app
- Application Load Balancer: react-app-lb
- Target Group: react-app-tg
- VPC and Subnets: Using default VPC in ap-south-1
- Security Groups:
  - Load Balancer SG: react-app-lb-sg
  - ECS Tasks SG: react-app-ecs-tasks-sg

## Service URLs
- Load Balancer URL: react-app-lb-1314282196.ap-south-1.elb.amazonaws.com
- ECR Repository: 004165098217.dkr.ecr.ap-south-1.amazonaws.com/react-app

## Resource Details

### ECS Task Definition
- CPU: 256 (0.25 vCPU)
- Memory: 512MB
- Network Mode: awsvpc
- Requires Fargate compatibility
- Container Port: 80
- Health Check:
  - Command: curl -f http://localhost:80/ || exit 1
  - Interval: 30s
  - Timeout: 5s
  - Retries: 3
  - Start Period: 60s

### Load Balancer Configuration
- Type: Application Load Balancer
- Port: 80
- Protocol: HTTP
- Health Check:
  - Path: /
  - Interval: 300s
  - Timeout: 60s
  - Healthy Threshold: 2
  - Unhealthy Threshold: 10
  - Success Codes: 200,302,401,403,404

### Security Groups
1. Load Balancer Security Group:
   - Inbound: Allow 80 from 0.0.0.0/0
   - Outbound: Allow all

2. ECS Tasks Security Group:
   - Inbound: Allow 80 from Load Balancer SG
   - Outbound: Allow all

### Network Configuration
- VPC ID: vpc-0e4956100c37fff93
- Subnets:
  - ap-south-1a: subnet-01fd3d33cd2b33998
  - ap-south-1b: subnet-06a66a0793d403812

## Monitoring
- CloudWatch Log Group: /ecs/react-app
- Log Retention: 7 days

## IAM Roles
- ECS Execution Role: ecs-execution-role
  - Trusted Entity: ecs-tasks.amazonaws.com
  - Attached Policy: AmazonECSTaskExecutionRolePolicy

## Deployment Status
Current deployment:
- Desired Count: 1
- Launch Type: FARGATE
- Platform Version: LATEST