# AWS Infrastructure Setup

This document outlines the AWS infrastructure setup using Terraform for our React application deployment.

## Infrastructure Components

### 1. VPC Setup
- Created a VPC with CIDR block 10.0.0.0/16
- Enabled DNS hostnames and DNS support
- Created an Internet Gateway for public internet access
- Set up a public subnet in ap-south-1a availability zone
- Configured route tables for internet access

### 2. Security
- Created a security group allowing:
  - HTTP (port 80) for web traffic
  - SSH (port 22) for remote access
  - Port 3000 for development server
  - All outbound traffic

### 3. EC2 Instance
- Launched Ubuntu 22.04 LTS in ap-south-1 region
- Instance type: t2.micro (free tier eligible)
- Auto-assigns public IP
- User data script installs:
  - Node.js and npm
  - Git
  - Nginx web server
  - AWS SSM agent
- Configures Nginx to serve React application

### 4. IAM Configuration
- Created GitHub OIDC provider for secure authentication
- Set up IAM roles:
  1. GitHub Actions Role:
     - Allows GitHub Actions to deploy to EC2
     - Permissions for EC2 operations
     - Access to S3 bucket for artifacts
  2. EC2 SSM Role:
     - Enables AWS Systems Manager access
     - Allows instance management

### 5. S3 Storage
- Created S3 bucket for deployment artifacts
- Enabled versioning for rollback capability
- Configured appropriate IAM permissions

## GitHub Actions Integration

### Required Secrets
The following secrets need to be configured in GitHub repository:
- `EC2_HOST`: EC2 instance public IP (13.234.116.173)
- `EC2_SSH_KEY`: SSH private key for EC2 access

### Deployment Process
1. GitHub Actions workflow triggers on:
   - Push to main branch
   - Pull requests to main branch

2. Workflow steps:
   - Checks out code
   - Sets up Node.js
   - Installs dependencies
   - Builds application
   - Deploys to EC2 instance

## Manual Setup Steps

1. Create AWS Account and get access credentials

2. Install Terraform:
   ```bash
   # Download and install Terraform
   # Configure AWS credentials
   ```

3. Initialize Terraform:
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

4. Create EC2 key pair:
   - Generate or import SSH key pair
   - Save private key securely
   - Add to GitHub secrets

## Infrastructure Updates

To update infrastructure:
```bash
terraform plan    # Review changes
terraform apply   # Apply changes
```

To destroy infrastructure:
```bash
terraform destroy
```

## Security Considerations

1. EC2 Instance:
   - Only necessary ports are open (80, 22, 3000)
   - SSH access restricted to key authentication
   - Regular security updates via user data script

2. GitHub Actions:
   - Uses OIDC for secure authentication
   - Minimal IAM permissions
   - Secrets stored securely in GitHub

3. Network:
   - VPC isolation
   - Public subnet only for web-facing components
   - Security group restrictions

## Maintenance

1. Regular Tasks:
   - Monitor EC2 instance health
   - Check CloudWatch logs
   - Update security patches
   - Review and rotate access keys

2. Troubleshooting:
   - Check EC2 instance logs
   - Verify security group rules
   - Test network connectivity
   - Review GitHub Actions logs

## Cost Management

The infrastructure uses:
- t2.micro instance (free tier eligible)
- Minimal S3 storage
- Free tier eligible services where possible

Monitor AWS billing dashboard for any unexpected charges.